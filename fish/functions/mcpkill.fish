function mcpkill --description 'Kill all running Godot MCP server processes'
    # matches both servers, however npx spawned them
    set -l pattern 'satelliteoflove/godot-mcp|ryanmazzolini/minimal-godot-mcp'

    set -l signal TERM
    if contains -- -9 $argv; or contains -- --force $argv
        set signal KILL
    end

    set -l pids (pgrep -f $pattern)
    if test -z "$pids"
        echo "No Godot MCP server processes running."
        return 0
    end

    kill -$signal $pids
    echo "Killed "(count $pids)" Godot MCP server process(es) with SIG$signal: $pids"
end
