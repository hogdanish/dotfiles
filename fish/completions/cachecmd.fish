# -F on --depends: it takes a real path, so re-enable file completion for that option only.
# no global -f: everything after the flags is a command, and file completion is a
# reasonable fallback for that.
complete -c cachecmd -s s -l source -d 'source the cache instead of printing it'
complete -c cachecmd -s c -l clear -d 'discard the cache entry first'
complete -c cachecmd -s d -l depends -r -F -d 'extra file whose mtime invalidates the cache'
complete -c cachecmd -n __fish_is_first_arg -a '(__fish_complete_command)' -d 'command to cache'
