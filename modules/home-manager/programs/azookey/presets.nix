# azooKey input table presets
# Based on https://github.com/azooKey/AzooKeyKanaKanjiConverter/tree/main/Sources/KanaKanjiConverterModule/InputManagement/InputTables
{
  lib,
  ...
}:
let
  azikPath = ./presets/azik.json;
  kanaJISPath = ./presets/kana-jis.json;
  kanaUSPath = ./presets/kana-us.json;
  roman2kanaPath = ./presets/roman2kana.json;

  # Load presets from JSON file
  loadPresets =
    path:
    let
      loaded = builtins.fromJSON (builtins.readFile path);
    in
    builtins.map (item: {
      input = item.name;
      output = item.value;
    }) (lib.attrsToList loaded);
in
{
  # AZIK preset
  presetAzik = loadPresets azikPath;

  # Kana JIS preset
  presetKanaJIS = loadPresets kanaJISPath;

  # Kana US preset
  presetKanaUS = loadPresets kanaUSPath;

  # Default romaji input preset
  presetRomanToKana = loadPresets roman2kanaPath;
}
