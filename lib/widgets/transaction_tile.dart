import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'transport':
      case 'fuel':
        return Icons.directions_car_outlined;
      case 'bills & utilities':
      case 'bills':
        return Icons.receipt_long_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'healthcare':
      case 'health':
        return Icons.medical_services_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'personal care':
        return Icons.spa_outlined;
      case 'income':
      case 'salary':
        return Icons.arrow_downward_rounded;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    if (transaction.isIncome) return AppColors.emeraldGreen;
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
        return AppColors.emeraldGreen;
      case 'shopping':
        return AppColors.purpleAccent;
      case 'transport':
        return AppColors.blueInfo;
      case 'bills & utilities':
      case 'bills':
        return AppColors.orangeWarning;
      case 'entertainment':
        return const Color(0xFFEC4899);
      case 'healthcare':
      case 'health':
        return AppColors.redError;
      case 'education':
        return AppColors.teal;
      default:
        return AppColors.slateSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _getCategoryColor(transaction.category);
    final iconData = _getCategoryIcon(transaction.category);
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Dismissible(
      key: Key(transaction.id),
      direction: onDelete != null ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.redError,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  iconData,
                  color: catColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Merchant / Title & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          transaction.category,
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
                          transaction.paymentMethod,
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
              // Amount & Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transaction.isIncome ? '+' : '-'}${CurrencyHelper.format(transaction.amount, showDecimals: true)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: transaction.isIncome
                          ? AppColors.emeraldGreen
                          : (isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateFormat.format(transaction.date),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.slateLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
