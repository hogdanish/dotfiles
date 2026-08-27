#!/opt/homebrew/bin/bun

import net from "node:net";
import {
  chmodSync,
  existsSync,
  mkdtempSync,
  rmSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const TOOL_PATHS = {
  "linode-cli": "/opt/homebrew/bin/linode-cli",
  cf: "/opt/homebrew/bin/cf",
};

function fail(message, status = 1) {
  process.stderr.write(`${message}\n`);
  process.exit(status);
}

function rejectUnsafeArguments(tool, args) {
  if (tool === "linode-cli" && args.includes("--debug")) {
    return "agent credential broker: linode-cli --debug is blocked because it can expose authorization headers";
  }
  if (tool === "linode-cli" && args[0] === "configure") {
    return "agent credential broker: linode-cli configure is blocked; credentials come from 1Password";
  }
  return null;
}

async function runRequest(request) {
  const { tool, args, cwd } = request;
  if (!(tool in TOOL_PATHS) || !Array.isArray(args) || typeof cwd !== "string") {
    return { status: 64, stdout: "", stderr: "agent credential broker: invalid request\n" };
  }

  const rejection = rejectUnsafeArguments(tool, args);
  if (rejection) {
    return { status: 64, stdout: "", stderr: `${rejection}\n` };
  }

  const env = { ...process.env };
  if (tool === "linode-cli") {
    if (!env.LINODE_CLI_TOKEN) {
      return { status: 77, stdout: "", stderr: "agent credential broker: Linode credential unavailable\n" };
    }
    delete env.CLOUDFLARE_API_TOKEN;
  } else {
    if (!env.CLOUDFLARE_API_TOKEN) {
      return { status: 77, stdout: "", stderr: "agent credential broker: Cloudflare credential unavailable\n" };
    }
    delete env.LINODE_CLI_TOKEN;
  }

  const child = Bun.spawn([TOOL_PATHS[tool], ...args], {
    cwd,
    env,
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  const [stdout, stderr, status] = await Promise.all([
    new Response(child.stdout).text(),
    new Response(child.stderr).text(),
    child.exited,
  ]);
  return { status, stdout, stderr };
}

function serve(socketPath) {
  const server = net.createServer((socket) => {
    let payload = "";
    let handled = false;
    socket.setEncoding("utf8");
    socket.on("data", async (chunk) => {
      payload += chunk;
      if (payload.length > 1024 * 1024) socket.destroy();
      if (handled || !payload.endsWith("\n")) return;
      handled = true;
      try {
        const response = await runRequest(JSON.parse(payload.trimEnd()));
        socket.end(JSON.stringify(response));
      } catch (error) {
        socket.end(JSON.stringify({
          status: 70,
          stdout: "",
          stderr: `agent credential broker: ${error.message}\n`,
        }));
      }
    });
  });

  server.listen(socketPath, () => chmodSync(socketPath, 0o600));
  const close = () => server.close(() => process.exit(0));
  process.on("SIGINT", close);
  process.on("SIGTERM", close);
}

async function runDirect(tool, args) {
  const path = TOOL_PATHS[tool];
  if (!path) fail("agent credential broker: unknown tool", 64);
  const child = Bun.spawn([path, ...args], {
    env: process.env,
    stdin: "inherit",
    stdout: "inherit",
    stderr: "inherit",
  });
  process.exit(await child.exited);
}

async function call(socketPath, tool, args) {
  if (!socketPath || !existsSync(socketPath)) await runDirect(tool, args);

  const response = await new Promise((resolve, reject) => {
    const socket = net.createConnection(socketPath);
    let payload = "";
    socket.setEncoding("utf8");
    socket.on("connect", () => socket.write(`${JSON.stringify({ tool, args, cwd: process.cwd() })}\n`));
    socket.on("data", (chunk) => { payload += chunk; });
    socket.on("end", () => {
      try {
        resolve(JSON.parse(payload));
      } catch (error) {
        reject(error);
      }
    });
    socket.on("error", reject);
  }).catch((error) => fail(`agent credential broker: ${error.message}`, 77));

  process.stdout.write(response.stdout);
  process.stderr.write(response.stderr);
  process.exit(response.status);
}

async function supervise(command) {
  if (command.length === 0) fail("agent credential broker: no agent command supplied", 64);
  if (!process.env.LINODE_CLI_TOKEN || !process.env.CLOUDFLARE_API_TOKEN) {
    fail("agent credential broker: 1Password did not resolve both infrastructure credentials", 77);
  }

  const sessionDir = mkdtempSync(join(tmpdir(), "agent-infra-"));
  const socketPath = join(sessionDir, "broker.sock");
  const broker = Bun.spawn([process.execPath, import.meta.path, "serve", socketPath], {
    env: process.env,
    stdin: "ignore",
    stdout: "inherit",
    stderr: "inherit",
  });

  for (let attempt = 0; attempt < 100 && !existsSync(socketPath); attempt += 1) {
    await Bun.sleep(10);
  }
  if (!existsSync(socketPath)) {
    broker.kill();
    rmSync(sessionDir, { force: true, recursive: true });
    fail("agent credential broker: server did not start", 70);
  }

  const agentEnv = { ...process.env };
  delete agentEnv.LINODE_CLI_TOKEN;
  delete agentEnv.CLOUDFLARE_API_TOKEN;
  delete agentEnv.LINODE_API_TOKEN;
  agentEnv.AGENT_INFRA_BROKER_SOCKET = socketPath;
  agentEnv.PATH = `/Users/ethan/.config/scripts/agent-bin:${agentEnv.PATH}`;

  const agent = Bun.spawn(command, {
    env: agentEnv,
    stdin: "inherit",
    stdout: "inherit",
    stderr: "inherit",
  });
  const forward = (signal) => agent.kill(signal);
  process.on("SIGINT", () => forward("SIGINT"));
  process.on("SIGTERM", () => forward("SIGTERM"));

  const status = await agent.exited;
  broker.kill();
  await broker.exited;
  rmSync(sessionDir, { force: true, recursive: true });
  process.exit(status);
}

const [mode, ...args] = process.argv.slice(2);
if (mode === "serve") serve(args[0]);
else if (mode === "call") await call(process.env.AGENT_INFRA_BROKER_SOCKET, args[0], args.slice(1));
else if (mode === "supervise") await supervise(args);
else fail("usage: agent-credential-broker.mjs <serve|call|supervise> ...", 64);
