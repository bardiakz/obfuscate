import 'dart:convert';

import 'legacy_map_codec.dart';

/// DEPRECATED compatibility shim replicating the exact old static API
/// (obfuscate 0.0.1) so existing call sites keep compiling AND keep
/// producing byte-identical output — not just "compiles," but
/// "behaves exactly the same," including old quirks:
/// - [obfuscateXOR]/[deobfuscateXOR] operate on raw UTF-16 code units,
///   not bytes — this can produce invalid surrogate sequences for
///   some key/input combinations. [XorCodec] fixes this but uses a
///   different (base64-wrapped) wire format, so it is NOT a drop-in
///   replacement for data already encoded with this method.
/// - [deobfuscateBase64] silently returns the input unchanged on a
///   decode failure instead of throwing. [Base64ObfuscationCodec]
///   throws [DecodingException] instead.
/// - [obfuscateWithMap]/[deobfuscateWithMap] delegate to
///   [LegacyMapCodec], which has its own documented quirks (space
///   insertion, silent duplicate-value handling).
///
/// New code should NOT use this class — use the codec classes
/// instead: [Base64ObfuscationCodec], [Rot13Codec], [XorCodec],
/// [ReverseCodec], [SubstitutionCodec], [TokenSubstitutionCodec].
@Deprecated(
  'Use the codec classes instead (SubstitutionCodec, '
  'Base64ObfuscationCodec, Rot13Codec, XorCodec, ReverseCodec, '
  'TokenSubstitutionCodec). This class exists only so old call sites '
  'keep compiling with unchanged behavior; it will be removed in a '
  'future major version.',
)
class Obfuscate {
  Obfuscate._();

  // ---- Base64 ----

  @Deprecated('Use Base64ObfuscationCodec instead.')
  static String obfuscateBase64(String text) {
    final bytes = utf8.encode(text);
    return base64.encode(bytes);
  }

  @Deprecated(
    'Use Base64ObfuscationCodec instead. Note: unlike '
    'Base64ObfuscationCodec, this method silently returns the input '
    'unchanged on decode failure instead of throwing.',
  )
  static String deobfuscateBase64(String encodedText) {
    try {
      final bytes = base64.decode(encodedText);
      return utf8.decode(bytes);
    } catch (e) {
      return encodedText; // matches old silent-fallback behavior
    }
  }

  // ---- ROT13 ----

  @Deprecated('Use Rot13Codec instead.')
  static String obfuscateROT13(String text) {
    return text
        .split('')
        .map((char) {
          final unit = char.codeUnitAt(0);
          if (unit >= 65 && unit <= 90) {
            return String.fromCharCode(((unit - 65 + 13) % 26) + 65);
          } else if (unit >= 97 && unit <= 122) {
            return String.fromCharCode(((unit - 97 + 13) % 26) + 97);
          }
          return char;
        })
        .join('');
  }

  @Deprecated('Use Rot13Codec instead.')
  static String deobfuscateROT13(String text) => obfuscateROT13(text);

  // ---- XOR ----

  @Deprecated(
    'Use XorCodec instead for new data. WARNING: XorCodec uses a '
    'different, byte-safe wire format — it will NOT correctly decode '
    'data produced by this method. Keep using this method to decode '
    'old XOR-obfuscated data; use XorCodec only for newly-encoded data.',
  )
  static String obfuscateXOR(String text, int key) {
    return text
        .split('')
        .map((char) => String.fromCharCode(char.codeUnitAt(0) ^ key))
        .join('');
  }

  @Deprecated(
    'Use XorCodec instead for new data. This method decodes the old '
    'raw-code-unit XOR format only — see obfuscateXOR for details.',
  )
  static String deobfuscateXOR(String text, int key) => obfuscateXOR(text, key);

  // ---- Reverse ----

  @Deprecated('Use ReverseCodec instead.')
  static String obfuscateReverse(String text) =>
      text.split('').reversed.join('');

  @Deprecated('Use ReverseCodec instead.')
  static String deobfuscateReverse(String text) => obfuscateReverse(text);

  // ---- Map-based (delegates to the frozen LegacyMapCodec) ----

  @Deprecated('Use SubstitutionCodec or TokenSubstitutionCodec instead.')
  static String obfuscateWithMap(
    String text,
    Map<String, String> obfuscationMap, {
    bool preserveUnmapped = false,
    bool preserveCase = false,
  }) {
    return LegacyMapCodec.obfuscate(
      text,
      obfuscationMap,
      preserveUnmapped: preserveUnmapped,
      preserveCase: preserveCase,
    );
  }

  @Deprecated('Use SubstitutionCodec or TokenSubstitutionCodec instead.')
  static String deobfuscateWithMap(
    String text,
    Map<String, String> obfuscationMap,
  ) {
    return LegacyMapCodec.deobfuscate(text, obfuscationMap);
  }
}
