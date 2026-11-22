import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry/views/home/home_floating_nav.dart';

/// Offers a section's ways of adding something to the home nav's trailing
/// button, drawn as [icon]. A single action is the button's own tap, labelled
/// as the action; several fan out above it under [label]; none takes the
/// button off the bar.
///
/// Draws nothing of its own beyond [child] — it sits in the section's tree so
/// the offer is re-made as the actions change with permissions and server
/// features.
class NavActionOffer extends StatefulWidget {
  final ValueNotifier<NavPrimaryAction?>? holder;
  final List<NavMenuAction> actions;
  final IconData icon;
  final String? label;
  final Widget? child;

  const NavActionOffer({
    super.key,
    required this.holder,
    required this.actions,
    this.icon = Icons.add,
    this.label,
    this.child,
  });

  @override
  State<NavActionOffer> createState() => _NavActionOfferState();
}

class _NavActionOfferState extends State<NavActionOffer> {
  @override
  void initState() {
    super.initState();
    // Drop whatever the previous section left in the nav slot. An offer from
    // this one looks identical and would be discarded as unchanged, leaving the
    // button wired to a section that is gone.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.holder?.value = null;
    });
  }

  NavPrimaryAction? get _offer {
    final actions = widget.actions;
    if (actions.isEmpty) return null;
    if (actions.length == 1) {
      final only = actions.single;
      return NavPrimaryAction(
        icon: widget.icon,
        label: only.label,
        onTap: only.onTap,
      );
    }
    return NavPrimaryAction(
      icon: widget.icon,
      label: widget.label ?? m.common.add,
      menu: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final holder = widget.holder;
    if (holder != null) {
      final offer = _offer;
      // A listenable is not mutated mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        holder.value = offer;
      });
    }
    return widget.child ?? const SizedBox.shrink();
  }
}
