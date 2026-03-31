function gclw
    set url $argv[1]
    set repo_name (basename $url .git)

    mkdir -p $repo_name
    git clone --bare $url $repo_name/.bare
    echo "gitdir: ./.bare" > $repo_name/.git
end

complete -c gchw -f -a '(begin
    set -l worktree_branches (git worktree list --porcelain 2>/dev/null | grep "^branch " | string replace "branch refs/heads/" "")
    for branch in (git branch -a --format="%(refname:short)" 2>/dev/null)
        if not contains -- $branch $worktree_branches
            echo $branch
        end
    end
end)'

function gchw
    if not git rev-parse --git-dir > /dev/null 2>&1
        echo "error: not in a git worktree repository" >&2
        return 1
    end

    set branch $argv[1]
    git worktree add $branch $branch
    git -C $branch submodule update --init --recursive
end
