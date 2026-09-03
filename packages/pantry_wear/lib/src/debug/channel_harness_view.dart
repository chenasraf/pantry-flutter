import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/services/wear_link_service.dart';

import '../services/rotary_service.dart';
import '../services/wear_host_service.dart';
import '../wear_shape.dart';

/// Exercises each native channel against real hardware.
///
/// The two pieces most likely to break are the two no test can reach: rotary
/// input cannot be injected over adb, and the link needs two paired devices.
/// This screen is where they get checked, and the strings are deliberately
/// literal — it is a debug surface and never reaches a translator.
class ChannelHarnessView extends StatefulWidget {
  const ChannelHarnessView({super.key});

  @override
  State<ChannelHarnessView> createState() => _ChannelHarnessViewState();
}

class _ChannelHarnessViewState extends State<ChannelHarnessView> {
  StreamSubscription<double>? _rotary;
  StreamSubscription<WearLinkMessage>? _link;

  int _detents = 0;
  double _lastDetent = 0;
  bool? _linkAvailable;
  List<WearLinkNode> _nodes = const [];
  String _lastSend = '—';
  String _lastReceived = '—';
  String _lastOpen = '—';

  @override
  void initState() {
    super.initState();
    _rotary = RotaryService.instance.detents.listen((value) {
      setState(() {
        _detents += 1;
        _lastDetent = value;
      });
    });
    _link = WearLinkService.instance.messages.listen((message) {
      setState(() => _lastReceived = '${message.path} ${message.data}');
    });
    _probeLink();
  }

  @override
  void dispose() {
    _rotary?.cancel();
    _link?.cancel();
    super.dispose();
  }

  Future<void> _probeLink() async {
    final available = await WearLinkService.instance.isAvailable();
    final nodes = await WearLinkService.instance.nodes();
    if (!mounted) return;
    setState(() {
      _linkAvailable = available;
      _nodes = nodes;
    });
  }

  Future<void> _ping() async {
    final delivered = await WearLinkService.instance.send('/debug/ping', {
      'from': 'watch',
    });
    if (!mounted) return;
    setState(() => _lastSend = delivered ? 'delivered' : 'not delivered');
  }

  Future<void> _open() async {
    final opened = await WearHostService.instance.openOnPhone(
      'https://github.com/chenasraf/pantry-flutter',
    );
    if (!mounted) return;
    setState(() => _lastOpen = opened ? 'opened' : 'failed');
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _nodes.isEmpty
        ? 'none'
        : _nodes.map((node) => node.name).join(', ');
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          children: [
            const Text('Channels', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            _row('shape', WearShape.shape.name),
            _row('detents', '$_detents (${_lastDetent.toStringAsFixed(1)})'),
            _row('link', switch (_linkAvailable) {
              null => 'probing',
              true => 'available',
              false => 'unavailable',
            }),
            _row('nodes', nodes),
            _row('sent', _lastSend),
            _row('received', _lastReceived),
            _row('openOnPhone', _lastOpen),
            const SizedBox(height: 12),
            TextButton(onPressed: _ping, child: const Text('Send ping')),
            TextButton(onPressed: _open, child: const Text('Open on phone')),
            TextButton(onPressed: _probeLink, child: const Text('Re-probe')),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: style),
          Expanded(child: Text(value, style: style)),
        ],
      ),
    );
  }
}
