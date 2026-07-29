# the 1password cli is the one installed tool with no completion from any source — not in
# homebrew's vendor_completions.d, not embedded in fish, not scraped from a man page. it can
# generate its own, so cache that.
#
# completions autoload on the first `op <TAB>`, never at startup, so the generation cost is
# paid once per machine rather than once per shell.
# ⚠ op's generated completion ends with a `complete --do-complete "op "` self-test that
# spawns an `op` subprocess when sourced. that is upstream cobra boilerplate and is exactly
# why this must stay lazily autoloaded and never be sourced from conf.d/.

type -q op; and cachecmd --source op completion fish
