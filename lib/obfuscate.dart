/// A library for text and byte obfuscation (NOT encryption — no
/// confidentiality guarantees). Provides:
///
/// - [SubstitutionCodec]: 1 character -> 1 character maps.
/// - [TokenSubstitutionCodec]: 1 character -> 1 word/token maps.
/// - [NibbleCodec]: wraps either of the above so it can be safely
///   applied to arbitrary binary data.
/// - [Base64ObfuscationCodec], [Rot13Codec], [XorCodec], [ReverseCodec]:
///   simple standalone codecs.
/// - [validateMap]: checks a map for collisions, empty values, and
///   risky characters before you build a codec from it.
/// - [LegacyMapCodec]: frozen copy of the pre-refactor map codec, for
///   decoding data obfuscated by older versions only. Never use for
///   new code.
/// - `Obfuscate` (deprecated): static-method compatibility shim
///   reproducing the exact pre-0.1.0 API and behavior, so existing
///   call sites keep compiling unchanged. New code should not use it.
///
/// All codecs implement [ObfuscationMethod] and throw
/// [ObfuscationException] subtypes on invalid input rather than
/// silently returning wrong or empty data.
library;

export 'src/codecs/base64_codec.dart';
export 'src/codecs/reverse_codec.dart';
export 'src/codecs/rot13_codec.dart';
export 'src/codecs/xor_codec.dart';
export 'src/exceptions.dart';
export 'src/legacy/legacy_map_codec.dart';
export 'src/legacy/obfuscate_compat.dart';
export 'src/map_validator.dart';
export 'src/nibble_codec.dart';
export 'src/obfuscation_method.dart';
export 'src/substitution_codec.dart';
export 'src/token_substitution_codec.dart';
export 'src/versioned_obfuscation_method.dart';
