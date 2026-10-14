{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  nodejs_22,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "chrome-devtools-mcp";
  version = "1.10.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-${finalAttrs.version}.tgz";
    hash = "sha256-ASy89ugy1PZwna0MIde+8XCJ6Ure6c8zF50V6gqa3ys=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p \
      "$out/bin" \
      "$out/libexec/chrome-devtools-mcp" \
      "$out/share/licenses/chrome-devtools-mcp"

    cp -R build package.json "$out/libexec/chrome-devtools-mcp/"
    install -Dm644 LICENSE "$out/share/licenses/chrome-devtools-mcp/LICENSE"

    makeWrapper \
      ${nodejs_22}/bin/node \
      "$out/bin/chrome-devtools-mcp" \
      --add-flags \
      "$out/libexec/chrome-devtools-mcp/build/src/bin/chrome-devtools-mcp.js"

    runHook postInstall
  '';

  meta = {
    description = "MCP server for Chrome DevTools";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = lib.licenses.asl20;
    mainProgram = "chrome-devtools-mcp";
    platforms = lib.platforms.unix;
  };
})
