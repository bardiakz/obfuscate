import 'dart:convert';
import 'dart:typed_data';

import 'package:obfuscate/obfuscate.dart';
import 'package:test/test.dart';

const brokenFa1Sample = {
  'A': 'ه', 'B': 'و', 'Q': 'ز',
  '9': 'ز', // <- collides with 'Q' above
};

// Same sample with the collision fixed.
const fixedFa1Sample = {
  'A': 'ه', 'B': 'و', 'Q': 'ز',
  '9': 'ط', // distinct value
};

void main() {
  group('validateMap', () {
    test('flags the real FA1 collision (Q and 9 both -> ز)', () {
      final result = validateMap(brokenFa1Sample, kind: MapKind.substitution);
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.contains('Q') && e.contains('9')),
        isTrue,
        reason: 'Expected a collision error mentioning both Q and 9',
      );
    });

    test('passes once the collision is fixed', () {
      final result = validateMap(fixedFa1Sample, kind: MapKind.substitution);
      expect(result.isValid, isTrue);
    });

    test('warns on combining marks (e.g. FA1 lowercase block characters)', () {
      final result = validateMap(
        {'a': '\u06E1'}, // ARABIC SMALL HIGH DOTLESS HEAD OF KHAH - Mn
        kind: MapKind.substitution,
      );
      expect(result.isValid, isTrue); // warning, not error
      expect(result.warnings, isNotEmpty);
    });

    test('token map rejects values containing the delimiter', () {
      final result = validateMap(
        {'a': 'has space'},
        kind: MapKind.token,
        delimiter: ' ',
      );
      expect(result.isValid, isFalse);
    });

    test('requiredDomain catches missing hex digits', () {
      final result = validateMap(
        {'0': 'x', '1': 'y'}, // missing 2-f
        kind: MapKind.substitution,
        requiredDomain: NibbleCodec.hexAlphabet,
      );
      expect(result.isValid, isFalse);
      expect(result.errors.length, greaterThanOrEqualTo(14));
    });
  });

  group('SubstitutionCodec', () {
    test('constructor throws on a colliding map', () {
      expect(
        () => SubstitutionCodec(brokenFa1Sample),
        throwsA(isA<InvalidMapException>()),
      );
    });

    test('round-trips ASCII', () {
      final codec = SubstitutionCodec({'h': 'x', 'e': 'y', 'l': 'z', 'o': 'w'});
      final obfuscated = codec.obfuscate('hello');
      expect(obfuscated, 'xyzzw');
      expect(codec.deobfuscate(obfuscated), 'hello');
    });

    test('round-trips a Persian sentence with normal spaces', () {
      final codec = SubstitutionCodec(fixedFa1Sample);
      const input = 'A B Q'; // includes spaces, which have no map entry
      final obfuscated = codec.obfuscate(input);
      expect(codec.deobfuscate(obfuscated), input);
    });

    test('round-trips text containing ZWNJ (\\u200C)', () {
      final codec = SubstitutionCodec({'a': 'x', 'b': 'y'});
      const input = 'a\u200Cb'; // e.g. می‌روم-style pseudo-space
      final obfuscated = codec.obfuscate(input);
      expect(codec.deobfuscate(obfuscated), input);
    });

    test('strict mode throws on unmapped characters', () {
      final codec = SubstitutionCodec({'a': 'x'}, strict: true);
      expect(
        () => codec.obfuscate('ab'),
        throwsA(isA<UnmappedCharacterException>()),
      );
    });

    test('non-strict mode passes unmapped characters through', () {
      final codec = SubstitutionCodec({'a': 'x'});
      expect(codec.obfuscate('ab'), 'xb');
    });
  });

  group('TokenSubstitutionCodec', () {
    final fa2Sample = {
      '0': 'صفر',
      '1': 'یک',
      '2': 'دو',
      'a': 'سلام',
      'b': 'خوب',
    };

    test('round-trips', () {
      final codec = TokenSubstitutionCodec(fa2Sample);
      final obfuscated = codec.obfuscate('0a1');
      expect(codec.deobfuscate(obfuscated), '0a1');
    });

    test('throws on unmapped character (no safe passthrough)', () {
      final codec = TokenSubstitutionCodec(fa2Sample);
      expect(
        () => codec.obfuscate('0z1'), // 'z' not in map
        throwsA(isA<UnmappedCharacterException>()),
      );
    });

    test('constructor rejects a token containing the delimiter', () {
      expect(
        () => TokenSubstitutionCodec({'a': 'has space'}),
        throwsA(isA<InvalidMapException>()),
      );
    });

    test('estimateOutputLength is in the right ballpark', () {
      final codec = TokenSubstitutionCodec(fa2Sample, delimiter: ' ');
      final estimate = codec.estimateOutputLength(10);
      final actual = codec.obfuscate('0101010101').length;
      // rough sample map, so just check same order of magnitude
      expect((estimate - actual).abs(), lessThan(actual));
    });
  });

  group('NibbleCodec', () {
    test('round-trips arbitrary binary data through a substitution map', () {
      final hexMap = {
        for (var i = 0; i < 16; i++)
          NibbleCodec.hexAlphabet[i]: String.fromCharCode(0x0600 + i),
      };
      final codec = NibbleCodec(SubstitutionCodec(hexMap));
      final original = Uint8List.fromList([0, 1, 255, 128, 42]);
      final obfuscated = codec.obfuscate(original);
      final recovered = codec.deobfuscate(obfuscated);
      expect(recovered, original);
    });

    test('replicates the old hand-rolled hex-loop + map pattern used in '
        'qrypt InputHandler, for regression safety', () {
      // Old qrypt pattern: bytes -> hex string -> obfuscateWithMap
      final map = {
        for (var i = 0; i < 16; i++)
          NibbleCodec.hexAlphabet[i]: String.fromCharCode(0x0600 + i),
      };
      final original = Uint8List.fromList(utf8.encode('test payload'));

      // Old manual approach (mirrors InputHandler.dart)
      final hexBuffer = StringBuffer();
      for (final byte in original) {
        hexBuffer.write(byte.toRadixString(16).padLeft(2, '0'));
      }
      final oldStyleObfuscatedHex = SubstitutionCodec(
        map,
      ).obfuscate(hexBuffer.toString());

      // New approach
      final codec = NibbleCodec(SubstitutionCodec(map));
      final newStyleObfuscatedBytes = codec.obfuscate(original);
      final newStyleObfuscatedHex = utf8.decode(newStyleObfuscatedBytes);

      expect(newStyleObfuscatedHex, oldStyleObfuscatedHex);
    });

    test('throws DecodingException on odd-length hex after decode', () {
      final codec = NibbleCodec(const Rot13Codec());
      expect(
        () => codec.deobfuscate(Uint8List.fromList(utf8.encode('abc'))),
        throwsA(isA<DecodingException>()),
      );
    });
  });

  group('Base64ObfuscationCodec', () {
    test('round-trips', () {
      const codec = Base64ObfuscationCodec();
      const input = 'Hello, دنیا!';
      expect(codec.deobfuscate(codec.obfuscate(input)), input);
    });

    test('throws DecodingException on invalid input', () {
      const codec = Base64ObfuscationCodec();
      expect(
        () => codec.deobfuscate('not valid base64!!'),
        throwsA(isA<DecodingException>()),
      );
    });
  });

  group('Rot13Codec', () {
    test('round-trips and matches known vector', () {
      const codec = Rot13Codec();
      const input = 'Hello World!';
      final obfuscated = codec.obfuscate(input);
      expect(obfuscated, 'Uryyb Jbeyq!');
      expect(codec.deobfuscate(obfuscated), input);
    });

    test('leaves Persian text unchanged (documented no-op behavior)', () {
      const codec = Rot13Codec();
      const input = 'سلام دنیا';
      expect(codec.obfuscate(input), input);
    });
  });

  group('XorCodec', () {
    test('round-trips ASCII', () {
      final codec = XorCodec(123);
      const input = 'Hello World!';
      final obfuscated = codec.obfuscate(input);
      expect(obfuscated, isNot(equals(input)));
      expect(codec.deobfuscate(obfuscated), input);
    });

    test('round-trips Persian text safely (no UTF-8 corruption)', () {
      final codec = XorCodec(250); // a key that would previously risk
      // producing invalid surrogate sequences under the old code-unit
      // XOR approach
      const input = 'سلام دنیا، این یک آزمایش است!';
      final obfuscated = codec.obfuscate(input);
      expect(codec.deobfuscate(obfuscated), input);
    });

    test('rejects out-of-range keys', () {
      expect(() => XorCodec(300), throwsA(isA<ObfuscationException>()));
      expect(() => XorCodec(-1), throwsA(isA<ObfuscationException>()));
    });
  });

  group('ReverseCodec', () {
    test('round-trips and matches known vector', () {
      const codec = ReverseCodec();
      const input = 'Hello World!';
      final obfuscated = codec.obfuscate(input);
      expect(obfuscated, '!dlroW olleH');
      expect(codec.deobfuscate(obfuscated), input);
    });

    test('round-trips emoji correctly (outside BMP)', () {
      const codec = ReverseCodec();
      const input = 'ab😀cd';
      expect(codec.deobfuscate(codec.obfuscate(input)), input);
    });
  });

  group('Obfuscate (deprecated compat shim)', () {
    test('base64 matches old behavior, including silent-fallback decode', () {
      // ignore: deprecated_member_use
      final obfuscated = Obfuscate.obfuscateBase64('Hello, دنیا!');
      // ignore: deprecated_member_use
      expect(Obfuscate.deobfuscateBase64(obfuscated), 'Hello, دنیا!');
      // old behavior: bad input returns unchanged, never throws
      // ignore: deprecated_member_use
      expect(
        Obfuscate.deobfuscateBase64('not valid base64!!'),
        'not valid base64!!',
      );
    });

    test('ROT13 matches known vector from the original test suite', () {
      // ignore: deprecated_member_use
      final obfuscated = Obfuscate.obfuscateROT13('Hello World!');
      expect(obfuscated, 'Uryyb Jbeyq!');
      // ignore: deprecated_member_use
      expect(Obfuscate.deobfuscateROT13(obfuscated), 'Hello World!');
    });

    test('XOR matches the old raw-code-unit behavior (not XorCodec\'s)', () {
      const input = 'Hello World!';
      const key = 123;
      // ignore: deprecated_member_use
      final obfuscated = Obfuscate.obfuscateXOR(input, key);
      // ignore: deprecated_member_use
      expect(Obfuscate.deobfuscateXOR(obfuscated, key), input);
      // confirm it's genuinely the old code-unit XOR, not the new
      // byte+base64 format — output should be raw XORed chars, not base64
      expect(XorCodec(key).obfuscate(input), isNot(equals(obfuscated)));
    });

    test('Reverse matches known vector from the original test suite', () {
      // ignore: deprecated_member_use
      final obfuscated = Obfuscate.obfuscateReverse('Hello World!');
      expect(obfuscated, '!dlroW olleH');
      // ignore: deprecated_member_use
      expect(Obfuscate.deobfuscateReverse(obfuscated), 'Hello World!');
    });

    test('map-based methods match LegacyMapCodec exactly', () {
      final map = {'h': 'x', 'e': 'y', 'l': 'z', 'o': 'w'};
      // ignore: deprecated_member_use
      final obfuscated = Obfuscate.obfuscateWithMap('Hello', map);
      expect(obfuscated, LegacyMapCodec.obfuscate('Hello', map));
      // ignore: deprecated_member_use
      expect(
        Obfuscate.deobfuscateWithMap(obfuscated, map),
        LegacyMapCodec.deobfuscate(obfuscated, map),
      );
    });
  });

  group('VersionedObfuscationMethod', () {
    test('always encodes with the current version', () {
      final v = VersionedObfuscationMethod(
        currentVersion: 'x2',
        methods: {'x2': XorCodec(42)},
      );
      final encoded = v.obfuscate('hello');
      expect(encoded, XorCodec(42).obfuscate('hello'));
    });

    test('decodes by explicit version, never by guessing', () {
      final v = VersionedObfuscationMethod(
        currentVersion: 'x2',
        methods: {'x2': XorCodec(42)},
        // ignore: deprecated_member_use
        legacyFallback: (input) => Obfuscate.deobfuscateXOR(input, 42),
      );
      final newEncoded = v.obfuscate('hello');
      expect(v.deobfuscate(newEncoded, 'x2'), 'hello');

      // old data (no version field existed when it was created)
      // ignore: deprecated_member_use
      final oldEncoded = Obfuscate.obfuscateXOR('hello', 42);
      expect(v.deobfuscateLegacy(oldEncoded), 'hello');
    });

    test('throws on an unknown version rather than guessing', () {
      final v = VersionedObfuscationMethod(
        currentVersion: 'x2',
        methods: {'x2': XorCodec(42)},
      );
      expect(
        () => v.deobfuscate('anything', 'x99'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('LegacyMapCodec (frozen, for old data only)', () {
    test('reproduces the exact historical output for a known input', () {
      final map = {'h': 'x', 'e': 'y', 'l': 'z', 'o': 'w'};
      final obfuscated = LegacyMapCodec.obfuscate('Hello', map);
      // This is what the pre-refactor library actually produced —
      // frozen here as a golden vector so this file can never be
      // "fixed" by accident.
      expect(obfuscated, 'x y z z w');
      expect(LegacyMapCodec.deobfuscate(obfuscated, map), 'hello');
    });
  });
}
