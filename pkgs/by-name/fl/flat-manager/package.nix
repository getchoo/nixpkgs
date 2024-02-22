{
  lib,
  rustPlatform,
  fetchFromGitHub,
  glib,
  openssl,
  ostree,
  pkg-config,
  postgresql,
}:

rustPlatform.buildRustPackage rec {
  pname = "flat-manager";
  version = "0.4.3.1";

  src = fetchFromGitHub {
    owner = "flatpak";
    repo = "flat-manager";
    rev = "refs/tags/${version}";
    hash = "sha256-GlKt7qXGHPXyVxRnChYuqNgUtrWxfzpmF81Zrj3kzyc=";
  };

  cargoPatches = [
    # https://github.com/NixOS/nixpkgs/issues/332957
    ./update-time.patch
  ];

  cargoHash = "sha256-lHVqzSAUTcPOnCh6dHI95LL2Uz5muA5YqGvidAW2z9Q=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    glib
    openssl
    ostree
    postgresql # required for diesel backend
  ];

  meta = {
    description = "Manager for flatpak repositories";
    longDescription = ''
      flat-manager serves and maintains a Flatpak repository. You point it at an ostree
      repository and it will allow Flatpak clients to install apps from the repository over HTTP.
      Additionally, it has an HTTP API that lets you upload new builds and manage the repository.
    '';
    homepage = "https://github.com/flatpak/flat-manager";
    changelog = "https://github.com/flatpak/flat-manager/releases/tag/${version}";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ getchoo ];
    mainProgram = "flat-manager";
    platforms = lib.platforms.linux;
  };
}
