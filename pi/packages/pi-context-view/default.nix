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

    runHook postInstall
  '';

  meta = {
    description = "Pi extension to visualise context usage and inspect hidden context injections";
    homepage = "https://github.com/dimk90/pi-context-view";
    license = lib.licenses.mit;
  };
}
