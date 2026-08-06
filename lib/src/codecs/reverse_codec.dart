import '../obfuscation_method.dart';

/// Reverses the order of a string's Unicode code points. Self-inverse.
///
/// Uses `.runes` rather than UTF-16 code units, so characters outside
/// the Basic Multilingual Plane (e.g. many emoji) survive intact
/// instead of being split into swapped surrogate halves. Combining
/// marks are still reversed as independent units from their base
/// character, which can look wrong for text that uses them — there is
/// no universally "correct" way to reverse a combining sequence, so
/// this is a known, documented limitation rather than a bug to fix
/// silently.
class ReverseCodec implements ObfuscationMethod {
  const ReverseCodec();

  @override
  String obfuscate(String input) =>
      String.fromCharCodes(input.runes.toList().reversed);

  @override
  String deobfuscate(String input) => obfuscate(input);
}
