import 'dart:convert';
import 'dart:typed_data';

import 'exceptions.dart';
import 'obfuscation_method.dart';

/// Wraps an [ObfuscationMethod] so it can be safely applied to
/// arbitrary binary data instead of just human-typed text.
///
/// Bytes are hex-encoded (2 hex characters per byte, e.g. 0xA3 ->
/// "a3"), passed through [inner], then UTF-8 encoded back to bytes.
/// This is the byte-safe replacement for the previous pattern of
/// manually hex-encoding compressed/encrypted data before running it
/// through a character map — the same ~15 lines that used to be
/// hand-copied at every call site now collapse to one call:
///
/// ```dart
/// final codec = NibbleCodec(SubstitutionCodec(fa1Map));
/// final obfuscatedBytes = codec.obfuscate(compressedBytes);
/// // ... send/store obfuscatedBytes (or utf8.decode it to a String) ...
/// final recoveredBytes = codec.deobfuscate(obfuscatedBytes);
/// ```
///
/// If [inner] is built from a map, that map only needs entries for
/// the 16 hex digit characters `0123456789abcdef`. Use
/// `validateMap(..., requiredDomain: NibbleCodec.hexAlphabet)` to
/// confirm a map covers them all before building a codec meant for
/// use here.
class NibbleCodec {
  final ObfuscationMethod inner;
  const NibbleCodec(this.inner);

  /// The 16 characters a map needs to cover to be usable with
  /// [NibbleCodec]. Pass this as `requiredDomain` to [validateMap].
  static const List<String> hexAlphabet = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
  ];

  Uint8List obfuscate(Uint8List bytes) {
    final hex = _bytesToHex(bytes);
    final obfuscatedHex = inner.obfuscate(hex);
    return Uint8List.fromList(utf8.encode(obfuscatedHex));
  }

  Uint8List deobfuscate(Uint8List bytes) {
    String obfuscatedHex;
    try {
      obfuscatedHex = utf8.decode(bytes);
    } catch (e) {
      throw DecodingException('Input is not valid UTF-8: $e');
    }

    final hex = inner.deobfuscate(obfuscatedHex);

    if (hex.length % 2 != 0) {
      throw DecodingException(
        'Decoded hex string has odd length (${hex.length}); data is '
        'corrupt, or was encoded with a different map/codec/delimiter.',
      );
    }

    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      final byteStr = hex.substring(i, i + 2);
      final byte = int.tryParse(byteStr, radix: 16);
      if (byte == null) {
        throw DecodingException('Invalid hex byte "$byteStr" at offset $i');
      }
      result[i ~/ 2] = byte;
    }
    return result;
  }

  static String _bytesToHex(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
