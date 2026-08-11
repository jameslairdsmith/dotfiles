{
  inputs,
  pkgs,
  ...
}:
{
  home.packages = [
    inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.default
    (pkgs.writeShellScriptBin "wt-clone" ''
      set -e
      url="$1"
      repo_name="$(basename "$url" .git)"
      mkdir -p "$repo_name"
      git clone --bare "$url" "$repo_name/.bare"
      echo "gitdir: ./.bare" > "$repo_name/.git"
      git -C "$repo_name" config remote.origin.fetch \
        "+refs/heads/*:refs/remotes/origin/*"
      git -C "$repo_name" fetch origin
      default_branch="$(git -C "$repo_name" symbolic-ref --short HEAD)"
      git -C "$repo_name" branch \
        --set-upstream-to="origin/$default_branch" "$default_branch"
    '')
  ];

  home.file.".config/worktrunk/config.toml".source = ../../worktrunk/config.toml;
}
