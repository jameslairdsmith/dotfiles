{
  lib,
  stdenv,
  fetchFromGitHub,
  bun2nix,
  python3,
}:

stdenv.mkDerivation rec {
  pname = "pi-web-access";
  version = "0.35.0";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "72c6e67787d67d8a7d01bf0abf30c072a6112de6";
    hash = "sha256-GOT/Nym/oWLUHoO6zzvWnEeq+pXiTh/QF4VTY4vbT8s=";
  };

  nativeBuildInputs = [
    bun2nix.hook
    python3
  ];

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./bun.nix;
  };

  # Hoisted installs avoid isolated-linker resolution surprises. On Darwin the
  # copyfile backend works reliably with Nix store permissions.
  bunInstallFlags =
    if stdenv.hostPlatform.isDarwin then
      [
        "--linker=hoisted"
        "--backend=copyfile"
      ]
    else
      [
        "--linker=hoisted"
      ];

  dontUseBunBuild = true;
  dontUseBunCheck = true;

  postPatch = ''
    cp ${./bun.lock} bun.lock

    python3 - <<'PY'
    import json

    path = "package.json"
    with open(path) as f:
        pkg = json.load(f)

    # Pi supplies these at runtime. Keeping them out of the install-time
    # manifest avoids bundling duplicate host packages into this Nix-built
    # package and prevents Bun from trying to resolve optional peers.
    for section in ["devDependencies", "peerDependencies", "peerDependenciesMeta"]:
        for name in list(pkg.get(section, {})):
            if name.startswith("@earendil-works/"):
                del pkg[section][name]

    # Load the built extension bundle, not source TypeScript.
    pkg.setdefault("pi", {})["extensions"] = ["./dist"]

    with open(path, "w") as f:
        json.dump(pkg, f, indent=2)
        f.write("\n")
    PY
  '';

  buildPhase = ''
    runHook preBuild
    bun run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    python3 - <<'PY'
    import json

    path = "package.json"
    with open(path) as f:
        pkg = json.load(f)

    pkg.setdefault("peerDependencies", {}).update({
        "@earendil-works/pi-ai": "*",
        "@earendil-works/pi-coding-agent": "*",
        "@earendil-works/pi-tui": "*",
    })
    pkg.setdefault("peerDependenciesMeta", {}).update({
        "@earendil-works/pi-ai": {"optional": True},
        "@earendil-works/pi-coding-agent": {"optional": True},
        "@earendil-works/pi-tui": {"optional": True},
    })

    with open(path, "w") as f:
        json.dump(pkg, f, indent=2)
        f.write("\n")
    PY

    mkdir -p $out
    cp package.json README.md CHANGELOG.md LICENSE banner.png \
      pi-web-fetch-demo.mp4 $out/
    cp -R dist $out/dist

    mkdir -p $out/node_modules
    cp -R node_modules/. $out/node_modules/

    runHook postInstall
  '';

  meta = {
    description = "Web access extension package for Pi coding agent";
    homepage = "https://github.com/nicobailon/pi-web-access";
    license = lib.licenses.mit;
  };
}
