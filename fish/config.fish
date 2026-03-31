function gcw
    set url $argv[1]
    set repo_name (basename $url .git)

    mkdir -p $repo_name
    git clone --bare $url $repo_name/.bare
    echo "gitdir: ./.bare" > $repo_name/.git
end
