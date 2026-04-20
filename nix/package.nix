{ bun, lib, stdenv, stdenvNoCC }:

let
  manifest = builtins.fromJSON (builtins.readFile ./package-manifest.json);
  src = builtins.path { path = ../.; name = "source"; };
  bunCompileTarget =
    {
      "x86_64-linux" = "bun-linux-x64";
      "aarch64-linux" = "bun-linux-arm64";
      "x86_64-darwin" = "bun-darwin-x64";
      "aarch64-darwin" = "bun-darwin-arm64";
    }.${stdenv.hostPlatform.system}
      or (throw "unsupported Bun compile target for ${stdenv.hostPlatform.system}");
  licenseMap = {
    "MIT" = lib.licenses.mit;
    "Apache-2.0" = lib.licenses.asl20;
  };
  resolvedLicense =
    if builtins.hasAttr manifest.meta.licenseSpdx licenseMap
    then licenseMap.${manifest.meta.licenseSpdx}
    else lib.licenses.unfree;
in
stdenvNoCC.mkDerivation {
  pname = manifest.binary.name;
  version = manifest.package.version;
  dontUnpack = true;

  nativeBuildInputs = [ bun ];

  buildPhase = ''
    runHook preBuild
    bun build \
      --compile \
      --target=${bunCompileTarget} \
      --format=esm \
      --bytecode \
      --outfile "$TMPDIR/${manifest.binary.name}" \
      ${src}/${manifest.binary.entrypoint}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    mv "$TMPDIR/${manifest.binary.name}" "$out/bin/${manifest.binary.name}"
    runHook postInstall
  '';

  meta = with lib; {
    description = manifest.meta.description;
    homepage = manifest.meta.homepage;
    license = resolvedLicense;
    mainProgram = manifest.binary.name;
    platforms = platforms.linux ++ platforms.darwin;
  };
}
