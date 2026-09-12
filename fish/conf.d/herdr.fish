# Quota repair must write the real settings file, not replace its symlink.
# The plugin reads CLAUDE_SETTINGS_FILE but does not read CLAUDE_CONFIG_DIR.
type -q herdr; or return
if not test -n "$CLAUDE_SETTINGS_FILE"; and test -r "$CLAUDE_CONFIG_DIR/settings.json"
    set -gx CLAUDE_SETTINGS_FILE (path resolve -- "$CLAUDE_CONFIG_DIR/settings.json")
end
