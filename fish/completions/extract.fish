# -k keeps the order given, so archives sort above everything else rather than being
# alphabetised in among ordinary files.
complete -c extract -k -a '(__fish_complete_suffix .tar.gz .tgz .tar.bz2 .tbz2 .tar.xz .txz .tar.zst .tar .zip .7z .rar .gz .bz2 .dmg .iso .jar .whl)'
