#!/usr/bin/env fish

# re-point xcode's metal toolchain link at the currently mounted cryptex.
#
# since xcode 16.4 the metal compiler ships as a separate mobileasset rather than inside
# xcode.app. macos mounts it as a cryptex under com.apple.security.cryptexd/mnt/ with a
# random suffix that changes on every boot. xcode 26.6 predates macos 27 and its `metal`
# shim never resolves the asset on its own, so unreal fails with "cannot execute tool
# 'metal' due to missing Metal Toolchain". linking the cryptex into XcodeDefault
# .xctoolchain restores it.
#
# rerun after a reboot, or after installing or switching xcode.

set -l xcode_usr /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr

function __rmt_log --description 'report status through gum when present, plainly otherwise'
    set -l level $argv[1]
    set -l message $argv[2..-1]
    if type -q gum
        gum log --level $level $message
    else if test $level = error
        echo >&2 "relink-metal-toolchain: $message"
    else
        echo "relink-metal-toolchain: $message"
    end
end

if not test -d $xcode_usr
    __rmt_log error "no xcode toolchain at $xcode_usr"
    exit 1
end

# the glob must be written inline: fish does not re-expand a wildcard stored in a
# variable. an unmatched glob yields an empty list here rather than an error.
set -l mounted (path filter -d -- \
    /private/var/run/com.apple.security.cryptexd/mnt/*/Metal.xctoolchain/usr/metal)

if test (count $mounted) -eq 0
    __rmt_log error 'no metal toolchain cryptex is mounted'
    __rmt_log info 'install it with: sudo xcodebuild -downloadComponent MetalToolchain'
    exit 1
end

# last entry wins if a stale mount is still lingering from a previous boot
set -l target $mounted[-1]
set -l current (path resolve $xcode_usr/metal)

if test "$current" = "$target"
    __rmt_log info "already linked to $target"
    exit 0
end

__rmt_log info "linking $xcode_usr/metal -> $target"
sudo ln -sfn $target $xcode_usr/metal
set -l rc $status

if test $rc -ne 0
    __rmt_log error "could not create the link (sudo exited $rc)"
    exit $rc
end

if not xcrun metal --version >/dev/null 2>&1
    __rmt_log error "link created but 'xcrun metal' still fails"
    exit 1
end

__rmt_log info 'metal toolchain is working'
