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
            SlotStatus.available => '${slot.remaining} places left',
            SlotStatus.full => 'Fully booked',
            SlotStatus.blocked =>
              slot.reason.isEmpty ? 'Unavailable' : slot.reason,
            SlotStatus.past => 'Time passed',
          };
    return Semantics(
      label: '${slot.label}. $label',
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.emerald : AppColors.outline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onSelect : null,
          hoverColor: AppColors.mintStrong.withValues(alpha: .25),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  slot.label,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
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
