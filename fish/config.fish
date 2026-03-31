function gcw
    set url $argv[1]
    set repo_name (basename $url .git)

    mkdir -p $repo_name
    git clone --bare $url $repo_name/.bare
    echo "gitdir: ./.bare" > $repo_name/.git
end

complete -c gchw -f -a '(git branch -a --format="%(refname:short)" 2>/dev/null)'

function gchw
    if not git rev-parse --git-dir > /dev/null 2>&1
        echo "error: not in a git worktree repository" >&2
        return 1
    end

    set branch $argv[1]
    git worktree add $branch $branch
end
