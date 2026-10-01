import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/bill_model.dart';
import '../models/alert_model.dart';

enum NotificationType {
  info,
  success,
  warning,
  error,
  billReminder,
  budgetAlert,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Display a floating interactive in-app notification banner
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    Color iconColor;
    Color bgColor;
    Color borderColor;
    IconData iconData;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case NotificationType.success:
        iconColor = AppColors.emeraldGreen;
        bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
        borderColor = AppColors.emeraldGreen.withValues(alpha: 0.4);
        iconData = Icons.check_circle_rounded;
        break;
      case NotificationType.warning:
      case NotificationType.billReminder:
        iconColor = AppColors.orangeWarning;
        bgColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);
        borderColor = AppColors.orangeWarning.withValues(alpha: 0.4);
        iconData = Icons.notifications_active_rounded;
        break;
      case NotificationType.error:
      case NotificationType.budgetAlert:
        iconColor = AppColors.redError;
        bgColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
        borderColor = AppColors.redError.withValues(alpha: 0.4);
        iconData = Icons.warning_rounded;
        break;
      case NotificationType.info:
      default:
        iconColor = AppColors.teal;
        bgColor = isDark ? const Color(0xFF134E4A) : const Color(0xFFF0FDFA);
        borderColor = AppColors.teal.withValues(alpha: 0.4);
        iconData = Icons.info_rounded;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        content: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: onTap != null
                  ? () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      onTap();
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.deepNavy,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'NOW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: iconColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.chevron_right_rounded, color: iconColor, size: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Convenience helper for Bill Reminders
  static void showBillReminder(BuildContext context, BillModel bill, {VoidCallback? onPayNow}) {
    show(
      context,
      title: 'Bill Due Reminder ⏰',
      message: '${bill.title} (₹${bill.amount.toStringAsFixed(0)}) is ${bill.dueLabel.toLowerCase()}. Tap to pay.',
      type: NotificationType.billReminder,
      onTap: onPayNow,
    );
  }

  /// Convenience helper for Budget Thresholds
  static void showBudgetAlert(BuildContext context, String categoryName, double pct) {
    show(
      context,
      title: pct >= 1.0 ? 'Budget Exceeded! 🚨' : 'Budget Warning (80%) ⚠️',
      message: 'You have consumed ${(pct * 100).toInt()}% of your $categoryName budget.',
      type: NotificationType.budgetAlert,
    );
  }

  /// Convenience helper for Successful actions
  static void showSuccess(BuildContext context, String title, String message) {
    show(
      context,
      title: title,
      message: message,
      type: NotificationType.success,
    );
  }
}
