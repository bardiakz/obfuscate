import 'dart:convert';
import 'dart:typed_data';

import '../exceptions.dart';
import '../obfuscation_method.dart';

/// XOR "cipher" with a single-byte key. NOT cryptographically secure
/// — trivially reversible by brute-forcing 256 key values, provided
/// for obfuscation only, never for confidentiality.
///
/// IMPORTANT — wire format change from the original implementation:
/// this version XORs UTF-8 *bytes* and represents the result as
/// base64, not raw UTF-16 code units turned directly into a String.
/// The original approach could produce invalid lone-surrogate
/// sequences for some key/input combinations, which then failed or
/// corrupted when written as UTF-8 (e.g. via `File.writeAsStringSync`
/// or `print`). If you have existing data encoded with the old XOR
/// logic, keep decoding it with `LegacyMapCodec`-style logic (or your
/// own frozen copy of the old XOR function) — do not point old data
/// at this class.
class XorCodec implements ObfuscationMethod {
  final int key;

  XorCodec(this.key) {
    if (key < 0 || key > 255) {
      throw ObfuscationException(
        'XOR key must be a single byte (0-255), got $key. If you need '
        'a longer key, XOR each byte against a repeating key sequence '
        'in your own wrapper before/after this codec\'s base64 layer.',
      );
    }
  }

  @override
  String obfuscate(String input) {
    final bytes = utf8.encode(input);
    final result = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      result[i] = bytes[i] ^ key;
    }
    return base64.encode(result);
  }

  @override
  String deobfuscate(String input) {
    Uint8List bytes;
    try {
      bytes = base64.decode(input);
    } catch (e) {
      throw DecodingException('Invalid base64 input: $e');
    }
    final result = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      result[i] = bytes[i] ^ key;
    }
    try {
      return utf8.decode(result);
    } catch (e) {
      throw DecodingException(
        'Decoded bytes are not valid UTF-8 — wrong key, or data was not '
        'encoded with XorCodec: $e',
      );
    }
  }
}
