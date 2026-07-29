function extract --description 'extract an archive, picking the tool from the file extension'
    if test (count $argv) -eq 0
        echo >&2 'extract: expected at least one archive'
        return 2
    end

    set -l failed 0
    for archive in $argv
        if not test -f $archive
            echo >&2 "extract: no such file: $archive"
            set failed 1
            continue
        end

        # quote the case globs — an unquoted `*.tar.gz` would be filename-expanded
        switch $archive
            case '*.tar.bz2' '*.tbz2'
                tar -xjf $archive
            case '*.tar.gz' '*.tgz'
                tar -xzf $archive
            case '*.tar.xz' '*.txz'
                tar -xJf $archive
            case '*.tar.zst'
                tar --zstd -xf $archive
            case '*.tar'
                tar -xf $archive
            case '*.gz'
                gunzip -k $archive
            case '*.bz2'
                bunzip2 -k $archive
            case '*.zip' '*.jar' '*.war' '*.xpi' '*.whl'
                unzip -q $archive
            case '*.7z' '*.rar' '*.dmg' '*.iso'
                # keka handles the formats the base system does not; it is a cask here
                if type -q keka
                    keka $archive
                else
                    echo >&2 "extract: no handler for $archive (keka is not on \$PATH)"
                    set failed 1
                end
            case '*'
                echo >&2 "extract: unknown archive type: $archive"
                set failed 1
        end
        or set failed 1
    end

    return $failed
end
