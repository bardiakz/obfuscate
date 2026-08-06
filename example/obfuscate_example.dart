import 'package:obfuscate/obfuscate.dart';

void main() {
  const text = 'Hello, World!';
  print('Original: $text');

  // Base64
  const base64Codec = Base64ObfuscationCodec();
  final base64Obfuscated = base64Codec.obfuscate(text);
  print('Base64: $base64Obfuscated');
  print('Base64 Decoded: ${base64Codec.deobfuscate(base64Obfuscated)}');

  // ROT13
  const rot13Codec = Rot13Codec();
  final rot13Obfuscated = rot13Codec.obfuscate(text);
  print('ROT13: $rot13Obfuscated');
  print('ROT13 Decoded: ${rot13Codec.deobfuscate(rot13Obfuscated)}');

  // XOR (byte-safe: output is base64, key must be 0-255)
  final xorCodec = XorCodec(123);
  final xorObfuscated = xorCodec.obfuscate(text);
  print('XOR: $xorObfuscated');
  print('XOR Decoded: ${xorCodec.deobfuscate(xorObfuscated)}');

  // Reverse
  const reverseCodec = ReverseCodec();
  final reverseObfuscated = reverseCodec.obfuscate(text);
  print('Reverse: $reverseObfuscated');
  print('Reverse Decoded: ${reverseCodec.deobfuscate(reverseObfuscated)}');

  // Custom 1-char -> 1-char mapping (validated at construction time —
  // throws InvalidMapException immediately if the map isn't bijective)
  final customMap = {
    'h': 'x',
    'e': 'y',
    'l': 'z',
    'o': 'w',
    'r': 'a',
    'd': 'b',
  };
  final customCodec = SubstitutionCodec(customMap);
  final customObfuscated = customCodec.obfuscate(text);
  print('Custom Map: $customObfuscated');
  print('Custom Map Decoded: ${customCodec.deobfuscate(customObfuscated)}');

  // Custom 1-char -> word mapping (needs a delimiter, unmapped chars throw)
  final wordMap = {'h': 'house', 'e': 'energy', 'l': 'library', 'o': 'office'};
  final tokenCodec = TokenSubstitutionCodec(wordMap);
  final tokenObfuscated = tokenCodec.obfuscate('hello');
  print('Token Map: $tokenObfuscated');
  print('Token Map Decoded: ${tokenCodec.deobfuscate(tokenObfuscated)}');
}
