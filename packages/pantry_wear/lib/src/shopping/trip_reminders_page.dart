import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/shopping_reminder.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';

/// What the house wants remembering before a trip starts, read and nothing
/// else.
///
/// Reminders are prose, and writing prose is not something the watch does — so
/// there is no add, no edit and no acknowledgement here. A reminder is
/// acknowledged by having been read.
class TripRemindersPage extends StatefulWidget {
  final List<ShoppingReminder> reminders;

  const TripRemindersPage({super.key, required this.reminders});

  @override
  State<TripRemindersPage> createState() => _TripRemindersPageState();
}

class _TripRemindersPageState extends State<TripRemindersPage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: wearGround,
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: RotaryScrollable(
          controller: _scroll,
          active: true,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 44,
            ),
            children: [
              if (widget.reminders.isEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 12),
                  child: Text(
                    m.shopping.noRemindersHere,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ),
              for (final reminder in widget.reminders)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsetsDirectional.only(top: 2, end: 8),
                        child: Icon(
                          Icons.notifications_none,
                          size: 13,
                          color: Colors.white38,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          reminder.text,
                          textDirection: detectTextDirection(reminder.text),
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
