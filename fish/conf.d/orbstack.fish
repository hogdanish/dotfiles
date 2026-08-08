# orbstack cli tools (docker/docker-compose/orb/orbctl/kubectl) live in ~/.orbstack/bin —
# populated even without granting orbstack admin access at first launch.
#
# ⚠ NOT sourcing ~/.orbstack/shell/init2.fish, despite that being orbstack's own documented
# integration point. its entire content is `fish_add_path -aP ~/.orbstack/bin`, and without
# -g that writes the *universal* fish_user_paths — this repo's steady state is zero
# universals (.claude/rules/fish.md), so replicating the one line with -g here avoids it.
# unlike zoxide's abbr/alias violations (tolerated, upstream's business), a universal write
# is cheap to avoid outright rather than tolerate.
#
# orbstack's own installer also writes `source ~/.orbstack/shell/init2.fish` straight into
# fish/config.fish on first fish shell start, which this repo keeps intentionally empty —
# strip that out if it reappears (the same move already made for ghostty's vendor-injected
# snippet; see conf.d/ghostty.fish). check after any orbstack upgrade: it may re-inject.
if test -d ~/.orbstack/bin
    fish_add_path -gPa ~/.orbstack/bin
end
