{
  mkKdeDerivation,
  qtdeclarative,
}:
mkKdeDerivation {
  pname = "polkit-kde-agent-1";

  extraBuildInputs = [ qtdeclarative ];

  passthru = {
    dbusName = "org.kde.polkit-kde-authentication-agent-1";
    polkitAgentPath = "libexec/polkit-kde-authentication-agent-1";
  };
}
