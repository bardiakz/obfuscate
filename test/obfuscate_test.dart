import 'package:test/test.dart';
import 'package:obfuscate/obfuscate.dart';

void main() {
  group('Obfuscate Tests', () {
    test('Base64 obfuscation/deobfuscation', () {
      const input = 'Hello World!';
      final obfuscated = Obfuscate.obfuscateBase64(input);
      final deobfuscated = Obfuscate.deobfuscateBase64(obfuscated);

      expect(deobfuscated, equals(input));
      expect(obfuscated, isNot(equals(input)));
    });

    test('ROT13 obfuscation/deobfuscation', () {
      const input = 'Hello World!';
      final obfuscated = Obfuscate.obfuscateROT13(input);
      final deobfuscated = Obfuscate.deobfuscateROT13(obfuscated);

      expect(deobfuscated, equals(input));
      expect(obfuscated, equals('Uryyb Jbeyq!'));
    });

    test('XOR obfuscation/deobfuscation', () {
      const input = 'Hello World!';
      const key = 123;
      final obfuscated = Obfuscate.obfuscateXOR(input, key);
      final deobfuscated = Obfuscate.deobfuscateXOR(obfuscated, key);

      expect(deobfuscated, equals(input));
      expect(obfuscated, isNot(equals(input)));
    });

    test('Reverse obfuscation/deobfuscation', () {
      const input = 'Hello World!';
      final obfuscated = Obfuscate.obfuscateReverse(input);
      final deobfuscated = Obfuscate.deobfuscateReverse(obfuscated);

      expect(deobfuscated, equals(input));
      expect(obfuscated, equals('!dlroW olleH'));
    });

    test('Custom map obfuscation/deobfuscation', () {
      const input = 'Hello';
      final map = {'h': 'x', 'e': 'y', 'l': 'z', 'o': 'w'};
      final obfuscated = Obfuscate.obfuscateWithMap(input, map);
      final deobfuscated = Obfuscate.deobfuscateWithMap(obfuscated, map);

      expect(deobfuscated, equals(input.toLowerCase()));
      expect(obfuscated, contains('x')); // 'h' should be replaced with 'x'
    });
  });
}
