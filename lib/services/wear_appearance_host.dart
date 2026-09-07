import 'dart:async';

import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/theming_service.dart';
import 'package:pantry_core/services/wear_appearance.dart';
import 'package:pantry_core/services/wear_link_service.dart';

import 'wear_pairing_host.dart';

/// States how this phone draws itself, so the watch it signed in looks like
/// the same app.
///
/// Published rather than sent: a message reaches nothing on a watch whose app
/// is not running, and a language is a statement that has to be true on the
/// next wrist-raise rather than an event that happened once. The same shape
/// [WearPairingHost] uses for the pairing itself, on a path of its own.
///
/// It listens to the two services that own appearance rather than to each
/// screen that changes it: `LocaleService` notifies for a deliberate switch and
/// for the background profile fetch that re-resolves one, and `ThemingService`
/// for the fetched accent and the opt-out over it.
class WearAppearanceHost {
  WearAppearanceHost._();

  static final WearAppearanceHost instance = WearAppearanceHost._();

  final _link = WearLinkService.instance;
  final _locale = LocaleService.instance;
  final _theming = ThemingService.instance;
  final _pairing = WearPairingHost.instance;

  var _listening = false;

  /// What was last put on the wire. Appearance changes are cosmetic and their
  /// triggers fire freely, so an identical statement is dropped here rather
  /// than costing a channel round trip.
  WearAppearanceState? _published;

  Future<void> init() async {
    if (_listening) return;
    if (!await _link.isAvailable()) return;
    _listening = true;
    _locale.addListener(_onChanged);
    _theming.addListener(_onChanged);
    // A pairing granted after this runs is the other moment a watch needs the
    // statement, and it is the first moment one is worth making.
    _pairing.paired.addListener(_onPaired);
    await publish();
  }

  Future<void> dispose() async {
    if (!_listening) return;
    _listening = false;
    _locale.removeListener(_onChanged);
    _theming.removeListener(_onChanged);
    _pairing.paired.removeListener(_onPaired);
    _published = null;
  }

  /// Say how this phone draws, if it has anyone to say it to.
  ///
  /// Guarded on a pairing at every call site rather than at one: a phone that
  /// has signed nobody in has nothing to state, and publishing anyway would
  /// hand its language to a watch some other phone owns.
  Future<void> publish() async {
    if (_pairing.paired.value == null) return;
    final state = WearAppearanceState(
      locale: _locale.effectiveLocale.languageCode,
      themeColorHex: PrefsService.instance.themeColorHex,
      useServerThemeColor: _theming.useServerThemeColor,
    );
    if (state == _published) return;
    if (await _link.publish(WearAppearance.path, state.toJson())) {
      _published = state;
    }
  }

  void _onChanged() => unawaited(publish());

  /// A pairing is a new audience, and the dedupe below is only about not
  /// repeating ourselves to the same one.
  ///
  /// The statement may be word for word what the last watch was told, and this
  /// watch has never heard it — or, having been signed out when it arrived,
  /// deliberately ignored it. Either way the cache is dropped so the pairing
  /// always puts one on the wire.
  void _onPaired() {
    _published = null;
    _onChanged();
  }
}
