#!/usr/bin/env fish
#
# gen-fish-theme — regenerate ~/.config/fish/themes/<name>.theme from the live palette.
# usage: claude-code/skills/fish/scripts/gen-fish-theme.fish [THEME_NAME]   (default: laramie)
#
# the .theme file exists only so `fish_config theme list/show` works. conf.d/colours.fish is
# the real source of truth at startup, because `fish_config theme choose` would autoload the
# 400-line fish_config function on every shell start. this script keeps the two in sync so
# nobody hand-edits the generated one.

set -g THEME_NAME laramie
test -n "$argv[1]"; and set THEME_NAME $argv[1]

function __gen_die --description 'print to stderr and exit non-zero'
    echo >&2 "gen-fish-theme: $argv"
    exit 1
end

function __gen_body --description 'print the live fish_color_* palette in .theme format'
    # ⚠ conf.d/colours.fish sets the fish_color_* block behind `status is-interactive`, and
    # this script runs as a non-interactive fish. harvest from a throwaway `fish -i` rather
    # than requiring the caller to source us from a real shell.
    #
    # two transforms inside, both mandatory:
    #   --theme=NAME  fish_config stamps this on variables it owns; it is not styling
    #   #             set_color accepts a leading hash, but a .theme file is parsed with
    #                 `read -at`, i.e. fish tokenizer rules, so `#a9b1d6` reads as a COMMENT
    #                 and the variable is silently set to nothing
    #
    # ⚠ the group MUST be non-capturing. `string match -r` prints the full match AND every
    # capture group, so `(pager_)` emitted a bare `pager_` line per pager variable — twelve
    # junk lines in the output, and twelve phantom entries in main's `count $body` floor.
    fish -i -c '
        for var in (set -n | string match -r "^fish_(?:pager_)?color_.*" | sort)
            set -l value (string match -v -r -- "^--theme=" $$var | string replace -a "#" "")
            printf "%s %s\n" $var (string join " " -- $value)
        end' 2>/dev/null | string trim -r
end

function main
    set -l palette $__fish_config_dir/themes/$THEME_NAME.fish
    set -l out $__fish_config_dir/themes/$THEME_NAME.theme
    test -r $palette; or __gen_die "no palette at $palette"

    set -l body (__gen_body)
    # sanity floor: a broken harvest yields a near-empty list, and silently writing a
    # 3-line theme is exactly the failure this file is meant to prevent.
    # ⚠ `(cmd)` does not substitute inside double quotes in fish — use $(cmd).
    test (count $body) -gt 20; or __gen_die "only $(count $body) colour variables found; harvest failed"

    printf '%s\n' \
        "# name: '$THEME_NAME'" \
        '# preferred_background: 1f2335' \
        '#' \
        "# GENERATED — do not hand-edit. the source of truth is themes/$THEME_NAME.fish," \
        '# applied by conf.d/colours.fish. regenerate with:' \
        '#   claude-code/skills/fish/scripts/gen-fish-theme.fish' \
        '#' \
        "# ⚠ values are BARE hex, no leading '#'. a .theme file is parsed with fish tokenizer" \
        "# rules, so '#a9b1d6' is read as a comment and the variable is set to nothing —" \
        '# silently, because the line still passes fish name whitelist.' \
        '' >$out
    printf '%s\n' $body >>$out

    echo "wrote $out with $(count $body) variables"
end

main
