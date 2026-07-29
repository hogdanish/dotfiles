function firecrawl --wraps firecrawl --description 'firecrawl cli with a 1password-resolved api key'
    # export the op:// *reference*, not a value — `op run` resolves it inside the subprocess, so the
    # plaintext exists only for the lifetime of that process and never in this shell.
    # ⚠ the reference must be exported on its own line: `FOO=op://… op run -- cmd` loses the race,
    # because fish expands $FOO before op ever substitutes it.
    #
    # no 1password shell plugin exists for firecrawl, and `firecrawl login` would write a second
    # credential store to ~/Library/Application Support/firecrawl-cli. this avoids both.
    if not type -q op
        echo >&2 'firecrawl: op is not installed; no api key available'
        return 127
    end
    set -lx FIRECRAWL_API_KEY 'op://Development/exznjdj2ifns24niif2j3th6s4/credential'
    op run -- firecrawl $argv
end
