{
  lib,
  breakpointHook,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  nodejs,
  pnpm_9,
}:

let
  pnpm = pnpm_9;
in

buildGoModule rec {
  pname = "slash";
  version = "1.0.0-unstable-2025-02-12";

  src = fetchFromGitHub {
    owner = "yourselfhosted";
    repo = "slash";
    rev = "64359b1213fe36e250adc72be665e637c952cf4f";
    hash = "sha256-qZTehoINLqVCO//A9Osf/1Df6MQZ+RBbc04TbNbABGI=";
  };

  vendorHash = "sha256-QPeqH6EPPB0CaERM45Y9Cbu7BS9TN4p6eUpNKXCiHxc=";

  strictDeps = true;

  nativeBuildInputs = [
    breakpointHook
    nodejs
    pnpm.configHook
  ];

  checkFlags =
    let
      skippedTests = [
        "TestActiveLicenseKey"
        "TestValidateLicenseKey"
      ];
    in
    [ "-skip=^${lib.concatStringsSep "$|^" skippedTests}$" ];

  env = {
    pnpmDeps = pnpm.fetchDeps rec {
      inherit pname version src;
      sourceRoot = "${src.name}/frontend/web";

      hash = "sha256-K6v7ufNAuF+8tfWPJxVzMRDScHFyXUVsZ+PAntq5tFk=";
    };

    pnpmRoot = "frontend/web";
  };

  preBuild = ''
    pushd $pnpmRoot
    pnpm run postinstall
    pnpm build
    popd

    mv {$pnpmRoot,server/route/frontend}/dist
  '';

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Open source, self-hosted platform for sharing and managing your most frequently used links";
    homepage = "https://github.com/yourselfhosted/slash";
    changelog = "https://github.com/yourselfhosted/slash/releases/tag/${src.tag}";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ getchoo ];
    mainProgram = "slash";
  };
}
