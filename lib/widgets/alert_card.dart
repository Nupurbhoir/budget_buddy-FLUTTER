import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/alert_model.dart';
import 'app_card.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;
  final VoidCallback? onAction;
  final String? actionText;

  const AlertCard({
    super.key,
    required this.alert,
    this.onMarkRead,
    this.onDelete,
    this.onAction,
    this.actionText,
  });

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'budget_exceeded':
        return Icons.error_outline_rounded;
      case 'budget_warning':
        return Icons.warning_amber_rounded;
      case 'bill_due':
      case 'bill_overdue':
        return Icons.notifications_active_outlined;
      case 'spending_spike':
        return Icons.trending_up_rounded;
      case 'insight':
        return Icons.auto_awesome;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'budget_exceeded':
      case 'bill_overdue':
        return AppColors.redError;
      case 'budget_warning':
      case 'bill_due':
        return AppColors.orangeWarning;
      case 'spending_spike':
        return AppColors.blueInfo;
      case 'insight':
        return AppColors.teal;
      case 'success':
        return AppColors.emeraldGreen;
      default:
        return AppColors.slateSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getAlertColor(alert.type);
    final icon = _getAlertIcon(alert.type);
    final timeStr = DateFormat('dd MMM, hh:mm a').format(alert.date);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: alert.isRead
          ? (isDark ? AppColors.darkCard : AppColors.whiteCard)
          : (isDark ? AppColors.darkCardElevated : Colors.white),
      border: Border.all(
        color: alert.isRead
            ? (isDark ? AppColors.darkBorder : AppColors.borderLight)
            : color.withOpacity(0.5),
        width: alert.isRead ? 1 : 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: alert.isRead ? FontWeight.w600 : FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                            ),
                          ),
                        ),
                        if (!alert.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.emeraldGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slateLight,
                ),
              ),
              Row(
                children: [
                  if (!alert.isRead && onMarkRead != null)
                    TextButton(
                      onPressed: onMarkRead,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Mark Read', style: TextStyle(fontSize: 12)),
                    ),
                  if (onAction != null && actionText != null)
                    ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(actionText!, style: const TextStyle(fontSize: 12)),
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Dismiss Alert',
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
