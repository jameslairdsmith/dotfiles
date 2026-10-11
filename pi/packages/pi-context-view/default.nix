{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "pi-context-view";
  version = "0.6.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/pi-context-view/-/pi-context-view-${version}.tgz";
    hash = "sha512-Ngo1m+3lzyi4AE1WxYW2MRKOAYdzvL3XcZSmJg27fqAlJPuDM3Rnp+rqheFBe3ElX+wsK4xZuv1CaZb+FrFKRA==";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R . $out/

    # Upstream declares its Pi extension as ./src/index.ts. Pi's compact
    # header labels for local packages are path-based, so that shows up as
    # "src". Expose a root index.ts wrapper instead so the label is the
    # package directory, "pi-context-view".
    substituteInPlace $out/package.json \
      --replace-fail '"./src/index.ts"' '"./index.ts"'
    cat > $out/index.ts <<'EOF'
    export { default } from "./src/index.ts";
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Pi extension to visualise context usage and inspect hidden context injections";
    homepage = "https://github.com/dimk90/pi-context-view";
    license = lib.licenses.mit;
  };
}
