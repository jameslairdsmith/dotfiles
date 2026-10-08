{
  lib,
  stdenv,
  fetchurl,
  bun2nix,
}:

stdenv.mkDerivation rec {
  pname = "pi-subagents";
  version = "0.76.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/pi-subagents/-/pi-subagents-${version}.tgz";
    hash = "sha256-NpJm+CBKoI4xqZWBe+AHBizceSET4m0k+fBAIXU9wIA=";
  };

  nativeBuildInputs = [
    bun2nix.hook
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
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R . $out/

    runHook postInstall
  '';

  meta = {
    description = "Subagents extension package for Pi coding agent";
    homepage = "https://github.com/nicobailon/pi-subagents";
    license = lib.licenses.mit;
  };
}
