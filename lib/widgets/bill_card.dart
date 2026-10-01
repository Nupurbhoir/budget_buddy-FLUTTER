import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../models/bill_model.dart';
import 'app_card.dart';

class BillCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleReminder;

  const BillCard({
    super.key,
    required this.bill,
    this.onMarkPaid,
    this.onEdit,
    this.onDelete,
    this.onToggleReminder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = bill.dynamicStatus;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (bill.isPaid) {
      badgeBg = AppColors.greenBg;
      badgeText = AppColors.emeraldDark;
      badgeLabel = 'Paid';
    } else if (status == 'overdue') {
      badgeBg = AppColors.redBg;
      badgeText = AppColors.redError;
      badgeLabel = bill.dueLabel;
    } else if (status == 'due_soon') {
      badgeBg = AppColors.warningBg;
      badgeText = AppColors.orangeWarning;
      badgeLabel = bill.dueLabel;
    } else {
      badgeBg = isDark ? AppColors.darkBorder : AppColors.surfaceMuted;
      badgeText = isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary;
      badgeLabel = bill.dueLabel;
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.orangeWarning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.orangeWarning,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          bill.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.slateLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          bill.frequency,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyHelper.format(bill.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? badgeText.withOpacity(0.2) : badgeBg,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    bill.reminderEnabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    size: 16,
                    color: bill.reminderEnabled
                        ? AppColors.emeraldGreen
                        : (isDark ? AppColors.darkTextSecondary : AppColors.slateLight),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Reminder',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                    ),
                  ),
                  Switch(
                    value: bill.reminderEnabled,
                    activeColor: AppColors.emeraldGreen,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: onToggleReminder,
                  ),
                ],
              ),
              Row(
                children: [
                  if (!bill.isPaid && onMarkPaid != null)
                    TextButton.icon(
                      onPressed: onMarkPaid,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Mark as Paid'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.emeraldGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz,
                      size: 20,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    onSelected: (val) {
                      if (val == 'edit') onEdit?.call();
                      if (val == 'delete') onDelete?.call();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Bill'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.redError),
                            SizedBox(width: 8),
                            Text('Delete Bill', style: TextStyle(color: AppColors.redError)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
