import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/utils/category_icons.dart';
import 'package:pantry/theme/app_theme.dart';
import 'form_components.dart';

class DeleteIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool busy;

  const DeleteIconButton({super.key, required this.onTap, required this.busy});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SurfaceRadius.tile),
      child: Container(
        width: 38,
        height: 38,
        decoration: AppSurfaces.of(context).iconTile(cs.error),
        child: busy
            ? Padding(
                padding: const EdgeInsets.all(9),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.error,
                ),
              )
            : Icon(Icons.delete_outline, color: cs.error, size: 20),
      ),
    );
  }
}

class HeaderPreview extends StatelessWidget {
  final String name;
  final models.Category? category;
  final Color? Function(String hex) parseColor;
  final String typeSummary;

  const HeaderPreview({
    super.key,
    required this.name,
    required this.category,
    required this.parseColor,
    required this.typeSummary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catColor = category != null
        ? (parseColor(category!.color) ?? cs.primary)
        : cs.onSurfaceVariant;
    final icon = category != null
        ? categoryIcon(category!.icon)
        : Icons.shopping_basket_outlined;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: AppSurfaces.of(
            context,
          ).iconTile(catColor, bordered: true),
          child: Icon(icon, color: catColor, size: 26),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                typeSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Filled card wrapping a single text field. The card's border + label color
/// flip to the accent when the field is focused — same treatment for name,
/// description, and (visually) the quantity row's inner input.
class LabeledField extends StatelessWidget {
  final String label;
  final bool focused;
  final Widget child;

  const LabeledField({
    super.key,
    required this.label,
    required this.focused,
    required this.child,
  });

  @override
  Widget build(BuildContext context) =>
      LabeledFieldCard(label: label, focused: focused, child: child);
}

class QuantityField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const QuantityField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelColor = focused ? cs.primary : cs.onSurfaceVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: AppSurfaces.of(context).card(focused: focused),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.checklists.itemForm.quantity.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              FormStepperButton(icon: Icons.remove, onTap: onMinus),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: m.checklists.compose.qtyHint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FormStepperButton(icon: Icons.add, accent: true, onTap: onPlus),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            m.checklists.compose.qtyStepperHelp,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class DockedSaveBar extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final bool saving;
  final String label;

  const DockedSaveBar({
    super.key,
    required this.onCancel,
    required this.onSave,
    required this.saving,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surfaces = AppSurfaces.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: surfaces.actionBar(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: Row(
          children: [
            InkWell(
              onTap: onCancel,
              borderRadius: BorderRadius.circular(SurfaceRadius.card),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: surfaces.secondaryButton(),
                child: Text(
                  m.common.cancel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: InkWell(
                onTap: onSave,
                borderRadius: BorderRadius.circular(SurfaceRadius.card),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: surfaces.primaryButton(raisedShadow: true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (saving)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: surfaces.onAccent,
                          ),
                        )
                      else
                        Icon(Icons.check, color: surfaces.onAccent, size: 20),
                      const SizedBox(width: 9),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: surfaces.onAccent,
                        ),
                      ),
                    ],
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
