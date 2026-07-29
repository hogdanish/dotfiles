function mcpkill --description 'Kill all running Godot MCP bun server processes'
    # matches any version dir, e.g. godot-mcp-pro-vX.Y.Z/server/build/index.js
    set -l pattern 'godot-mcp-pro.*index\.js'

    set -l signal TERM
    if contains -- -9 $argv; or contains -- --force $argv
        set signal KILL
    end

    set -l pids (pgrep -f $pattern)
    if test -z "$pids"
        echo "No Godot MCP server processes running."
        return 0
    end

    kill -$signal $pids
    echo "Killed "(count $pids)" Godot MCP server process(es) with SIG$signal: $pids"
end
