function up --description 'travel up any number of directories: `up 3` -> cd ../../..'
    set -l levels 1
    set -q argv[1]; and set levels $argv[1]

    # validate rather than letting `string repeat -n foo` leak its own error
    if not string match -qr '^[0-9]+$' -- $levels
        echo >&2 "up: expected a number, got '$levels'"
        return 2
    end
    if test $levels -eq 0
        return 0
    end

    cd (string repeat -n $levels ../)
end
