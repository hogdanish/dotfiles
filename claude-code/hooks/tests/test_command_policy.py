from __future__ import annotations

import importlib.util
import json
import subprocess
import unittest
from pathlib import Path


HOOKS = Path(__file__).resolve().parents[1]


def load_policy():
    path = HOOKS / "command-policy.py"
    spec = importlib.util.spec_from_file_location("command_policy", path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


policy = load_policy()


class CommandPolicyTests(unittest.TestCase):
    def test_allows_read_only_linode_and_safe_brew(self) -> None:
        allowed = [
            "linode-cli linodes list --json",
            "linode-cli linodes view 123 --json",
            "brew bundle check --file=Brewfile",
            "fish -ic 'op plugin run -- linode-cli linodes list --json'",
        ]
        for command in allowed:
            with self.subTest(command=command):
                self.assertIsNone(policy.classify(command))

    def test_denies_direct_and_wrapped_paid_actions(self) -> None:
        denied = [
            "linode-cli linodes create --label fake",
            "linode-cli linodes clone 123 --label fake",
            "linode-cli linodes resize 123 --type fake",
            "linode-cli linodes rebuild 123 --image fake",
            "env SAFE=1 linode-cli lke cluster-create --label fake",
            "op run -- linode-cli volumes create --label fake",
            "bash -c 'linode-cli nodebalancers create --label fake'",
            "zsh -lc 'linode-cli databases postgresql-create --label fake'",
            "fish -ic 'op plugin run -- linode-cli linodes migrate 123'",
        ]
        for command in denied:
            with self.subTest(command=command):
                self.assertIn("billable Akamai Cloud", policy.classify(command) or "")

    def test_denies_destructive_brewfile_operations(self) -> None:
        for command in (
            "brew bundle dump --force --file=Brewfile",
            "fish -c 'brew bundle cleanup --force --file=Brewfile'",
        ):
            with self.subTest(command=command):
                self.assertIn("software-inventory", policy.classify(command) or "")

    def test_malformed_payload_fails_closed_without_echoing_input(self) -> None:
        result = subprocess.run(
            ["python3", str(HOOKS / "command-policy.py")],
            input="{not-json SECRET_SENTINEL",
            capture_output=True,
            check=True,
            text=True,
        )
        payload = json.loads(result.stdout)
        output = payload["hookSpecificOutput"]
        self.assertEqual("deny", output["permissionDecision"])
        self.assertNotIn("SECRET_SENTINEL", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
