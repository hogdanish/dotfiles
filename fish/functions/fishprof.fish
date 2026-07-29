function fishprof --description 'profile fish startup and print the slowest lines'
    argparse n/count= t/threshold= b/bench -- $argv; or return

    set -l threshold 500
    set -q _flag_threshold; and set threshold $_flag_threshold

    set -l prof (command mktemp -t fishprof)

    # -i so the interactive-only snippets (tools, colours, ghostty) are included; --login
    # because that is how ghostty launches fish, and step 2 of fish's init (the /etc/paths
    # path_helper equivalent, ~0.9 ms) runs for a login shell only. the redirect keeps it from
    # trying to read the terminal.
    # ⚠ startup varies run to run by a few ms, and outliers of 3x the median do occur. treat a
    # single number as indicative and compare medians over several runs before claiming a win.
    command fish --profile-startup=$prof --login -i -c exit </dev/null

    # ⚠ the profile is SPACE-separated (time, sum, command) with trailing tabs, and a command
    # spanning several source lines is written across as many lines — whose continuations start
    # with a *word*, not a number. every row therefore has to be tested for a numeric first
    # field: awk compares a non-numeric $1 to the threshold as a STRING, so "string" and "while"
    # passed `$1 > 500` and printed as bogus, timing-less entries. that is what the junk rows
    # in this report used to be.
    set -l total (command awk 'NR>1 && $1 ~ /^[0-9]+$/ {s+=$1} END{print s+0}' $prof)
    echo "total self time: $total us"
    echo
    echo "slowest lines over $threshold us (self time, command):"
    command awk -v t=$threshold '
        NR > 1 && $1 ~ /^[0-9]+$/ && $1 + 0 > t {
            self = $1
            $1 = ""
            $2 = ""
            sub(/^ +/, "")
            printf "%s %s\n", self, $0
        }' $prof \
        | command sort -rn \
        | string replace -- $HOME '~'

    command rm -f $prof

    if set -q _flag_bench
        set -l count 10
        set -q _flag_count; and set count $_flag_count
        echo
        echo "wall clock, $count interactive startups:"
        for i in (seq $count)
            command /usr/bin/time fish --login -i -c exit </dev/null 2>&1 | command tail -1
        end
    end
end
