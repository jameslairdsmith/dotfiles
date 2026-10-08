# Pi packages

This directory contains Pi packages that are managed declaratively with Nix.

Pi can install packages from npm, git, URLs, or local paths. For packages with
runtime npm dependencies, using Pi's installer directly would make part of the
setup mutable under `~/.pi/agent`. Instead, we build those packages with Nix and
then expose the realised package to Pi as a local package.

The intended flow is:

1. Keep the package build expression and generated dependency files in this
   directory.
2. Build the package from Home Manager/Nix.
3. Link the built result into Pi's agent directory, usually under:

   ```text
   ~/.pi/agent/packages/<package-name>
   ```

4. Declare the local package in `pi/settings.json`, for example:

   ```json
   {
     "packages": ["./packages/pi-web-access"]
   }
   ```

The relative path is resolved from Pi's agent settings directory, so the example
above points at `~/.pi/agent/packages/pi-web-access`.

## Why this exists

Small Pi extensions without dependencies can be linked directly from
`pi/extensions/` into `~/.pi/agent/extensions/`.

Larger Pi packages, especially those with npm dependencies, need more structure.
Pi's local package support does not install or modify local packages; their
`node_modules` tree must already be present. Nix is therefore responsible for
building the package and its dependencies ahead of time.

This gives us:

- reproducible dependency resolution;
- no imperative `pi install` state to reconcile;
- no mutable `node_modules` under `~/.pi/agent`;
- one Nix/Home Manager path for Pi itself, Pi settings, and Pi packages.

## Current packages

- `pi-web-access/` — web search, URL fetching, PDF extraction, GitHub access,
  and related web tools for Pi. Built with `bun2nix`.
- `pi-subagents/` — subagent delegation, built-in specialist agents, workflow
  prompts, and background jobs for Pi. Built from the npm package with
  `bun2nix`.
- `pi-subscription-usage/` — subscription quota reporting for Pi, including
  regular OpenAI ChatGPT subscription plan limits. Built from the npm package
  tarball.

## Regenerating a `bun2nix` package

For Bun-backed packages, the usual pattern is:

1. Fetch or clone the upstream package.
2. Patch `package.json` if needed before generating the lockfile.
3. Generate `bun.lock` with Bun.
4. Generate `bun.nix` with `bun2nix`.
5. Update the package derivation.
6. Build with:

   ```sh
   darwin-rebuild build --flake ./nix/hosts/neo#neo
   ```

For Pi packages, be careful with Pi host packages such as
`@earendil-works/pi-coding-agent`. They should generally be treated as host
provided peer dependencies rather than bundled runtime dependencies, otherwise an
extension may load duplicate Pi internals.
