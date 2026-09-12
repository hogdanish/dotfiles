# Quota repair must write the real settings file, and CLAUDE_SETTINGS_FILE is how the plugin is
# told where that is — it reads neither CLAUDE_CONFIG_DIR nor claude's own --settings.
#
# ⚠ There is no settings.json in the claude config dir any more (2026-09-12). clauth rewrites that
# path on every account switch with a temp file + rename, which would replace a tracked symlink
# with a regular file; leaving it absent is what keeps clauth off it. The authored file reaches
# each session through `claude --settings` instead — see functions/wrappers/claude.fish.
# So point the plugin straight at the tracked file rather than at a link that no longer exists.
type -q herdr; or return
set -l authored $XDG_CONFIG_HOME/claude-code/settings.json
if not test -n "$CLAUDE_SETTINGS_FILE"; and test -r $authored
    set -gx CLAUDE_SETTINGS_FILE $authored
end
