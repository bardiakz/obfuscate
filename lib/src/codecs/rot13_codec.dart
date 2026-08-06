import '../obfuscation_method.dart';

/// Classic ROT13 substitution on ASCII letters A-Z/a-z. Self-inverse
/// (obfuscate and deobfuscate are the same operation). Non-alphabetic
/// characters, including all Persian/Arabic characters, pass through
/// unchanged — this is expected behavior, not a bug: a ROT13 pass on
/// Persian/Arabic text is a no-op.
class Rot13Codec implements ObfuscationMethod {
  const Rot13Codec();

  @override
  String obfuscate(String input) => _rotate(input);

  @override
  String deobfuscate(String input) => _rotate(input);

  static String _rotate(String text) {
    final buffer = StringBuffer();
    for (final unit in text.codeUnits) {
      if (unit >= 65 && unit <= 90) {
        buffer.writeCharCode(((unit - 65 + 13) % 26) + 65);
      } else if (unit >= 97 && unit <= 122) {
        buffer.writeCharCode(((unit - 97 + 13) % 26) + 97);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }
}
