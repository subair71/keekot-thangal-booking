import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/booking_models.dart';

class SlotCard extends StatelessWidget {
  const SlotCard({
    super.key,
    required this.slot,
    required this.selected,
    required this.visitors,
    required this.onSelect,
  });
  final VisitSlot slot;
  final bool selected;
  final int visitors;
  final VoidCallback onSelect;
  @override
  Widget build(BuildContext context) {
    final enabled = slot.accepts(visitors);
    final color = selected
        ? AppColors.emerald
        : slot.status == SlotStatus.blocked
        ? AppColors.rose
        : enabled
        ? AppColors.white
        : AppColors.disabled;
    final foreground = selected
        ? AppColors.white
        : slot.status == SlotStatus.blocked
        ? AppColors.error
        : AppColors.emerald;
    final label = selected
        ? 'Selected'
        : switch (slot.status) {
            SlotStatus.available =>
              enabled
                  ? '${slot.remaining} places left'
                  : 'Not enough places for this group',
            SlotStatus.full => 'Fully booked',
            SlotStatus.blocked =>
              slot.reason.isEmpty ? 'Unavailable' : slot.reason,
            SlotStatus.past => 'Time passed',
          };
    return Semantics(
      label: '${tr(context, slot.label)}. ${tr(context, label)}',
      excludeSemantics: true,
      onTap: enabled ? onSelect : null,
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.gold : AppColors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onSelect : null,
          hoverColor: AppColors.mintStrong.withValues(alpha: .25),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 17,
                      color: selected ? AppColors.mintStrong : foreground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        slot.label,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: selected
                      ? AppColors.ivory.withValues(alpha: .2)
                      : AppColors.outline,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: selected
                              ? AppColors.mintStrong
                              : AppColors.muted,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.mintStrong,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
