/// A reversible text transformation.
///
/// Implementations should guarantee that, for a correctly-configured
/// instance, `deobfuscate(obfuscate(x)) == x` for all valid input `x`.
///
/// IMPORTANT: implementations must NEVER silently swallow decode
/// errors — throw an [ObfuscationException] instead of
/// returning the input unchanged or an empty string.
abstract class ObfuscationMethod {
  String obfuscate(String input);
  String deobfuscate(String input);
}

/// Kind of character map, used by [validateMap] to select which
/// checks apply.
enum MapKind {
  /// One character maps to exactly one character. No delimiter is
  /// needed since input length (in code points) always equals output
  /// length. See [SubstitutionCodec].
  substitution,

  /// One character maps to a token (a word or any multi-character
  /// string). Requires a delimiter and full domain coverage, since an
  /// unmapped raw character sitting next to word-tokens would be
  /// ambiguous on decode. See [TokenSubstitutionCodec].
  token,
}
