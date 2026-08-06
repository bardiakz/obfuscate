import 'exceptions.dart';
import 'map_validator.dart';
import 'obfuscation_method.dart';

/// Maps a single character to a token — a word or any multi-character
/// string — joined with [delimiter] on encode and split by it on
/// decode.
///
/// Unlike [SubstitutionCodec], every character that appears in input
/// MUST have an entry in [map] — there is no safe passthrough for
/// unmapped characters here, because a raw unmapped character sitting
/// next to word-length tokens after a `split(delimiter)` is
/// indistinguishable from a token and would corrupt decoding. Encode
/// throws [UnmappedCharacterException] immediately instead.
///
/// [map]'s values must not contain [delimiter] — this is enforced at
/// construction time via [validateMap] and will throw
/// [InvalidMapException] if violated.
///
/// Output is significantly larger than input: each input character
/// becomes an entire token plus a delimiter. Use
/// [estimateOutputLength] if you need to reason about size ahead of
/// time (e.g. before generating a QR code).
class TokenSubstitutionCodec implements ObfuscationMethod {
  final Map<String, String> map;
  final String delimiter;
  final List<String> warnings;
  final Map<String, String> _reverseMap;

  factory TokenSubstitutionCodec(
    Map<String, String> map, {
    String delimiter = ' ',
  }) {
    final result = validateMap(map, kind: MapKind.token, delimiter: delimiter);
    if (!result.isValid) {
      throw InvalidMapException(
        'Cannot build TokenSubstitutionCodec:\n${result.errors.join('\n')}',
      );
    }
    final reverseMap = {for (final e in map.entries) e.value: e.key};
    return TokenSubstitutionCodec._(
      map,
      delimiter,
      result.warnings,
      reverseMap,
    );
  }

  TokenSubstitutionCodec._(
    this.map,
    this.delimiter,
    this.warnings,
    this._reverseMap,
  );

  @override
  String obfuscate(String input) {
    final tokens = <String>[];
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final token = map[char];
      if (token == null) {
        throw UnmappedCharacterException(char);
      }
      tokens.add(token);
    }
    return tokens.join(delimiter);
  }

  @override
  String deobfuscate(String input) {
    if (input.isEmpty) return '';
    final parts = input.split(delimiter);
    final buffer = StringBuffer();
    for (final part in parts) {
      final original = _reverseMap[part];
      if (original == null) {
        throw DecodingException(
          'Unknown token "$part" — data may be corrupt, or was encoded '
          'with a different map or delimiter.',
        );
      }
      buffer.write(original);
    }
    return buffer.toString();
  }

  /// Rough output length estimate in characters, given [inputCodePoints]
  /// input characters and the average token length in [map]. Useful
  /// for warning users ahead of time about size blowup (e.g. before
  /// encoding into a QR code).
  int estimateOutputLength(int inputCodePoints) {
    if (map.isEmpty) return 0;
    final avgTokenLength =
        map.values.map((v) => v.length).reduce((a, b) => a + b) / map.length;
    final avgDelimiterLength = delimiter.length;
    return (inputCodePoints * (avgTokenLength + avgDelimiterLength)).round();
  }
}
