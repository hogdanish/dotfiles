function hogdot --description 'Run the most recently compiled hogdot editor (the WebGPU Godot fork)'
    # ⚠ The stock `godot` (Homebrew -> /Applications/Godot.app) does NOT know
    # hogdot-only project settings such as `rendering_device/driver.web`, and
    # DROPS them when it re-serialises project.godot — silently un-selecting the
    # WebGPU backend for a web export. Open and export COMMONGROUNDS with this.

    set -l root (test -n "$HOGDOT_DIR"; and echo $HOGDOT_DIR; or echo "$HOME/Projects/hogdot")

    if not test -d $root/bin
        echo "hogdot: no build directory at $root/bin (set \$HOGDOT_DIR?)" >&2
        return 1
    end

    # newest editor binary by mtime — arch/target agnostic, so a future
    # x86_64/dev build is picked up without editing this function
    set -l bin (find $root/bin -maxdepth 1 -type f -perm -u+x -name 'godot.macos.editor.*' \
        -not -name '*.dSYM' -not -name '*.zip' 2>/dev/null \
        | xargs -r stat -f '%m %N' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

    if test -z "$bin"
        echo "hogdot: no compiled editor in $root/bin — build one:" >&2
        echo "  cd $root; and scons platform=macos target=editor arch=arm64" >&2
        return 1
    end

    # no args -> open the project in the current directory, else COMMONGROUNDS
    if test (count $argv) -eq 0
        if test -f ./project.godot
            set argv --editor --path (pwd)
        else
            set argv --editor --path "$HOME/Projects/commongrounds"
        end
    end

    echo "hogdot: "(basename $bin)" ("(date -r (stat -f %m $bin) '+%Y-%m-%d %H:%M')")" >&2
    command $bin $argv
end
