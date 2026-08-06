import 'obfuscation_method.dart';

/// Result of [validateMap]. [errors] are things that will cause
/// incorrect encode/decode and must be fixed. [warnings] are things
/// that are risky but not necessarily wrong (e.g. a combining mark
/// that might render oddly in some clients).
class MapValidationResult {
  final List<String> errors;
  final List<String> warnings;

  MapValidationResult(this.errors, this.warnings);

  bool get isValid => errors.isEmpty;

  @override
  String toString() {
    final b = StringBuffer();
    if (errors.isNotEmpty) {
      b.writeln('Errors:');
      for (final e in errors) {
        b.writeln('  - $e');
      }
    }
    if (warnings.isNotEmpty) {
      b.writeln('Warnings:');
      for (final w in warnings) {
        b.writeln('  - $w');
      }
    }
    if (errors.isEmpty && warnings.isEmpty) {
      b.writeln('Map OK, no issues found.');
    }
    return b.toString();
  }
}

/// Validates a character map before it's used to build a codec.
///
/// [kind] determines which checks apply:
/// - [MapKind.substitution]: checks bijectivity and empty values, and
///   flags combining/zero-width characters used as output values
///   (warning only — these can render invisibly or get merged into a
///   neighboring character by Unicode normalization on paste/copy).
/// - [MapKind.token]: additionally requires that no value contains
///   [delimiter], since that would make splitting on decode ambiguous.
///
/// [requiredDomain], if provided, checks that every character in it
/// has an entry in [map] — use this to enforce e.g. "must cover all
/// 16 hex digits" for maps intended for use with [NibbleCodec].
///
/// This function never throws; it always returns a result you inspect.
/// Codec constructors call this internally and throw on `!isValid`.
MapValidationResult validateMap(
  Map<String, String> map, {
  required MapKind kind,
  String delimiter = ' ',
  Iterable<String>? requiredDomain,
}) {
  final errors = <String>[];
  final warnings = <String>[];

  if (map.isEmpty) {
    errors.add('Map is empty.');
    return MapValidationResult(errors, warnings);
  }

  // 1. Bijectivity: every output value must come from exactly one key.
  //    This is the check that would have caught OBF_FA1_Q and OBF_FA1_9
  //    both mapping to 'ز' — instead of only surfacing as a runtime
  //    print() warning the first time someone happened to decode it.
  final seenBy = <String, String>{};
  map.forEach((key, value) {
    final firstKey = seenBy[value];
    if (firstKey != null) {
      errors.add('Collision: "$firstKey" and "$key" both map to "$value"');
    } else {
      seenBy[value] = key;
    }
  });

  // 2. Empty values are never valid.
  map.forEach((key, value) {
    if (value.isEmpty) {
      errors.add('Empty mapping for key "$key"');
    }
  });

  // 3. Kind-specific checks.
  if (kind == MapKind.substitution) {
    map.forEach((key, value) {
      if (_looksLikeCombiningOrZeroWidth(value)) {
        warnings.add(
          '"$key" -> "$value" is a combining/zero-width character; '
          'may render invisibly, or merge into a neighboring character '
          'under Unicode normalization (e.g. NFC applied by some '
          'clipboard managers or messaging apps).',
        );
      }
    });
  } else {
    map.forEach((key, value) {
      if (value.contains(delimiter)) {
        errors.add(
          '"$key" -> "$value" contains the delimiter "$delimiter"; '
          'this will make decode ambiguous.',
        );
      }
    });
  }

  // 4. Domain coverage, if the caller specified one.
  if (requiredDomain != null) {
    for (final char in requiredDomain) {
      if (!map.containsKey(char)) {
        errors.add('Required character "$char" has no mapping.');
      }
    }
  }

  return MapValidationResult(errors, warnings);
}

/// Heuristic, range-based check for Unicode combining marks (general
/// categories Mn/Mc/Me) and zero-width/directional characters.
///
/// This is NOT a full Unicode database lookup — it covers the ranges
/// most likely to show up in hand-authored maps (Arabic diacritics,
/// combining diacritical marks, zero-width joiners/spaces). It is
/// exactly the check that would have flagged most of the current
/// FA1 lowercase block (ۥ ۦ ۧ ۨ ۩ ... are Arabic combining marks, not
/// standalone letters). For exhaustive correctness across all of
/// Unicode, consider the `characters` or `unicode` pub packages.
bool _looksLikeCombiningOrZeroWidth(String value) {
  for (final rune in value.runes) {
    if (_isCombiningOrZeroWidth(rune)) return true;
  }
  return false;
}

bool _isCombiningOrZeroWidth(int rune) {
  const ranges = [
    [0x0300, 0x036F], // Combining Diacritical Marks
    [0x0483, 0x0489], // Cyrillic combining marks
    [0x0591, 0x05BD], // Hebrew points
    [0x05BF, 0x05BF],
    [0x05C1, 0x05C2],
    [0x0610, 0x061A], // Arabic marks
    [0x064B, 0x065F], // Arabic tashkeel (diacritics)
    [0x0670, 0x0670], // Arabic letter superscript alef
    [0x06D6, 0x06DC], // Arabic small high marks
    [0x06DF, 0x06E4],
    [0x06E7, 0x06E8],
    [0x06EA, 0x06ED],
    [0x0711, 0x0711], // Syriac letter superscript alaph
    [0x0730, 0x074A], // Syriac diacritics
    [0x1AB0, 0x1AFF], // Combining Diacritical Marks Extended
    [0x1DC0, 0x1DFF], // Combining Diacritical Marks Supplement
    [0x20D0, 0x20FF], // Combining marks for symbols
    [0xFE20, 0xFE2F], // Combining half marks
    [0x200B, 0x200F], // zero-width space / ZWNJ / ZWJ / direction marks
    [0x202A, 0x202E], // directional formatting characters
    [0xFEFF, 0xFEFF], // BOM / zero-width no-break space
  ];
  for (final r in ranges) {
    if (rune >= r[0] && rune <= r[1]) return true;
  }
  return false;
}
