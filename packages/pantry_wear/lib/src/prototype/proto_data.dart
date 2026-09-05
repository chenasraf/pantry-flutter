import 'dart:async';

import 'package:flutter/material.dart';

/// PROTOTYPE — throwaway stand-in data. Nothing here reaches a server; the
/// shell is being judged on density and geometry, not on fetching.

@immutable
class ProtoItem {
  final String name;
  final String? qty;
  final bool done;

  const ProtoItem(this.name, {this.qty, this.done = false});
}

const protoHouse = 'Home';
const protoListName = 'Groceries';

/// Long enough to scroll well past a watch screen, with the two cases that
/// break watch rows: a name too long for one line, and a right-to-left name.
const protoItems = <ProtoItem>[
  ProtoItem('Milk', qty: '2 L'),
  ProtoItem('Sourdough loaf'),
  ProtoItem('Eggs', qty: '12'),
  ProtoItem('Coffee beans, dark roast', qty: '500 g'),
  ProtoItem('חלב עיזים', qty: '1'),
  ProtoItem('Bananas', qty: '6', done: true),
  ProtoItem('Olive oil'),
  ProtoItem('Chickpeas', qty: '2 tins'),
  ProtoItem('Greek yoghurt', qty: '1 kg'),
  ProtoItem('Tomatoes', qty: '500 g', done: true),
  ProtoItem('Cucumber', qty: '3'),
  ProtoItem('Parmesan'),
  ProtoItem('Kitchen roll', qty: '4'),
  ProtoItem('Washing-up liquid'),
  ProtoItem('Rice', qty: '1 kg'),
  ProtoItem('Frozen peas'),
  ProtoItem('Chicken thighs', qty: '1 kg'),
  ProtoItem('Lemons', qty: '4'),
  ProtoItem('Dark chocolate, 70%'),
  ProtoItem('Toothpaste', done: true),
  ProtoItem('Bin bags'),
  ProtoItem('Oat milk', qty: '2'),
  ProtoItem('Cat food', qty: '8 pouches'),
];

@immutable
class ProtoPhoto {
  final String caption;
  final Color a;
  final Color b;

  const ProtoPhoto(this.caption, this.a, this.b);
}

const protoPhotos = <ProtoPhoto>[
  ProtoPhoto('Fridge shelf', Color(0xFF3A6EA5), Color(0xFF1B3A5C)),
  ProtoPhoto('Receipt', Color(0xFF8E6A3A), Color(0xFF4A3620)),
  ProtoPhoto('Paint colour', Color(0xFF4B7F52), Color(0xFF223A26)),
  ProtoPhoto('Boiler dial', Color(0xFF7A4A6E), Color(0xFF3A2434)),
  ProtoPhoto('Bike lock', Color(0xFF9A5A3A), Color(0xFF4A2A1B)),
  ProtoPhoto('Spare key', Color(0xFF3A7A7A), Color(0xFF1C3B3B)),
];

/// The three states the shell has to show. The phone surfaces only a backlog
/// or an error and stays silent on a clean flush; the watch has far less room
/// to spend, so this is the set worth designing against.
enum ProtoSync { idle, offline, error }

/// Walks the sync states on a timer so every variant can be judged in all
/// three without a control to drive it.
///
/// It pauses when the watch stops showing the app, which is the behaviour the
/// real polling loop needs: a Dart timer keeps firing through a doze window,
/// so nothing periodic may be left running on blur.
class ProtoSyncCycler extends ChangeNotifier {
  ProtoSyncCycler() {
    _lifecycle = AppLifecycleListener(
      onHide: pause,
      onPause: pause,
      onShow: resume,
      onRestart: resume,
    );
    resume();
  }

  static const _period = Duration(seconds: 6);

  Timer? _timer;
  late final AppLifecycleListener _lifecycle;
  var _index = 0;

  ProtoSync get state => ProtoSync.values[_index];

  int get pending => state == ProtoSync.idle ? 0 : 3;

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    _timer ??= Timer.periodic(_period, (_) {
      _index = (_index + 1) % ProtoSync.values.length;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    pause();
    _lifecycle.dispose();
    super.dispose();
  }
}

/// Icon, colour and label for a sync state, so the three variants disagree
/// about placement rather than about vocabulary.
({IconData icon, Color color, String label}) protoSyncLook(
  BuildContext context,
  ProtoSync state,
  int pending,
) {
  final scheme = Theme.of(context).colorScheme;
  return switch (state) {
    ProtoSync.idle => (
      icon: Icons.cloud_done_outlined,
      color: scheme.onSurfaceVariant,
      label: 'Up to date',
    ),
    ProtoSync.offline => (
      icon: Icons.cloud_off_outlined,
      color: scheme.secondary,
      label: '$pending waiting',
    ),
    ProtoSync.error => (
      icon: Icons.error_outline,
      color: scheme.error,
      label: 'Sync failed',
    ),
  };
}
