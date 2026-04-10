{ bash, bun, bun2nix, lib, makeWrapper, symlinkJoin }:

let
  manifest = builtins.fromJSON (builtins.readFile ./package-manifest.json);
  sourceRoot = lib.cleanSource ../.;
  licenseMap = {
    "MIT" = lib.licenses.mit;
    "Apache-2.0" = lib.licenses.asl20;
  };
  resolvedLicense =
    if builtins.hasAttr manifest.meta.licenseSpdx licenseMap
    then licenseMap.${manifest.meta.licenseSpdx}
    else lib.licenses.unfree;
  aliasOutputs = manifest.binary.aliases or [ ];
  aliasOutputLinks = lib.concatMapStrings
    (
      alias:
      ''
        mkdir -p "${"$" + alias}/bin"
        cat > "${"$" + alias}/bin/${alias}" <<EOF
#!${lib.getExe bash}
exec "$out/bin/${manifest.binary.name}" "\$@"
EOF
        chmod +x "${"$" + alias}/bin/${alias}"
      ''
    )
    aliasOutputs;
  basePackage = bun2nix.writeBunApplication {
    pname = manifest.package.repo;
    version = manifest.package.version;
    packageJson = ../package.json;
    src = sourceRoot;
    dontUseBunBuild = true;
    dontUseBunCheck = true;
    startScript = ''
      bun ${manifest.binary.entrypoint} "$@"
    '';
    bunDeps = bun2nix.fetchBunDeps {
      bunNix = ../bun.nix;
    };
    meta = with lib; {
      description = manifest.meta.description;
      homepage = manifest.meta.homepage;
      license = resolvedLicense;
      mainProgram = manifest.binary.name;
      platforms = platforms.linux ++ platforms.darwin;
      broken = !(builtins.pathExists ../bun.nix);
    };
  };
in
symlinkJoin {
  pname = manifest.binary.name;
  version = manifest.package.version;
  name = "${manifest.binary.name}-${manifest.package.version}";
  outputs = [ "out" ] ++ aliasOutputs;
  paths = [ basePackage ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    rm -rf "$out/bin"
    mkdir -p "$out/bin"
    cat > "$out/bin/${manifest.binary.name}" <<EOF
#!${lib.getExe bash}
exec ${lib.getExe' bun "bun"} "${sourceRoot}/${manifest.binary.entrypoint}" "\$@"
EOF
    chmod +x "$out/bin/${manifest.binary.name}"
    ${aliasOutputLinks}
  '';
  meta = basePackage.meta;
}
