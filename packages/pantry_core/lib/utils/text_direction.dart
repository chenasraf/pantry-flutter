import 'package:flutter/widgets.dart';

/// Returns the text direction of [text] using the same logic as HTML
/// `dir="auto"`: find the first strongly-typed character and return its
/// directionality. Neutral characters (punctuation, numbers, whitespace,
/// emoji, symbols) are skipped.
///
/// Defaults to LTR for empty strings or strings with no strong characters.
TextDirection detectTextDirection(String? text) {
  if (text == null) return TextDirection.ltr;
  final trimmed = text.trim();
  if (trimmed.isEmpty) return TextDirection.ltr;

  for (final rune in trimmed.runes) {
    final dir = _runeDirection(rune);
    if (dir != null) return dir;
  }
  return TextDirection.ltr;
}

/// Returns the strong directionality of a rune, or null if it's neutral/weak.
/// Based on Unicode Bidirectional Character Type — we only care about the
/// strong classes: L (Left-to-Right), R (Right-to-Left), AL (Arabic Letter).
TextDirection? _runeDirection(int rune) {
  // Right-to-Left (R) — Hebrew, NKo, Samaritan, Mandaic
  if ((rune >= 0x0590 && rune <= 0x05FF) || // Hebrew
      (rune >= 0x07C0 && rune <= 0x07FF) || // NKo
      (rune >= 0x0800 && rune <= 0x083F) || // Samaritan
      (rune >= 0x0840 && rune <= 0x085F) || // Mandaic
      (rune >= 0xFB1D && rune <= 0xFB4F)) {
    // Hebrew presentation forms
    return TextDirection.rtl;
  }

  // Right-to-Left Arabic (AL) — Arabic, Syriac, Thaana, Arabic Supplement/Extended
  if ((rune >= 0x0600 && rune <= 0x06FF) || // Arabic
      (rune >= 0x0700 && rune <= 0x074F) || // Syriac
      (rune >= 0x0750 && rune <= 0x077F) || // Arabic Supplement
      (rune >= 0x0780 && rune <= 0x07BF) || // Thaana
      (rune >= 0x08A0 && rune <= 0x08FF) || // Arabic Extended-A
      (rune >= 0xFB50 && rune <= 0xFDFF) || // Arabic presentation forms A
      (rune >= 0xFE70 && rune <= 0xFEFF)) {
    // Arabic presentation forms B
    return TextDirection.rtl;
  }

  // Left-to-Right (L) — Latin, Greek, Cyrillic, Armenian, most scripts
  if ((rune >= 0x0041 && rune <= 0x005A) || // A-Z
      (rune >= 0x0061 && rune <= 0x007A) || // a-z
      (rune >= 0x00C0 && rune <= 0x00FF) || // Latin-1 Supplement letters
      (rune >= 0x0100 && rune <= 0x024F) || // Latin Extended A/B
      (rune >= 0x0370 && rune <= 0x03FF) || // Greek
      (rune >= 0x0400 && rune <= 0x04FF) || // Cyrillic
      (rune >= 0x0500 && rune <= 0x052F) || // Cyrillic Supplement
      (rune >= 0x0530 && rune <= 0x058F) || // Armenian
      (rune >= 0x1E00 && rune <= 0x1EFF) || // Latin Extended Additional
      (rune >= 0x2C60 && rune <= 0x2C7F) || // Latin Extended-C
      (rune >= 0xA720 && rune <= 0xA7FF) || // Latin Extended-D
      (rune >= 0x3040 && rune <= 0x309F) || // Hiragana
      (rune >= 0x30A0 && rune <= 0x30FF) || // Katakana
      (rune >= 0x4E00 && rune <= 0x9FFF) || // CJK Unified Ideographs
      (rune >= 0xAC00 && rune <= 0xD7AF)) {
    // Hangul Syllables
    return TextDirection.ltr;
  }

  // Neutral / weak — skip (punctuation, numbers, whitespace, symbols, emoji)
  return null;
}
