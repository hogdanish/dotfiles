# private generator, __-prefixed so it cannot collide.
function __funcfresh_names --description 'function names, including private ones when asked'
    # show __-prefixed internals only once the user has typed an underscore, so the common
    # case is not buried under fish's ~200 shipped helpers.
    if string match -q '_*' -- (commandline --current-token --cut-at-cursor)
        functions --names --all
    else
        functions --names
    end
end

complete -c funcfresh -x -a '(__funcfresh_names)' -d function
complete -c funcfresh -s c -l cache -d 'clear the cachecmd store so tool inits regenerate'
