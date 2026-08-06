import 'exceptions.dart';
import 'map_validator.dart';
import 'obfuscation_method.dart';

/// Maps a single character to another single character.
/// output length (in Unicode code points) always equals input length, and decode walks the string back one code point at a time.
/// Iteration is by Unicode code point (`.runes`), not UTF-16 code
/// unit, so this is safe for characters outside the Basic Multilingual
/// Plane (e.g. emoji). It does NOT merge grapheme clusters — a base
/// character followed by a combining mark is treated as two separate
/// units. That matches how [map] is expected to be authored (one
/// entry per code point) but means a source string containing
/// combining sequences with no map entry for the mark itself will
/// simply pass the mark through unchanged (see [strict] below). For
/// full grapheme-cluster correctness, consider layering the
/// `characters` package's `Characters` class on top of this class in
/// your own iteration if you need it.
///
/// By default, characters with no entry in [map] pass through
/// unchanged in both directions. Set [strict] to true to throw
/// [UnmappedCharacterException] instead — useful when you want to
/// guarantee every character in a message was actually obfuscated.
class SubstitutionCodec implements ObfuscationMethod {
  final Map<String, String> map;
  final bool strict;
  final List<String> warnings;
  final Map<String, String> _reverseMap;

  factory SubstitutionCodec(Map<String, String> map, {bool strict = false}) {
    final result = validateMap(map, kind: MapKind.substitution);
    if (!result.isValid) {
      throw InvalidMapException(
        'Cannot build SubstitutionCodec:\n${result.errors.join('\n')}',
      );
    }
    final reverseMap = {for (final e in map.entries) e.value: e.key};
    return SubstitutionCodec._(map, strict, result.warnings, reverseMap);
  }

  SubstitutionCodec._(this.map, this.strict, this.warnings, this._reverseMap);

  @override
  String obfuscate(String input) => _transform(input, map);

  @override
  String deobfuscate(String input) => _transform(input, _reverseMap);

  String _transform(String input, Map<String, String> activeMap) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final mapped = activeMap[char];
      if (mapped != null) {
        buffer.write(mapped);
      } else if (strict) {
        throw UnmappedCharacterException(char);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
