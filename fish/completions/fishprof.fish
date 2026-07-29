complete -c fishprof -f
complete -c fishprof -s t -l threshold -x -d 'only show lines slower than N microseconds'
complete -c fishprof -s b -l bench -d 'also time repeated interactive startups'
complete -c fishprof -s n -l count -x -d 'how many startups to time with --bench'
