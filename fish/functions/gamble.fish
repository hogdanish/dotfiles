# functions/gamble.fish
function gamble --description 'launch keep gambling in the crossover steam bottle'
    set -l wine /Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine
    # the real game binary — steam's Kaching.exe wrapper false-positives a
    # missing-vc++ check under wine, so we bypass it (steam_appid.txt sits
    # beside this exe to keep steamworks connected to the running client)
    set -l exe 'C:\Program Files (x86)\Steam\steamapps\common\KEEP GAMBLING\Kaching\Binaries\Win64\Kaching-Win64-Shipping.exe'
    set -l macexe "$HOME/Library/Application Support/CrossOver/Bottles/Steam/drive_c/Program Files (x86)/Steam/steamapps/common/KEEP GAMBLING/Kaching/Binaries/Win64/Kaching-Win64-Shipping.exe"

    if not test -x $wine
        echo >&2 'gamble: crossover is not installed'
        return 1
    end
    if not test -x $macexe
        echo >&2 'gamble: keep gambling is not installed in the steam bottle'
        return 1
    end

    # steamworks needs the steam client alive in the same bottle — and fully
    # started: the game null-derefs at second 0 (same stack with and without
    # -dx11) when it initialises against a half-ready client
    if not pgrep -qif steam.exe
        echo >&2 'gamble: starting steam in the bottle first…'
        $wine --bottle Steam 'C:\Program Files (x86)\Steam\steam.exe' -silent &
        disown
        for i in (seq 30)
            pgrep -qif steamwebhelper
            and break
            sleep 1
        end
        sleep 5
    end

    # -dx11 is the dev's own fallback launch option in steam
    $wine --bottle Steam $exe -dx11 $argv &
    disown
end
