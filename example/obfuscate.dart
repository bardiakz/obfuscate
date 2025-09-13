import 'package:obfuscate/obfuscate.dart';

void main() {
  const text = 'Hello, World!';
  print('Original: $text');

  // Base64
  final base64Obfuscated = Obfuscate.obfuscateBase64(text);
  print('Base64: $base64Obfuscated');
  print('Base64 Decoded: ${Obfuscate.deobfuscateBase64(base64Obfuscated)}');

  // ROT13
  final rot13Obfuscated = Obfuscate.obfuscateROT13(text);
  print('ROT13: $rot13Obfuscated');
  print('ROT13 Decoded: ${Obfuscate.deobfuscateROT13(rot13Obfuscated)}');

  // XOR
  final xorObfuscated = Obfuscate.obfuscateXOR(text, 123);
  print('XOR: $xorObfuscated');
  print('XOR Decoded: ${Obfuscate.deobfuscateXOR(xorObfuscated, 123)}');

  // Reverse
  final reverseObfuscated = Obfuscate.obfuscateReverse(text);
  print('Reverse: $reverseObfuscated');
  print('Reverse Decoded: ${Obfuscate.deobfuscateReverse(reverseObfuscated)}');

  // Custom mapping
  final customMap = {
    'h': 'x',
    'e': 'y',
    'l': 'z',
    'o': 'w',
    'r': 'a',
    'd': 'b',
  };
  final customObfuscated = Obfuscate.obfuscateWithMap(text, customMap);
  print('Custom Map: $customObfuscated');
  print(
    'Custom Map Decoded: ${Obfuscate.deobfuscateWithMap(customObfuscated, customMap)}',
  );
}
