# backing function for the `!!` abbreviation in conf.d/abbrs.fish. an abbr declared with
# --function replaces the matched token with whatever this prints, at expansion time.

function __abbr_last_history_item --description 'print the most recent history entry'
    echo $history[1]
end
