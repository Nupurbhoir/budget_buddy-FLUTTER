import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../models/bill_model.dart';
import '../providers/finance_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/insight_card.dart';
import '../widgets/empty_state.dart';
import 'add_edit_expense_screen.dart';
import 'category_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final finance = context.watch<FinanceProvider>();
    final profile = finance.userProfile;
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, d MMM').format(now);

    final dueBills = finance.bills
        .where((b) => !b.isPaid && (b.dynamicStatus == 'due_soon' || b.dynamicStatus == 'overdue'))
        .toList();

    // Top Header Widget
    final headerWidget = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, ${profile.name.split(' ').first} 👋',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.emeraldGreen.withOpacity(0.15),
          child: const Icon(Icons.person, color: AppColors.emeraldGreen, size: 22),
        ),
      ],
    );

    // Left Column Content
    final leftColumnWidgets = [
      _buildBalanceCard(context, finance),
      const SizedBox(height: AppSpacing.lg),
      _buildQuickActions(context),
      const SizedBox(height: AppSpacing.lg),
      _buildMonthlyBudgetCard(context, finance, isDark),
      const SizedBox(height: AppSpacing.lg),
      _buildRecentTransactionsSection(context, finance, isDark),
    ];

    // Right Column Content
    final rightColumnWidgets = [
      if (dueBills.isNotEmpty) ...[
        _buildDueBillsBanner(context, dueBills.first, isDark),
        const SizedBox(height: AppSpacing.lg),
      ],
      _buildSpendingSnapshot(context, finance, isDark),
      const SizedBox(height: AppSpacing.lg),
      if (finance.generatedInsights.isNotEmpty) ...[
        InsightCard(
          message: finance.generatedInsights.first,
          actionLabel: 'View Detailed Analytics',
          onAction: () => onNavigateTab(3), // Switch to Analytics
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      _buildSavingsChallengeWidget(context, finance, isDark),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerWidget,
          const SizedBox(height: AppSpacing.md),

          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: leftColumnWidgets,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 45,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rightColumnWidgets,
                  ),
                ),
              ],
            )
          else ...[
            ...leftColumnWidgets,
            const SizedBox(height: AppSpacing.lg),
            ...rightColumnWidgets,
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildDueBillsBanner(BuildContext context, BillModel bill, bool isDark) {
    final isOverdue = bill.dynamicStatus == 'overdue';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isOverdue ? AppColors.redBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isOverdue ? AppColors.redError : AppColors.orangeWarning,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isOverdue ? AppColors.redError : AppColors.orangeWarning).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: isOverdue ? AppColors.redError : AppColors.orangeWarning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bill.title} is ${bill.dueLabel.toLowerCase()}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOverdue ? AppColors.redError : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Amount: ${CurrencyHelper.format(bill.amount)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? AppColors.redError : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isOverdue ? AppColors.redError : AppColors.orangeWarning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => onNavigateTab(5), // Switch to Recurring Bills
            child: const Text('Pay Now', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsChallengeWidget(
    BuildContext context,
    FinanceProvider finance,
    bool isDark,
  ) {
    if (finance.savingsGoals.isEmpty) return const SizedBox.shrink();
    final topGoal = finance.savingsGoals.first;
    final pct = topGoal.progressPercentage;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, color: AppColors.teal, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Active Savings Challenge',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => onNavigateTab(6), // Switch to Savings Challenge
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  topGoal.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.slateDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(pct * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.surfaceMuted,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Saved: ${CurrencyHelper.format(topGoal.currentSaved)} of ${CurrencyHelper.format(topGoal.targetAmount)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  topGoal.motivationalInsight,
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.teal),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
    BuildContext context,
    FinanceProvider finance,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
              ),
            ),
            TextButton(
              onPressed: () => onNavigateTab(1), // Switch to Transactions
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (finance.transactions.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            message: 'Start tracking your spending by adding your first expense.',
            actionText: 'Add Expense',
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
              );
            },
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: finance.transactions.take(5).length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, index) {
                final tx = finance.transactions[index];
                return TransactionTile(
                  transaction: tx,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditExpenseScreen(transaction: tx),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, FinanceProvider finance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavy.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  color: AppColors.slateLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.emeraldGreen, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Live Balance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            CurrencyHelper.format(finance.totalBalance, showDecimals: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Income & Expense Breakdown Chips
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          color: AppColors.emeraldGreen,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Income',
                              style: TextStyle(color: AppColors.slateLight, fontSize: 11),
                            ),
                            Text(
                              '+${CurrencyHelper.format(finance.totalIncome)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.redError.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: AppColors.redError,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Expenses',
                              style: TextStyle(color: AppColors.slateLight, fontSize: 11),
                            ),
                            Text(
                              '-${CurrencyHelper.format(finance.totalExpenses)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionBtn(
          context,
          icon: Icons.add,
          color: AppColors.emeraldGreen,
          label: 'Add Expense',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddEditExpenseScreen(initialType: 'expense'),
              ),
            );
          },
        ),
        _buildActionBtn(
          context,
          icon: Icons.south_west_rounded,
          color: AppColors.teal,
          label: 'Add Income',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddEditExpenseScreen(initialType: 'income'),
              ),
            );
          },
        ),
        _buildActionBtn(
          context,
          icon: Icons.pie_chart_rounded,
          color: AppColors.purpleAccent,
          label: 'Set Budget',
          onTap: () => onNavigateTab(2), // Switch to Budgets
        ),
        _buildActionBtn(
          context,
          icon: Icons.receipt_long_rounded,
          color: AppColors.orangeWarning,
          label: 'Add Bill',
          onTap: () => onNavigateTab(5), // Switch to Recurring Bills
        ),
      ],
    );
  }

  Widget _buildActionBtn(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBudgetCard(
    BuildContext context,
    FinanceProvider finance,
    bool isDark,
  ) {
    final spent = finance.currentMonthExpenses;
    final total = finance.monthlyBudget;
    final remaining = finance.remainingMonthlyBudget;
    final pct = finance.monthlyBudgetPercentageUsed;
    final pctInt = (pct * 100).toInt();

    final isWarning = pct >= 0.8 && pct < 1.0;
    final isExceeded = pct >= 1.0;

    final progressColor = isExceeded
        ? AppColors.redError
        : (isWarning ? AppColors.orangeWarning : AppColors.emeraldGreen);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Budget',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isExceeded
                      ? AppColors.redBg
                      : (isWarning ? AppColors.warningBg : AppColors.greenBg),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$pctInt% used',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isExceeded
                        ? AppColors.redError
                        : (isWarning ? AppColors.orangeWarning : AppColors.emeraldDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyHelper.format(spent),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                ),
              ),
              Text(
                'of ${CurrencyHelper.format(total)} limit',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
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
                isExceeded
                    ? 'Over budget by ${CurrencyHelper.format(spent - total)}'
                    : '${CurrencyHelper.format(remaining)} remaining',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isExceeded
                      ? AppColors.redError
                      : (isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary),
                ),
              ),
              TextButton(
                onPressed: () => onNavigateTab(2),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Adjust Budget', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingSnapshot(
    BuildContext context,
    FinanceProvider finance,
    bool isDark,
  ) {
    final topCategories = finance.categories
        .where((c) => c.currentSpent > 0)
        .toList()
      ..sort((a, b) => b.currentSpent.compareTo(a.currentSpent));

    if (topCategories.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Snapshot',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                ),
              ),
              TextButton(
                onPressed: () => onNavigateTab(7), // Categories
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Manage Categories', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...topCategories.take(4).map((cat) {
            final pct = cat.percentageUsed.clamp(0.0, 1.0);
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryDetailScreen(category: cat),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(cat.icon, size: 16, color: cat.color),
                            const SizedBox(width: 8),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.slateDark,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '${CurrencyHelper.format(cat.currentSpent)} / ${CurrencyHelper.format(cat.monthlyLimit)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 16, color: AppColors.slateLight),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: SizedBox(
                        height: 6,
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: isDark ? AppColors.darkBorder : AppColors.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            cat.isExceeded
                                ? AppColors.redError
                                : (cat.isWarning ? AppColors.orangeWarning : cat.color),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
