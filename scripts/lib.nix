{ lib }:
let
  self = {
    # Validate updateScript type and structure
    # Returns { isValid, errors } where errors is a list of error messages
    validateUpdateScript =
      pkg: updateScript:
      let
        errorPrefix = "Package '${pkg}': passthru.updateScript";

        # Check if attribute set has valid structure
        validateAttrSet =
          attrs:
          let
            hasCommand = attrs ? command;
            commandType = builtins.typeOf attrs.command;
            isCommandValid = hasCommand && (commandType == "string" || commandType == "list");

            attrPathType = if attrs ? attrPath then builtins.typeOf attrs.attrPath else null;
            isAttrPathValid = attrPathType == null || attrPathType == "string";

            supportedFeaturesType =
              if attrs ? supportedFeatures then builtins.typeOf attrs.supportedFeatures else null;
            isSupportedFeaturesValid = supportedFeaturesType == null || supportedFeaturesType == "list";

            errors =
              (if !hasCommand then [ "${errorPrefix}: attribute set must contain 'command' field" ] else [ ])
              ++ (
                if hasCommand && !isCommandValid then
                  [ "${errorPrefix}: 'command' must be a string or list, got ${commandType}" ]
                else
                  [ ]
              )
              ++ (
                if !isAttrPathValid then
                  [ "${errorPrefix}: 'attrPath' must be a string, got ${attrPathType}" ]
                else
                  [ ]
              )
              ++ (
                if !isSupportedFeaturesValid then
                  [ "${errorPrefix}: 'supportedFeatures' must be a list, got ${supportedFeaturesType}" ]
                else
                  [ ]
              );
          in
          {
            isValid = errors == [ ];
            errors = errors;
          };

        # Check if list is non-empty
        validateList =
          lst:
          if lst == [ ] then
            {
              isValid = false;
              errors = [ "${errorPrefix}: list must not be empty" ];
            }
          else
            {
              isValid = true;
              errors = [ ];
            };

        scriptType = builtins.typeOf updateScript;
      in
      if lib.isDerivation updateScript then
        # Single derivation (e.g. writeShellScript result)
        {
          isValid = true;
          errors = [ ];
        }
      else if scriptType == "set" then
        # Attribute set with command field (nixpkgs updateScript attrset format)
        validateAttrSet updateScript
      else if scriptType == "list" then
        validateList updateScript
      else if scriptType == "string" then
        # Store path string
        {
          isValid = true;
          errors = [ ];
        }
      else
        {
          isValid = false;
          errors = [ "${errorPrefix}: must be an attribute set, list, or derivation, got ${scriptType}" ];
        };

    # Parse updateScript into command list (handles attrset, list, or single derivation)
    parseUpdateScript =
      updateScript:
      if lib.isDerivation updateScript then
        [ updateScript ]
      else if lib.isAttrs updateScript && updateScript ? command then
        lib.toList updateScript.command
      else if lib.isList updateScript then
        updateScript
      else
        [ updateScript ];

    # Flatten an attrset of packages into a list of { path, value } records.
    # Nested attrsets (without a `type` attr) are recursed into with "." separators.
    # e.g. microsoft-office.word -> { path = "microsoft-office.word"; value = <drv>; }
    flattenPackages =
      prefix: attrs:
      lib.concatMap (
        name:
        let
          value = attrs.${name};
          path = if prefix == "" then name else "${prefix}.${name}";
        in
        if lib.isDerivation value then
          [ { inherit path value; } ]
        else if lib.isAttrs value && !(value ? type) then
          self.flattenPackages path value
        else
          [ ]
      ) (lib.attrNames attrs);

    # Resolve a "."-separated path string to the actual attribute in allPackages.
    resolvePkg =
      allPackages: path:
      let
        parts = lib.splitString "." path;
      in
      lib.getAttrFromPath parts allPackages;

    # Return the list of valid updatable package path strings (e.g. ["claude" "microsoft-office/word"]).
    getUpdatablePackages =
      allPackages:
      let
        inherit (self) flattenPackages resolvePkg validateUpdateScript;
        flatPkgs = flattenPackages "" allPackages;
        flatPkgPaths = map (x: x.path) flatPkgs;
        pkgsWithUpdateScript = lib.filter (
          p: (resolvePkg allPackages p) ? passthru.updateScript
        ) flatPkgPaths;
        validationResults = builtins.listToAttrs (
          map (pkg: {
            name = pkg;
            value = validateUpdateScript pkg (resolvePkg allPackages pkg).passthru.updateScript;
          }) pkgsWithUpdateScript
        );
      in
      lib.filter (pkg: validationResults.${pkg}.isValid) pkgsWithUpdateScript;
  };
in
self
