# Worktrunk shell integration
if type -q wt
    command wt config shell init fish | source
    complete --keep-order --exclusive --command wt --arguments "(test -n \"\$WORKTRUNK_BIN\"; or set -l WORKTRUNK_BIN (type -P wt 2>/dev/null); and COMPLETE=fish \$WORKTRUNK_BIN -- (commandline --current-process --tokenize --cut-at-cursor) (commandline --current-token))"
    functions -c wt __wt_orig
    function wt
        if test (count $argv) -ge 1; and test "$argv[1]" = "remove"
            __wt_orig remove --no-delete-branch $argv[2..]
        else
            __wt_orig $argv
        end
    end
end
