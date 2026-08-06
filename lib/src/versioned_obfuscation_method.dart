import 'obfuscation_method.dart';

/// Dispatches to one of several [ObfuscationMethod]s based on an
/// explicit version identifier, so callers never have to pick a
/// class by hand at each call site — but critically, the version
/// comes from an authoritative source (a tag, a stored field, a
/// format marker known to be safe for that codec's output space),
/// never from guessing which codec successfully decoded the input.
///
/// Guessing is unsafe in general: a wrong-format decode frequently
/// does not throw, it just silently produces wrong-but-plausible
/// output. This class deliberately does not attempt that — it has no
/// "try each until one works" mode. If you don't have a reliable
/// version signal, you don't have a version, and mixing formats
/// blind is not something this class will do for you.
///
/// Typical use: register your current codec under a version key, plus
/// any old codecs under their historical keys, then always encode
/// with [currentVersion] and decode by whatever version the message
/// says it is.
///
/// ```dart
/// final xor = VersionedObfuscationMethod(
///   currentVersion: 'x2',
///   methods: {
///     'x2': XorCodec(myKey),          // current, byte-safe format
///   },
///   legacyFallback: (input) => Obfuscate.deobfuscateXOR(input, myKey),
/// );
///
/// // qrypt's tag already records which version was used, e.g.:
/// final encoded = xor.obfuscate(plaintext); // always current version
/// final decoded = version == null
///     ? xor.deobfuscateLegacy(cipherText)   // no version in old tags
///     : xor.deobfuscate(cipherText, version);
/// ```
class VersionedObfuscationMethod {
  final String currentVersion;
  final Map<String, ObfuscationMethod> methods;
  final String Function(String input)? legacyFallback;

  VersionedObfuscationMethod({
    required this.currentVersion,
    required this.methods,
    this.legacyFallback,
  }) : assert(
         methods.containsKey(currentVersion),
         'methods must contain an entry for currentVersion',
       );

  /// Always encodes with the current version's codec.
  String obfuscate(String input) => methods[currentVersion]!.obfuscate(input);

  /// Decodes using the codec registered for [version]. Throws
  /// [ArgumentError] if [version] isn't registered — this is
  /// intentionally strict rather than falling back silently.
  String deobfuscate(String input, String version) {
    final method = methods[version];
    if (method == null) {
      throw ArgumentError.value(
        version,
        'version',
        'No codec registered for this version. Known versions: '
            '${methods.keys.join(', ')}',
      );
    }
    return method.deobfuscate(input);
  }

  /// Decodes data that predates versioning entirely (no version field
  /// existed in the tag/format at the time it was created). Only
  /// call this when you positively know there's no version signal to
  /// read — e.g. the message's tag format itself is the old,
  /// unversioned one.
  String deobfuscateLegacy(String input) {
    if (legacyFallback == null) {
      throw StateError(
        'No legacyFallback was configured for this '
        'VersionedObfuscationMethod.',
      );
    }
    return legacyFallback!(input);
  }
}
