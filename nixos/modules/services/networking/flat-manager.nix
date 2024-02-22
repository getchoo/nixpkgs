{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mapNullable
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.services.flat-manager;

  settingsFormat = pkgs.format.json { };
in
{
  options.services.flat-manager = {
    enable = mkEnableOption "flat-manager";
    package = mkPackageOption pkgs "flat-manager" { };

    domain = mkOption {
      type = types.str;
      description = "The hostname flat-manager should use.";
    };

    port = mkOption {
      type = types.port;
      default = 3532;
      description = ''
        The port flat-manager should listen on for new connections.
      '';
    };

    database = {
      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to create a local database with PostgreSQL.
        '';
      };

      host = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The hostname of the database to connect to.

          If `null`, a local unix socket is used. Otherwise,
          TCP is used.
        '';
      };

      port = mkOption {
        type = types.nullOr types.str;
        inherit (options.services.postgresql.port) default;
        defaultText = literalExpression "options.services.postgresql.port.default";
        description = ''
          The Port of the database to connect to.
        '';
      };

      name = mkOption {
        type = types.str;
        default = "flat-manager";
        description = ''
          The name of the database to connect to.
        '';
      };

      user = mkOption {
        type = types.str;
        default = "flat-manager";
        description = ''
          The user to connect to the database as.
        '';
      };

      passwordFile = mkOption {
        type = types.nullOr types.str;
        apply = mapNullable toString;
        default = null;
        example = "/run/secrets/database-password.txt";
        description = ''
          The path to a file containing the database password.
        '';
      };
    };

    settings = mkOption {
      inherit (settingsFormat) type;
      default = { };
      description = ''
        The settings flat-manager should use.

        For a full list of options, see [example-config.json](https://github.com/flatpak/flat-manager/blob/master/example-config.json).
      '';
    };

    settingsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression "/run/secrets/flat-manager-settings.json";
      description = ''
        Path to the settings file to use. May not be used with `services.flat-manager.settings`.

        For a full list of options, see [example-config.json](https://github.com/flatpak/flat-manager/blob/master/example-config.json).
      '';
    };

    nginx = mkOption {
      type = types.nullOr (types.submodule (import ../web-servers/nginx/vhost-options.nix));
      default = null;
      example = literalExpression ''
        {
          enableACME = true;
          forceSSL = true;
        }
      '';
      description = ''
        With this option, you can customize an nginx virtual host which already has sensible defaults for flat-manager.
        Set to {} if you do not need any customization to the virtual host.
        If enabled, then by default, the {option}`serverName` is
        `''${domain}`,
        If this is set to null (the default), no nginx virtualHost will be configured.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.database.createLocally {
      services.postgresql = {
        enable = mkDefault true;

        ensureDatabases = [ cfg.database.name ];
        ensureUsers = [
          {
            name = cfg.database.user;
            ensureDBOwnership = true;
          }
        ];
      };
    })
  ]);
}
