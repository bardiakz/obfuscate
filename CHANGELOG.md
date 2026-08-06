## 1.0.0

Redesigned the codec architecture.Old data and old code both keep working:

**Added**
- `SubstitutionCodec` and `TokenSubstitutionCodec` — typed replacements for the old character-map obfuscation, split by whether a map goes char-to-char or char-to-word
- `NibbleCodec` — safely applies any codec to raw bytes, not just text.
- `validateMap()` — checks a map for duplicate values, empty entries, and risky characters (like combining marks) before you use it.
- `VersionedObfuscationMethod` — lets you decode both old- and new-format data through one call, based on an explicit version rather than guessing.
- Proper exceptions (`ObfuscationException` and subtypes) instead of silent failures.

**Fixed**
- XOR obfuscation could corrupt data when writing to UTF-8 (invalid surrogate sequences for some key/input combos). Now operates on bytes and outputs base64.
- Map-based obfuscation inserted a stray delimiter between every character and silently ate original whitespace on decode.
- `deobfuscateBase64` used to return the input unchanged on a bad decode instead of signaling failure.

**Deprecated**
- The old static `Obfuscate` class (`obfuscateBase64`, `obfuscateWithMap`, etc.) is deprecated but still works exactly as before — no code changes required.

**Compatibility**
- Data obfuscated with 0.0.1 still decodes correctly via `LegacyMapCodec` and the deprecated `Obfuscate` methods.
- New code should use the codec classes above instead.
- 
## 0.0.1

- Initial version.
