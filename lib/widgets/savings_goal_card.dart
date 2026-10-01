import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../models/savings_goal_model.dart';
import 'app_card.dart';

class SavingsGoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  final VoidCallback? onAddSavings;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SavingsGoalCard({
    super.key,
    required this.goal,
    this.onAddSavings,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = goal.progressPercentage;
    final pctInt = (pct * 100).toInt();

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: AppColors.teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        goal.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: goal.isCompleted
                          ? AppColors.greenBg
                          : (isDark ? AppColors.darkBorder : AppColors.surfaceMuted),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      goal.isCompleted ? 'Completed 🎉' : '$pctInt%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: goal.isCompleted ? AppColors.emeraldDark : AppColors.teal,
                      ),
                    ),
                  ),
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
                            Text('Edit Goal'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.redError),
                            SizedBox(width: 8),
                            Text('Delete Goal', style: TextStyle(color: AppColors.redError)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Saved vs Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved: ${CurrencyHelper.format(goal.currentSaved)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                ),
              ),
              Text(
                'Target: ${CurrencyHelper.format(goal.targetAmount)}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(
                  goal.isCompleted ? AppColors.emeraldGreen : AppColors.teal,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Motivational Quote
          Text(
            goal.motivationalInsight,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.isCompleted
                    ? 'Target accomplished!'
                    : '${CurrencyHelper.format(goal.remainingAmount)} left to reach goal',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                ),
              ),
              if (!goal.isCompleted && onAddSavings != null)
                TextButton.icon(
                  onPressed: onAddSavings,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Savings'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
