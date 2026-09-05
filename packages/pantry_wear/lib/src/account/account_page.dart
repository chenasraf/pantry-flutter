import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../pairing/wear_pairing_client.dart';

/// Who the watch is signed in as, and the way back out.
///
/// Signing out here does **not** revoke: the app password is the phone's, and
/// revoking it from the wrist would sign the phone out too.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  /// A watch has no room for a dialog and no cancel a wearer can aim at, so
  /// the confirmation is a second tap on the same target — and it lapses on
  /// its own, which a dialog left open on a wrist would not.
  var _confirming = false;
  Timer? _lapse;

  @override
  void dispose() {
    _lapse?.cancel();
    super.dispose();
  }

  void _tap() {
    if (!_confirming) {
      setState(() => _confirming = true);
      _lapse = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _confirming = false);
      });
      return;
    }
    _lapse?.cancel();
    unawaited(WearPairingClient.instance.forget());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = AuthService.instance.credentials?.loginName ?? '';
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 22, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              name.isEmpty ? m.wear.account : m.wear.signedInAs(name),
              textAlign: TextAlign.center,
              textDirection: detectTextDirection(name),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _tap,
              behavior: HitTestBehavior.opaque,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _confirming
                      ? const Color(0xFF3A1D1D)
                      : const Color(0xFF17171A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Text(
                    _confirming ? m.wear.signOutConfirm : m.common.logout,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _confirming
                          ? const Color(0xFFE0A0A0)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
