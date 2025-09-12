import 'dart:convert';

class Obfuscate {
  static String obfuscateWithMap(
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

  static String deobfuscateWithMap(
    String text,
    Map<String, String> obfuscationMap,
  ) {
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

  // Base64 obfuscation
  static String obfuscateBase64(String text) {
    final bytes = utf8.encode(text);
    return base64.encode(bytes);
  }

  static String deobfuscateBase64(String encodedText) {
    try {
      final bytes = base64.decode(encodedText);
      return utf8.decode(bytes);
    } catch (e) {
      return encodedText; // Return original if decoding fails
    }
  }

  // ROT13 obfuscation
  static String obfuscateROT13(String text) {
    return text
        .split('')
        .map((char) {
          if (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) {
            // Uppercase A-Z
            return String.fromCharCode(
              ((char.codeUnitAt(0) - 65 + 13) % 26) + 65,
            );
          } else if (char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122) {
            // Lowercase a-z
            return String.fromCharCode(
              ((char.codeUnitAt(0) - 97 + 13) % 26) + 97,
            );
          }
          return char; // Non-alphabetic characters unchanged
        })
        .join('');
  }

  static String deobfuscateROT13(String text) {
    return obfuscateROT13(text);
  }

  //XOR obfuscation with key
  static String obfuscateXOR(String text, int key) {
    return text
        .split('')
        .map((char) {
          return String.fromCharCode(char.codeUnitAt(0) ^ key);
        })
        .join('');
  }

  static String deobfuscateXOR(String text, int key) {
    return obfuscateXOR(text, key);
  }

  // Reverse string obfuscation
  static String obfuscateReverse(String text) {
    return text.split('').reversed.join('');
  }

  static String deobfuscateReverse(String text) {
    return obfuscateReverse(text);
  }
}

void main(List<String> arguments) {}
