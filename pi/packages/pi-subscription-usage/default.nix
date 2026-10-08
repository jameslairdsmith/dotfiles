{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "pi-subscription-usage";
  version = "1.3.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@specode/pi-subscription-usage/-/pi-subscription-usage-${version}.tgz";
    hash = "sha512-dbZpEziIX7zezVz3plD4OZfeApBPDy+k1k+TYgeTcPcnApl/fIEesAGk+O7wCRkyVud87eCzpT2KBhm8FYQPoA==";
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
    description = "Subscription quota extension package for Pi coding agent";
    homepage = "https://github.com/specode/pi-subscription-usage";
    license = lib.licenses.mit;
  };
}
