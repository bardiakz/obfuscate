/// Base exception type for all obfuscation/deobfuscation failures.
///
/// All codecs in this library throw this (or a subtype) instead of
/// silently returning corrupted or unchanged data — see the note on
/// [ObfuscationMethod].
class ObfuscationException implements Exception {
  final String message;
  const ObfuscationException(this.message);

  @override
  String toString() => 'ObfuscationException: $message';
}

/// Thrown when a map is invalid: not bijective, has empty values, or
/// a value collides with the configured delimiter. Thrown at codec
/// construction time so a bad map fails immediately rather than
/// producing a wrong-but-plausible decode later.
class InvalidMapException extends ObfuscationException {
  InvalidMapException(super.message);
}

/// Thrown when a character has no entry in a map that requires full
/// domain coverage (e.g. [TokenSubstitutionCodec], or [SubstitutionCodec]
/// constructed with `strict: true`).
class UnmappedCharacterException extends ObfuscationException {
  final String character;
  UnmappedCharacterException(this.character)
    : super('No mapping found for character: "$character"');
}

/// Thrown when obfuscated input cannot be parsed back into its
/// original form: corrupt data, wrong codec, wrong map/key, or data
/// produced by a different format version than the one decoding it.
class DecodingException extends ObfuscationException {
  DecodingException(super.message);
}
