# fish sources this file LAST, after every conf.d/ snippet. it is deliberately empty.
#
# all real configuration lives in conf.d/, one concern per file, ordered by filename
# (digits -> `_` -> letters). putting anything here would make it the last thing to run,
# which is almost never what you want; the documented purpose of config.fish is to override
# a vendor or sysconf snippet you cannot edit.
#
# if something ever needs to run after the whole config has been read — re-asserting a
# $PATH entry that a later snippet reordered, say — add the emitter here and register the
# handler in the conf.d file that owns the concern:
#
#     # config.fish
#     emit fish_postinit
#
#     # conf.d/<owner>.fish  — ⚠ handlers only register when a file is *sourced*, so they
#     # must live in conf.d/, never in functions/
#     function __re_prepend --on-event fish_postinit --description 're-assert my path entries'
#         fish_add_path --prepend --move $my_paths
#     end
#
# `fish_postinit` is a convention, not a built-in fish event. there is no consumer today —
# conf.d/brew.fish is the only file that touches $PATH and it is already ordered correctly —
# so the emitter is documented rather than added, to keep this file honestly empty.
