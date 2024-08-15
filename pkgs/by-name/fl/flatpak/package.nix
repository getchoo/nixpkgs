{
  lib,
  stdenv,
  appstream,
  bison,
  bubblewrap,
  bzip2,
  coreutils,
  curl,
  dbus,
  dconf,
  desktop-file-utils,
  docbook-xsl-nons,
  docbook_xml_dtd_45,
  fetchurl,
  fuse3,
  gettext,
  glib,
  glib-networking,
  gobject-introspection,
  gpgme,
  gsettings-desktop-schemas,
  gtk-doc,
  gtk3,
  hicolor-icon-theme,
  intltool,
  json-glib,
  libarchive,
  libcap,
  librsvg,
  libseccomp,
  libxml2,
  libxslt,
  meson,
  ninja,
  nix-update-script,
  nixos-icons,
  nixosTests,
  ostree,
  p11-kit,
  pkg-config,
  pkgsCross,
  polkit,
  python3,
  runCommand,
  shared-mime-info,
  socat,
  substituteAll,
  systemd,
  testers,
  valgrind,
  which,
  wrapGAppsNoGuiHook,
  xdg-dbus-proxy,
  xmlto,
  xorg,
  xz,
  zstd,
  withGtkDoc ? stdenv.buildPlatform.canExecute stdenv.hostPlatform,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "flatpak";
  version = "1.14.10";

  # TODO: split out lib once we figure out what to do with triggerdir
  outputs = [
    "out"
    "dev"
    "man"
    "doc"
    "devdoc"
    "installedTests"
  ];

  separateDebugInfo = true;

  src = fetchurl {
    url = "https://github.com/flatpak/flatpak/releases/download/${finalAttrs.version}/flatpak-${finalAttrs.version}.tar.xz";
    hash = "sha256-a73HkIEnNQrYWkpH1wKSyi9MRul3sysf0jHCpxnYIc0=";
  };

  patches = [
    # Hardcode paths used by tests and change test runtime generation to use files from Nix store.
    # https://github.com/flatpak/flatpak/issues/1460
    (substituteAll {
      src = ./fix-test-paths.patch;
      inherit
        coreutils
        gettext
        gtk3
        socat
        ;
      dfu = desktop-file-utils;
      hicolorIconTheme = hicolor-icon-theme;
      smi = shared-mime-info;
    })

    # Hardcode paths used by Flatpak itself.
    (substituteAll {
      src = ./fix-paths.patch;
      p11kit = lib.getExe' p11-kit "p11-kit";
    })

    # Use flatpak from PATH to avoid references to `/nix/store` in `/desktop` files.
    # Applications containing `DBusActivatable` entries should be able to find the flatpak binary.
    # https://github.com/NixOS/nixpkgs/issues/138956
    ./binary-path.patch

    # Try mounting fonts and icons from NixOS locations if FHS locations don't exist.
    # https://github.com/NixOS/nixpkgs/issues/119433
    ./fix-fonts-icons.patch

    # Allow gtk-doc to find schemas using XML_CATALOG_FILES environment variable.
    # Patch taken from gtk-doc expression.
    ./respect-xml-catalog-files-var.patch

    # Nix environment hacks should not leak into the apps.
    # https://github.com/NixOS/nixpkgs/issues/53441
    ./unset-env-vars.patch

    # The icon validator needs to access the gdk-pixbuf loaders in the Nix store
    # and cannot bind FHS paths since those are not available on NixOS.
    finalAttrs.passthru.icon-validator-patch

    # Try mounting fonts and icons from NixOS locations if FHS locations don't exist.
    # https://github.com/NixOS/nixpkgs/issues/119433
    ./fix-fonts-icons.patch
  ];

  postPatch = ''
    patchShebangs buildutil
    patchShebangs tests
    patchShebangs --build subprojects/variant-schema-compiler/variant-schema-compiler
  '';

  strictDeps = true;

  nativeBuildInputs = [
    (python3.pythonOnBuildForHost.withPackages (p: [ p.pyparsing ]))
    bison
    docbook-xsl-nons
    docbook_xml_dtd_45
    gobject-introspection
    # NOTE: this is required regardless of the GTK docs being built
    gtk-doc
    intltool
    libxml2
    libxslt
    meson
    ninja
    pkg-config
    which
    wrapGAppsNoGuiHook
    xmlto
  ];

  buildInputs = [
    appstream
    bubblewrap
    bzip2
    curl
    dbus
    dconf
    fuse3
    fuse3
    glib-networking
    glib-networking
    gpgme
    gsettings-desktop-schemas
    gsettings-desktop-schemas
    json-glib
    libarchive
    libcap
    librsvg # for flatpak-validate-icon
    librsvg # for flatpak-validate-icon
    libseccomp
    libxml2
    polkit
    python3
    systemd
    xorg.libXau
    xz
    zstd
  ] ++ lib.optional withGtkDoc gtk-doc;

  # Required by flatpak.pc
  propagatedBuildInputs = [
    glib
    ostree
  ];

  nativeCheckInputs = [ valgrind ];

  # TODO: some issues with temporary files
  doCheck = false;

  mesonFlags = [
    (lib.mesonEnable "gtkdoc" withGtkDoc)
    (lib.mesonEnable "installed_tests" true)
    (lib.mesonEnable "selinux_module" false)
    (lib.mesonEnable "tests" finalAttrs.doCheck)
    (lib.mesonOption "dbus_config_dir" (placeholder "out" + "/share/dbus-1/system.d"))
    (lib.mesonOption "http_backend" "curl")
    (lib.mesonOption "profile_dir" (placeholder "out" + "/etc/profile.d"))
    (lib.mesonOption "system_bubblewrap" (lib.getExe bubblewrap))
    (lib.mesonOption "system_dbus_proxy" (lib.getExe xdg-dbus-proxy))
    (lib.mesonOption "system_install_dir" "/var/lib/flatpak")
  ];

  env = {
    NIX_LDFLAGS = "-lpthread";
  };

  passthru = {
    icon-validator-patch = substituteAll {
      src = ./fix-icon-validation.patch;
      inherit (builtins) storeDir;
    };

    tests = {
      cross = pkgsCross.aarch64-multiplatform.flatpak;

      installedTests = nixosTests.installed-tests.flatpak;

      validate-icon = runCommand "test-icon-validation" { } ''
        ${finalAttrs.finalPackage}/libexec/flatpak-validate-icon \
          --sandbox 512 512 \
          "${nixos-icons}/share/icons/hicolor/512x512/apps/nix-snowflake.png" > "$out"

        grep format=png "$out"
      '';

      version = testers.testVersion { package = finalAttrs.finalPackage; };
    };

    updateScript = nix-update-script { };
  };

  meta = {
    description = "Linux application sandboxing and distribution framework";
    homepage = "https://flatpak.org/";
    changelog = "https://github.com/flatpak/flatpak/releases/tag/${finalAttrs.version}";
    license = lib.licenses.lgpl21Plus;
    maintainers = with lib.maintainers; [ getchoo ];
    platforms = lib.platforms.linux;
  };
})
