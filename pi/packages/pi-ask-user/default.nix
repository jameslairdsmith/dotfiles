{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "pi-ask-user";
  version = "0.16.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/pi-ask-user/-/pi-ask-user-${version}.tgz";
    hash = "sha256-38h0WFtcITuaIvbwSMJoRH9XNrQoAZDGZEPSTfuqq7o=";
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
    description = "Interactive ask_user tool for Pi coding agent";
    homepage = "https://github.com/edlsh/pi-ask-user";
    license = lib.licenses.mit;
  };
}
