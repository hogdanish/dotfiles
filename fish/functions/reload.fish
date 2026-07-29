function reload --description 'open a fresh terminal window at the current directory, then close this one'
    # to reload config *in place*, use the `refresh` abbreviation (`exec fish`) — cheaper,
    # and it keeps the window. this is for when a genuinely new window is wanted.
    if not set -q TERM_PROGRAM; or test -z "$TERM_PROGRAM"
        echo >&2 'reload: $TERM_PROGRAM is unset — cannot tell which terminal to open'
        return 1
    end

    if not open -a "$TERM_PROGRAM.app" "$PWD"
        # gum is the house prompt/log tool, but it is not a hard dependency of the shell
        if type -q gum
            gum log -l error "could not open a new $TERM_PROGRAM window"
        else
            echo >&2 "reload: could not open a new $TERM_PROGRAM window"
        end
        return 1
    end

    # let the new window claim focus before this one disappears
    sleep 0.5

    # ⚠ `exit`, not `return`: ending this shell is the point. inside a function `exit` kills
    # the whole shell — correct here, almost never anywhere else.
    exit 0
end
