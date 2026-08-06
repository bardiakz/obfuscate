import 'dart:convert';

import '../exceptions.dart';
import '../obfuscation_method.dart';

/// Standard Base64 encoding, wrapped as an [ObfuscationMethod]. Not
/// obfuscation in any meaningful security sense (no key, trivially
/// reversible by anyone) — provided for its original purpose of
/// producing safe-to-transmit ASCII text.
class Base64ObfuscationCodec implements ObfuscationMethod {
  const Base64ObfuscationCodec();

  @override
  String obfuscate(String input) => base64.encode(utf8.encode(input));

  @override
  String deobfuscate(String input) {
    try {
      return utf8.decode(base64.decode(input));
    } catch (e) {
      throw DecodingException('Invalid base64 or UTF-8 data: $e');
    }
  }
}
