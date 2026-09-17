import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../services/wear_host_service.dart';
import 'wear_surfaces.dart';

/// The furniture a detail page is built from.
///
/// Three surfaces open one thing to say everything known about it — an item,
/// a photo, a note — and they are read the same way: a stack of facts with the
/// hand-off to the phone under them. One set of parts keeps them reading as
/// one screen at three depths rather than three screens that resemble each
/// other.
///
/// Every part takes its [ink], because a note detail page is drawn on the
/// colour its author picked and a fixed white would vanish on half the
/// palette.

/// The quiet ink a page with no colour of its own draws its facts in.
const kDetailInk = Color(0xFFB6B6BE);

/// One fact: its label over its value.
///
/// Label over value rather than beside it. A watch is too narrow to put a
/// caption and an arbitrary-length value on one line — a recurrence summary
/// alone can run to "Every week on Monday, Thursday" — so the value gets the
/// full width and wraps into it.
class WearFact extends StatelessWidget {
  final String label;
  final Widget value;

  /// A second line under the value, in the quieter ink: the exact answer where
  /// the value is the one read at a glance. A date is the case it exists for —
  /// "2 weeks ago" is what the wearer wants, and "3 Sep 2025, 14:20" is what
  /// they check.
  final String? note;

  final Color ink;

  const WearFact({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.ink = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final detail = note;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.7,
              color: ink.withValues(alpha: 0.38),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Align(alignment: AlignmentDirectional.centerStart, child: value),
          if (detail != null) ...[
            const SizedBox(height: 3),
            Text(
              detail,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.2,
                color: ink.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A full-width action at the foot of a detail page.
class WearDetailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const WearDetailButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: DecoratedBox(
      decoration: WearSurface.panel(
        context,
        fill: color.withValues(alpha: 0.18),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                textDirection: detectTextDirection(label),
                style: TextStyle(fontSize: 12, color: color),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Hands [url] to the paired phone, and says how that went in its own label.
///
/// The outcome is shown in place of the button's text because the watch has
/// nowhere to put a toast that isn't over the content the wearer is reading.
class OpenOnPhoneButton extends StatefulWidget {
  final String url;
  final Color ink;

  const OpenOnPhoneButton({
    super.key,
    required this.url,
    this.ink = const Color(0xFF8A8A92),
  });

  @override
  State<OpenOnPhoneButton> createState() => _OpenOnPhoneButtonState();
}

class _OpenOnPhoneButtonState extends State<OpenOnPhoneButton> {
  String? _outcome;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    final opened = await WearHostService.instance.openOnPhone(widget.url);
    if (!mounted) return;
    setState(() {
      _outcome = opened ? m.wear.openedOnPhone : m.wear.openOnPhoneFailed;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _outcome = null);
    });
  }

  @override
  Widget build(BuildContext context) => WearDetailButton(
    icon: Icons.phone_android,
    label: _outcome ?? m.wear.openOnPhone,
    color: widget.ink,
    onTap: _open,
  );
}
