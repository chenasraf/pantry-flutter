import 'dart:async';

import 'package:flutter/material.dart';

import '../pairing/wear_pairing_client.dart';
import '../pairing/wear_setup_page.dart';
import '../widgets/wear_mechanics.dart';

/// Getting a rejected credential replaced, without giving anything up.
///
/// The same screen the watch shows before it has ever had a session, pushed
/// over the shell rather than replacing it — because everything the wearer had
/// is still readable underneath, and a wearer who changes their mind halfway
/// has to be able to get back to it. That is also why the renewal cannot be a
/// sign-out and a fresh pairing: the queue this is being done to drain would
/// go with it.
class SetUpAgainPage extends StatefulWidget {
  const SetUpAgainPage({super.key});

  @override
  State<SetUpAgainPage> createState() => _SetUpAgainPageState();
}

class _SetUpAgainPageState extends State<SetUpAgainPage> {
  final _client = WearPairingClient.instance;

  @override
  void initState() {
    super.initState();
    _client.addListener(_onState);
    unawaited(_client.renew());
  }

  @override
  void dispose() {
    _client.removeListener(_onState);
    super.dispose();
  }

  /// The grant landed, so there is nothing left to show. Leaving on its own is
  /// the point: the wearer asked for a credential, not for a screen.
  void _onState() {
    if (!mounted) return;
    if (_client.state == WearSetupState.ready) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => EdgeDismissible(
    onDismiss: () => Navigator.of(context).pop(),
    child: WearSetupPage(client: _client),
  );
}
