{
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "jls-study-mode";
  version = "0.1.0";

  src = ./.;

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp package.json $out/
    cp -R skills $out/

    runHook postInstall
  '';
}
