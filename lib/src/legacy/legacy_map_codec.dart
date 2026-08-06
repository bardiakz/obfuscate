// ignore_for_file: avoid_print

/// FROZEN legacy implementation — DO NOT MODIFY THIS FILE.
///
/// This is a byte-for-byte copy of the original
/// `Obfuscate.obfuscateWithMap` / `deobfuscateWithMap` logic from
/// obfuscate 0.0.1, including its known quirks (inserting a delimiter
/// space between every output unit, and silently keeping only one
/// side of a duplicate-value collision in the reverse map). It exists
/// solely so that data obfuscated by earlier versions of this
/// library — or by qrypt's InputHandler using the old API — can still
/// be decoded correctly.
///
/// Do NOT use this for new code, and do NOT "fix" the quirks below:
/// doing so would silently break decoding of already-obfuscated data
/// that real users may still be holding onto (old QR codes, saved
/// messages, etc). New code should use [SubstitutionCodec] or
/// [TokenSubstitutionCodec] instead.

class LegacyMapCodec {
  static String obfuscate(
    String text,
    Map<String, String> obfuscationMap, {
    bool preserveUnmapped = false,
    bool preserveCase = false,
  }) {
    final contentToObfuscate = text;

    // Check if we're dealing with base64-like content
    bool isBase64Like = RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(text);

    StringBuffer sb = StringBuffer();
    bool first = true;

    if (preserveUnmapped) {
      for (var char in contentToObfuscate.split('')) {
        var key = char.toLowerCase();
        var mapped = obfuscationMap[key];
        if (mapped != null) {
          if (!first) sb.write(' ');
          if (preserveCase && char != key) {
            sb.write(mapped.toUpperCase());
          } else {
            sb.write(mapped);
          }
          first = false;
        } else {
          var preservedChar = char == ' ' ? '__SPACE__' : char;
          sb.write(preservedChar);
          first = true; // Allow space before next mapped
        }
      }
      return sb.toString();
    } else {
      if (isBase64Like) {
        for (var char in contentToObfuscate.split('')) {
          var key = char.toLowerCase();
          var mapped = obfuscationMap[key] ?? char;
          if (!first) sb.write(' ');
          if (preserveCase && char != key && mapped != char) {
            sb.write(mapped.toUpperCase());
          } else {
            sb.write(mapped);
          }
          first = false;
        }
      } else {
        for (var char in contentToObfuscate.split('')) {
          var key = char.toLowerCase();
          var mapped = obfuscationMap[key] ?? char;
          if (!first) sb.write(' ');
          if (preserveCase && char != key && mapped != char) {
            sb.write(mapped.toUpperCase());
          } else {
            sb.write(mapped);
          }
          first = false;
        }
      }
      return sb.toString();
    }
  }

  static String deobfuscate(String text, Map<String, String> obfuscationMap) {
    // Create reverse mapping with lowered keys for case-insensitivity
    Map<String, String> reverseMap = {};
    obfuscationMap.forEach((key, value) {
      var lowerValue = value.toLowerCase();
      if (reverseMap.containsKey(lowerValue)) {
        print(
          'Warning: Duplicate lowered substitution for $value; deobfuscation may be incomplete.',
        );
      }
      reverseMap[lowerValue] = key;
    });

    // Split by spaces and deobfuscate each word
    final deobfuscatedContent = text
        .split(' ')
        .where((word) => word.isNotEmpty) // Filter out empty strings
        .map((word) {
          if (word == '__SPACE__') return ' ';
          var lowerWord = word.toLowerCase();
          var original = reverseMap[lowerWord] ?? word;
          return word == word.toUpperCase() ? original.toUpperCase() : original;
        })
        .join(''); // Join without spaces
    return deobfuscatedContent;
  }
}
