/// How the phone draws itself, as the watch paired to it can read.
///
/// The server is not a source on a watch: nothing there fetches a user profile
/// or a theme, so both of the rungs that give a phone its language and its
/// accent are dead on the wrist. What the phone resolved is the nearest thing
/// to a source the watch has, so the phone states it and the watch reads it.
///
/// Every field is a **default**. An explicit choice made on the wrist outranks
/// the publication and goes on outranking it, which is what keeps this a
/// published default rather than one device writing another's settings.
///
/// Brightness is deliberately absent. The watch is dark, and the two-plane
/// ground the rail, the note falloff and the degraded wash are all drawn
/// against is a decision about an OLED that is off most of the time — not one
/// the phone's light mode has anything to say about.
class WearAppearance {
  WearAppearance._();

  /// Phone → watch. Its own path, never [WearPairing.statePath]: a `DataItem`
  /// write is whole-item, so folding a cosmetic and frequently-fired value into
  /// the pairing would push every language change through the guard that
  /// decides whether a watch is still signed in.
  static const path = '/appearance/state';
}

/// One statement of how the phone looks, absolute rather than a change.
///
/// Language crosses **resolved** and the accent crosses **as inputs**, under
/// one principle: carry whatever core's resolver needs, and where a rung is
/// dead on the watch, carry the resolution instead. The phone's own locale
/// preference is nullable and most phones leave it unset, drawing from the
/// Nextcloud user language — a watch handed that null would fall to its own OS
/// language, which is the divergence this exists to close. Both of
/// `ThemingService.effectiveColor`'s inputs can cross, so its resolver runs on
/// the watch verbatim.
class WearAppearanceState {
  /// The locale the phone is drawing in, already resolved through its own
  /// ladder. Null only for a phone whose resolution named nothing supported.
  final String? locale;

  /// The Nextcloud accent the phone last fetched, as `#RRGGBB`.
  final String? themeColorHex;

  /// Whether the phone paints with that accent at all.
  final bool useServerThemeColor;

  const WearAppearanceState({
    this.locale,
    this.themeColorHex,
    this.useServerThemeColor = true,
  });

  Map<String, dynamic> toJson() => {
    'locale': locale,
    'themeColorHex': themeColorHex,
    'useServerThemeColor': useServerThemeColor,
  };

  static WearAppearanceState fromJson(Map<String, dynamic> json) =>
      WearAppearanceState(
        locale: switch (json['locale']) {
          final String code when code.isNotEmpty => code,
          _ => null,
        },
        themeColorHex: switch (json['themeColorHex']) {
          final String hex when hex.isNotEmpty => hex,
          _ => null,
        },
        useServerThemeColor: json['useServerThemeColor'] != false,
      );

  /// Compared before a publish, so a phone that notifies for an unrelated
  /// preference does not wake the link.
  @override
  bool operator ==(Object other) =>
      other is WearAppearanceState &&
      other.locale == locale &&
      other.themeColorHex == themeColorHex &&
      other.useServerThemeColor == useServerThemeColor;

  @override
  int get hashCode => Object.hash(locale, themeColorHex, useServerThemeColor);
}
