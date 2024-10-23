{
  config,
  lib,
  ...
}:
let
  cfg = config.security.polkit.agent;
in
{
  options.security.polkit.agent = {
    enable = lib.mkEnableOption "a Polkit authentication agent";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The Polkit agent package to use.";
      example = lib.literalExpression "pkgs.kdePackages.polkit-kde-agent-1";
    };

    dbusName = lib.mkOption {
      type = lib.types.str;
      default = cfg.package.passthru.dbusName or null;
      defaultText = "config.security.polkit.agent.package.passthru.dbusName or null";
      description = "The D-Bus destination name of the agent.";
      example = lib.literalExpression "org.kde.polkit-kde-authentication-agent-1";
    };

    agentPath = lib.mkOption {
      type = lib.types.str;
      default = cfg.package.passthru.polkitAgentPath or null;
      apply = path: "${cfg.package}/${path}";
      defaultText = "config.security.polkit.agent.package.passthru.agentPath";
      description = "The path of the Polkit agent relative to `security.polkit.agent.package`.";
      example = lib.literalExpression ''
        "libexec/polkit-kde-authentication-agent-1"
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.polkit-agent = {
      description = "Polkit authentication agent";

      partOf = "graphical-session.target";
      after = "graphical-session.target";
      wantedBy = "graphical-session.target";

      script = cfg.agentPath;

      serviceConfig = {
        # NOTE: This makes the service of type `dbus`
        BusName = cfg.dbusName;

        Slice = "background.slice";

        Restart = "on-failure";
        TimeoutSec = "5sec";
      };
    };
  };
}
