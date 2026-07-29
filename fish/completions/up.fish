# -x: exclusive, so no filenames are offered — `up` only ever takes a count.
complete -c up -x -a '(seq 1 9)' -d 'directories to go up'
