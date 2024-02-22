{
  python3Packages,
  flat-manager,
  gobject-introspection,
  ostree,
  wrapGAppsHook4,
}:
python3Packages.buildPythonApplication {
  pname = "flat-manager-client";
  inherit (flat-manager) version src;
  pyproject = false;

  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook4
  ];

  buildInputs = [ ostree ];

  dependencies = with python3Packages; [
    aiohttp
    pygobject3
    tenacity
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 {,$out/bin/}flat-manager-client
    runHook postInstall
  '';

  makeWrapperArgs = [ "\${gappsWrapperArgs[@]}" ];

  meta = {
    inherit (flat-manager.meta)
      longDescription
      homepage
      changelog
      license
      maintainers
      platforms
      ;

    description = flat-manager.meta.description + " (Client)";
    mainProgram = "flat-manager-client";
  };
}
