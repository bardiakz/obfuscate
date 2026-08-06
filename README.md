# Obfuscate

Text obfuscation toolkit for Dart — CLI and library.

> Obfuscation, not encryption. Base64/ROT13/XOR/reverse/map ciphers give no real confidentiality — don't use this for anything that actually needs to stay secret.

## Features

- **CLI tool** for quick obfuscation from the command line
- **Dart library** to integrate into your own projects
- **Methods**: Base64, ROT13, XOR (byte-safe), string reversal, character-substitution maps, word-token maps
- **`validateMap()`** catches bad maps (collisions, empty values, risky characters) before you use them
- **`NibbleCodec`** applies any codec safely to raw bytes, not just text

## Install

```bash
dart pub global activate obfuscate
```

## Usage

```dart
import 'package:obfuscate/obfuscate.dart';

const codec = Base64ObfuscationCodec();
final encoded = codec.obfuscate('Hello, World!');
final decoded = codec.deobfuscate(encoded);

// character map
final substitution = SubstitutionCodec({'h': 'x', 'e': 'y'});

// word map
final tokens = TokenSubstitutionCodec({'h': 'house', 'e': 'energy'});
```

Upgrading from an earlier version? The old `Obfuscate.obfuscateBase64()`-style static methods still work — deprecated, not removed, no code changes needed. See `CHANGELOG.md`.