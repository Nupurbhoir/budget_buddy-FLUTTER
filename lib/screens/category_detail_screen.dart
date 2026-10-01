import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../models/category_model.dart';
import '../providers/finance_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_edit_expense_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final CategoryModel category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finance = context.watch<FinanceProvider>();
    
    // Find updated category from provider state
    final liveCat = finance.categories.firstWhere(
      (c) => c.id == category.id,
      orElse: () => category,
    );

    final catTx = finance.transactions
        .where((t) => t.category.toLowerCase() == liveCat.name.toLowerCase())
        .toList();
    
    final totalSpent = liveCat.currentSpent;
    final limit = liveCat.monthlyLimit;
    final pct = liveCat.percentageUsed;
    final isOver = liveCat.isExceeded;
    final isWarn = liveCat.isWarning;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          liveCat.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Expense in ${liveCat.name}',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditExpenseScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: liveCat.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Icon(liveCat.icon, color: liveCat.color, size: 28),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    liveCat.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${catTx.length} transaction${catTx.length == 1 ? '' : 's'} this cycle',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOver
                                    ? AppColors.redBg
                                    : (isWarn ? AppColors.warningBg : AppColors.greenBg),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                isOver
                                    ? 'Overspent'
                                    : (isWarn ? 'Warning (80%)' : 'On Track'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isOver
                                      ? AppColors.redError
                                      : (isWarn ? AppColors.orangeWarning : AppColors.emeraldDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Spent vs Limit
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Spent',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyHelper.format(totalSpent),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Monthly Limit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyHelper.format(limit),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.slateDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: SizedBox(
                            height: 10,
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              backgroundColor: isDark ? AppColors.darkBorder : AppColors.surfaceMuted,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOver
                                    ? AppColors.redError
                                    : (isWarn ? AppColors.orangeWarning : liveCat.color),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isOver
                                  ? 'Exceeded by ${CurrencyHelper.format(totalSpent - limit)}'
                                  : '${CurrencyHelper.format((limit - totalSpent).clamp(0.0, double.infinity))} remaining',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isOver ? AppColors.redError : AppColors.emeraldDark,
                              ),
                            ),
                            Text(
                              '${(pct * 100).toInt()}% utilized',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Spending Trend Line Chart for this category
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending Trend',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Daily expense progression in ${liveCat.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 160,
                          child: _buildCategoryTrendChart(catTx, liveCat.color, isDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Recent Transactions in this Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transactions (${catTx.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (catTx.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text('No transactions recorded for this category yet.'),
                      ),
                    )
                  else
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: catTx.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, index) {
                          final tx = catTx[index];
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
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTrendChart(List<dynamic> transactions, Color color, bool isDark) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final List<FlSpot> spots = [];

    double cumulative = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      if (day <= now.day) {
        final dayExpenses = transactions
            .where((t) => t.date.day == day)
            .fold(0.0, (sum, t) => sum + t.amount);
        cumulative += dayExpenses;
        spots.add(FlSpot(day.toDouble(), cumulative));
      }
    }

    if (spots.isEmpty) spots.add(const FlSpot(1, 0));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 5,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}d',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slateLight,
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (val, meta) => Text(
                CurrencyHelper.formatCompact(val),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slateLight,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}
