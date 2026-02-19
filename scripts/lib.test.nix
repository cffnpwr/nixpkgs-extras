{ lib }:
let
  scriptsLib = import ./lib.nix { inherit lib; };
  inherit (scriptsLib)
    validateUpdateScript
    parseUpdateScript
    flattenPackages
    resolvePkg
    getUpdatablePackages
    ;

  # Mock derivation (as a string to simulate evaluated derivation)
  mockDrv = "/nix/store/xxx-update-script";

  # Minimal mock derivation attrset (lib.isDerivation checks for type = "derivation")
  mkMockDrv =
    name:
    {
      type = "derivation";
      inherit name;
    }
    // lib.optionalAttrs true {
      pname = name;
      version = "1.0";
    };

  # Mock packages for flattenPackages / resolvePkg / getUpdatablePackages tests
  mockPackages = {
    simple = (mkMockDrv "simple") // {
      passthru.updateScript = mockDrv;
    };
    no-update = mkMockDrv "no-update";
    nested = {
      child = (mkMockDrv "child") // {
        passthru.updateScript = mockDrv;
      };
    };
  };
in
{
  # validateUpdateScript tests
  validateUpdateScript = {
    # Valid cases - attribute set
    "accepts valid attribute set with string command" = {
      expr = validateUpdateScript "test-pkg" { command = "update.sh"; };
      expected = {
        isValid = true;
        errors = [ ];
      };
    };

    "accepts valid attribute set with list command" = {
      expr = validateUpdateScript "test-pkg" {
        command = [
          "update.sh"
          "--arg"
          "value"
        ];
      };
      expected = {
        isValid = true;
        errors = [ ];
      };
    };

    "accepts attribute set with optional attrPath" = {
      expr = validateUpdateScript "test-pkg" {
        command = "update.sh";
        attrPath = "some.path";
      };
      expected = {
        isValid = true;
        errors = [ ];
      };
    };

    "accepts attribute set with optional supportedFeatures" = {
      expr = validateUpdateScript "test-pkg" {
        command = "update.sh";
        supportedFeatures = [
          "commit"
          "attrPath"
        ];
      };
      expected = {
        isValid = true;
        errors = [ ];
      };
    };

    # Valid cases - list
    "accepts non-empty list" = {
      expr = validateUpdateScript "test-pkg" [
        "update.sh"
        "--flag"
      ];
      expected = {
        isValid = true;
        errors = [ ];
      };
    };

    # Valid cases - derivation
    "accepts string (evaluated derivation)" = {
      expr = validateUpdateScript "test-pkg" mockDrv;
      expected = {
        isValid = true;
        errors = [ ];
      };
    };

    "accepts lambda (unevaluated derivation)" = {
      expr = validateUpdateScript "test-pkg" (x: x);
      expected = {
        isValid = true;
        errors = [ ];
      };
    };

    # Invalid cases - attribute set
    "rejects attribute set without command" = {
      expr = validateUpdateScript "test-pkg" { attrPath = "foo"; };
      expected = {
        isValid = false;
        errors = [
          "Package 'test-pkg': passthru.updateScript: attribute set must contain 'command' field"
        ];
      };
    };

    "rejects attribute set with invalid command type" = {
      expr = validateUpdateScript "test-pkg" { command = 123; };
      expected = {
        isValid = false;
        errors = [
          "Package 'test-pkg': passthru.updateScript: 'command' must be a string or list, got int"
        ];
      };
    };

    "rejects attribute set with invalid attrPath type" = {
      expr = validateUpdateScript "test-pkg" {
        command = "update.sh";
        attrPath = 123;
      };
      expected = {
        isValid = false;
        errors = [ "Package 'test-pkg': passthru.updateScript: 'attrPath' must be a string, got int" ];
      };
    };

    "rejects attribute set with invalid supportedFeatures type" = {
      expr = validateUpdateScript "test-pkg" {
        command = "update.sh";
        supportedFeatures = "not-a-list";
      };
      expected = {
        isValid = false;
        errors = [
          "Package 'test-pkg': passthru.updateScript: 'supportedFeatures' must be a list, got string"
        ];
      };
    };

    # Invalid cases - list
    "rejects empty list" = {
      expr = validateUpdateScript "test-pkg" [ ];
      expected = {
        isValid = false;
        errors = [ "Package 'test-pkg': passthru.updateScript: list must not be empty" ];
      };
    };

    # Invalid cases - wrong type
    "rejects invalid type (int)" = {
      expr = validateUpdateScript "test-pkg" 123;
      expected = {
        isValid = false;
        errors = [
          "Package 'test-pkg': passthru.updateScript: must be an attribute set, list, or derivation, got int"
        ];
      };
    };

    "rejects invalid type (null)" = {
      expr = validateUpdateScript "test-pkg" null;
      expected = {
        isValid = false;
        errors = [
          "Package 'test-pkg': passthru.updateScript: must be an attribute set, list, or derivation, got null"
        ];
      };
    };
  };

  # parseUpdateScript tests
  parseUpdateScript = {
    "parses attribute set with string command to list" = {
      expr = parseUpdateScript { command = "update.sh"; };
      expected = [ "update.sh" ];
    };

    "parses attribute set with list command" = {
      expr = parseUpdateScript {
        command = [
          "update.sh"
          "--arg"
        ];
      };
      expected = [
        "update.sh"
        "--arg"
      ];
    };

    "parses list directly" = {
      expr = parseUpdateScript [
        "update.sh"
        "--flag"
      ];
      expected = [
        "update.sh"
        "--flag"
      ];
    };

    "parses single derivation to list" = {
      expr = parseUpdateScript mockDrv;
      expected = [ mockDrv ];
    };

    "parses lambda (unevaluated derivation) to list" = {
      expr = builtins.isList (parseUpdateScript (x: x));
      expected = true;
    };
  };

  # flattenPackages tests
  flattenPackages = {
    "flattens top-level derivations" = {
      expr = map (x: x.path) (flattenPackages "" mockPackages);
      expected = [
        "nested/child"
        "no-update"
        "simple"
      ];
    };

    "flattens nested derivations with slash separator" = {
      expr =
        (builtins.head (lib.filter (x: x.path == "nested/child") (flattenPackages "" mockPackages))).path;
      expected = "nested/child";
    };

    "skips non-derivation non-attrset values" = {
      expr = map (x: x.path) (
        flattenPackages "" {
          num = 42;
          drv = mkMockDrv "drv";
        }
      );
      expected = [ "drv" ];
    };
  };

  # resolvePkg tests
  resolvePkg = {
    "resolves top-level package" = {
      expr = (resolvePkg mockPackages "simple").name;
      expected = "simple";
    };

    "resolves nested package with slash path" = {
      expr = (resolvePkg mockPackages "nested/child").name;
      expected = "child";
    };
  };

  # getUpdatablePackages tests
  getUpdatablePackages = {
    "returns only packages with valid updateScript" = {
      expr = builtins.sort builtins.lessThan (getUpdatablePackages mockPackages);
      expected = [
        "nested/child"
        "simple"
      ];
    };

    "excludes packages without updateScript" = {
      expr = builtins.elem "no-update" (getUpdatablePackages mockPackages);
      expected = false;
    };
  };
}
