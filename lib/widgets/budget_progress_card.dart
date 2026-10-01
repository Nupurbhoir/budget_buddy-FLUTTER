import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../models/budget_model.dart';
import 'app_card.dart';

class BudgetProgressCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BudgetProgressCard({
    super.key,
    required this.budget,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = budget.percentageUsed;
    final pctClamped = pct.clamp(0.0, 1.0);
    final pctInt = (pct * 100).toInt();

    Color progressColor;
    Color statusBg;
    Color statusText;
    String statusLabel;

    if (budget.isExceeded) {
      progressColor = AppColors.redError;
      statusBg = AppColors.redBg;
      statusText = AppColors.redError;
      statusLabel = 'Exceeded';
    } else if (budget.isWarning) {
      progressColor = AppColors.orangeWarning;
      statusBg = AppColors.warningBg;
      statusText = AppColors.orangeWarning;
      statusLabel = 'Warning (80%)';
    } else {
      progressColor = AppColors.emeraldGreen;
      statusBg = AppColors.greenBg;
      statusText = AppColors.emeraldDark;
      statusLabel = 'On Track';
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  budget.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? statusText.withOpacity(0.2) : statusBg,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusText,
                  ),
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
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
                          Text('Edit Budget'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.redError),
                          SizedBox(width: 8),
                          Text('Delete Budget', style: TextStyle(color: AppColors.redError)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Amount spent vs total limit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  text: CurrencyHelper.format(budget.spentAmount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                  ),
                  children: [
                    TextSpan(
                      text: ' / ${CurrencyHelper.format(budget.totalAmount)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$pctInt%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: pctClamped,
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                budget.isExceeded
                    ? 'Exceeded by ${CurrencyHelper.format(budget.spentAmount - budget.totalAmount)}'
                    : '${CurrencyHelper.format(budget.remainingAmount)} remaining',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: budget.isExceeded
                      ? AppColors.redError
                      : (isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary),
                ),
              ),
              Text(
                'Monthly Cycle',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slateLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
