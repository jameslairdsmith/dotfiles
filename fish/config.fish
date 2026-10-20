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

function cdf --description "Fuzzy cd into a directory from common roots"
    if not type -q fzf
        echo "cdf: fzf is not installed" >&2
        return 1
    end

    set -l root_candidates ~ /Applications /Volumes /opt
    set -l roots

    for root in $root_candidates
        if test -d $root
            set -a roots $root
        end
    end

    if test (count $roots) -eq 0
        echo "cdf: no search roots exist" >&2
        return 1
    end

    set -l dir (
        fzf \
            --prompt="cd> " \
            --walker=dir,follow,hidden \
            --walker-root $roots \
            --walker-skip=.git,node_modules,.direnv,.devenv,.cache,.Trash,Library,result,dist,build,.next,target
    )

    if test -n "$dir"
        cd "$dir"
    end
end

function cdmacs --description "Choose a directory with Emacs and cd into it"
    if not type -q cdmacs-picker
        echo "cdmacs: cdmacs-picker is not installed" >&2
        return 1
    end

    set -l output (mktemp -t cdmacs.XXXXXX); or return
    command cdmacs-picker "$output"
    set -l picker_status $status
    set -l directory

    if test $picker_status -eq 0; and test -s "$output"
        read -z directory < "$output"
    end
    command rm -f "$output"

    if test -n "$directory"; and test -d "$directory"
        cd "$directory"
    else
        return $picker_status
    end
end

function cdp --description "Fuzzy cd into a project under ~/projects"
    set -l projects_dir ~/projects

    if not test -d $projects_dir
        echo "cdp: $projects_dir does not exist" >&2
        return 1
    end

    set -l project (
        command find $projects_dir -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null \
            | sort \
            | fzf --prompt="projects> "
    )

    if test -n "$project"
        cd "$projects_dir/$project"
    end
end
