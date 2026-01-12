{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    generators
    escapeShellArg
    concatStringsSep
    concatMapStringsSep
    optionalString
    ;

  cfg = config.programs.azookey;

  # Import presets
  presets = import ./presets.nix { inherit pkgs; };

  domain = "dev.ensan.inputmethod.azooKeyMac";
  prefixKey = key: "${domain}.preference.${key}";

  # Helper to write UserDefaults
  writeDefault =
    key: value:
    let
      fullKey = prefixKey key;
      plistValue = generators.toPlist { } value;
    in
    "defaults write ${domain} ${escapeShellArg fullKey} ${escapeShellArg plistValue}";

  # Helper to write JSON-encoded values
  writeJsonDefault =
    key: value:
    let
      fullKey = prefixKey key;
      jsonValue = builtins.toJSON value;
    in
    ''defaults write ${domain} ${escapeShellArg fullKey} -string ${escapeShellArg jsonValue}'';

  # Helper to delete UserDefaults
  deleteDefault =
    key:
    let
      fullKey = prefixKey key;
    in
    "defaults delete ${domain} ${escapeShellArg fullKey} 2>/dev/null || true";

  # Convert a setting to either write or delete command
  settingToCommand =
    key: value: writeOrDelete:
    if value == null then deleteDefault key else writeOrDelete key value;

  # Convert settings to defaults write/delete commands
  settingsToCommands =
    let
      # Boolean and string settings (use plist encoding)
      settings = {
        enableLiveConversion = cfg.settings.enableLiveConversion;
        typeBackSlash = cfg.settings.typeBackSlash;
        typeHalfSpace = cfg.settings.typeHalfSpace;
        includeContextInAITransform = cfg.settings.includeContextInAITransform;
        ZenzaiProfile = cfg.settings.zenzaiProfile;
        OpenAiModelName = cfg.settings.openAiModelName;
        OpenAiApiEndpoint = cfg.settings.openAiApiEndpoint;
      };

      # JSON-encoded settings (enums and custom types)
      jsonSettings = {
        punctuation_style = cfg.settings.punctuationStyle;
        input_style = cfg.settings.inputStyle;
        keyboard_layout = cfg.settings.keyboardLayout;
        learning = cfg.settings.learning;
        aiBackend = cfg.settings.aiBackendPreference;
        "zenzai.personalization_level" = cfg.settings.zenzaiPersonalizationLevel;
      };
    in
    (lib.mapAttrsToList (k: v: settingToCommand k v writeDefault) settings)
    ++ (lib.mapAttrsToList (k: v: settingToCommand k v writeJsonDefault) jsonSettings);

  customInputTablePath = "${config.home.homeDirectory}/Library/Containers/${domain}/Data/Library/Application Support/azooKeyMac/CustomInputTable/custom_input_table.tsv";

  # Convert list of {input, output} to TSV format
  tableToTsv = table: concatMapStringsSep "\n" (entry: "${entry.input}\t${entry.output}") table;
in
{
  options.programs.azookey = {
    enable = mkEnableOption "azooKey Japanese Input Method configuration";

    settings = {
      # Boolean settings
      enableLiveConversion = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable live conversion (ライブ変換).";
      };

      typeBackSlash = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Type backslash instead of yen symbol (`¥` → `\\`).";
      };

      typeHalfSpace = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Type half-width space instead of full-width space (`　` → ` `).";
      };

      includeContextInAITransform = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Include context in AI transformation.";
      };

      # String settings
      zenzaiProfile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Zenzai profile configuration.";
      };

      openAiModelName = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "gpt-4o-mini";
        description = "OpenAI model name for AI features.";
      };

      openAiApiEndpoint = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "https://api.openai.com/v1/chat/completions";
        description = "OpenAI API endpoint.";
      };

      # Enum settings
      punctuationStyle = mkOption {
        type = types.nullOr (
          types.enum [
            1
            2
            3
            4
          ]
        );
        default = null;
        description = ''
          Punctuation style:
          - 1: 。、(kuten and toten)
          - 2: 。，(kuten and comma)
          - 3: .、(period and toten)
          - 4: .，(period and comma)
        '';
      };

      inputStyle = mkOption {
        type = types.nullOr (
          types.enum [
            "default"
            "defaultAZIK"
            "defaultKanaJIS"
            "defaultKanaUS"
            "custom"
          ]
        );
        default = null;
        description = "Input style (romaji, AZIK, kana, or custom).";
      };

      keyboardLayout = mkOption {
        type = types.nullOr (
          types.enum [
            "qwerty"
            "colemak"
            "dvorak"
            "dvorakQwertyCommand"
          ]
        );
        default = null;
        description = "Keyboard layout.";
      };

      learning = mkOption {
        type = types.nullOr (
          types.enum [
            "inputAndOutput"
            "onlyOutput"
            "nothing"
          ]
        );
        default = null;
        description = ''
          Learning mode:
          - inputAndOutput: Learn from both input and output
          - onlyOutput: Learn only from output
          - nothing: Disable learning
        '';
      };

      aiBackendPreference = mkOption {
        type = types.nullOr (
          types.enum [
            "Off"
            "Foundation Models"
            "OpenAI API"
          ]
        );
        default = null;
        description = "AI backend preference.";
      };

      zenzaiPersonalizationLevel = mkOption {
        type = types.nullOr (
          types.enum [
            "off"
            "soft"
            "normal"
            "hard"
          ]
        );
        default = null;
        description = "Zenzai personalization level.";
      };
    };

    customInputTable = mkOption {
      type = types.nullOr (
        types.listOf (
          types.submodule {
            options = {
              input = mkOption {
                type = types.str;
                description = "Input sequence (romaji/kana)";
                example = "ji";
              };
              output = mkOption {
                type = types.str;
                description = "Output character(s)";
                example = "じ";
              };
            };
          }
        )
      );
      default = null;
      example = lib.literalExpression ''
        presets.presetAzik ++ [
          { input = "ji"; output = "じ"; }
          { input = "custom"; output = "カスタム"; }
        ]
      '';
      description = ''
        Custom input table as a list of input-output mappings.
        You can use preset tables like `presets.presetAzik` and extend them with your own entries.
      '';
    };

    # Export presets for users to access
    presets = mkOption {
      type = types.anything;
      readOnly = true;
      default = presets;
      description = "Available input table presets";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "programs.azookey is only supported on macOS";
      }
    ];

    home.activation.azookeySettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      let
        commands = settingsToCommands;
        hasSettings = commands != [ ];
        setupCustomTable = optionalString (cfg.customInputTable != null) ''
          echo "Setting up azooKey custom input table..." >&2
          CUSTOM_TABLE_DIR="$(dirname ${escapeShellArg customInputTablePath})"
          mkdir -p "$CUSTOM_TABLE_DIR"
          cat > ${escapeShellArg customInputTablePath} << 'EOF'
          ${tableToTsv cfg.customInputTable}
          EOF
        '';
      in
      ''
        ${optionalString hasSettings ''
          echo "Applying azooKey settings..." >&2
          ${concatStringsSep "\n" commands}
        ''}
        ${setupCustomTable}
      ''
    );
  };

  meta.maintainers = with lib.maintainers; [ cffnpwr ];
}
