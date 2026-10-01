import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../providers/finance_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/insight_card.dart';
import '../widgets/primary_button.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _timeRange = 'Month'; // 'Week', 'Month', 'Year'
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final finance = context.watch<FinanceProvider>();
    final now = DateTime.now();

    final totalSpent = finance.currentMonthExpenses;
    final totalIncome = finance.currentMonthIncome;
    final dailyAvg = finance.dailyAverageSpending;
    final remaining = finance.remainingMonthlyBudget;
    final savings = (totalIncome - totalSpent).clamp(0.0, double.infinity);

    // Filter transactions according to selected range
    final filteredTransactions = finance.transactions.where((t) {
      if (!t.isExpense) return false;
      if (_timeRange == 'Week') {
        return t.date.isAfter(now.subtract(const Duration(days: 7)));
      } else if (_timeRange == 'Month') {
        return t.date.year == now.year && t.date.month == now.month;
      } else {
        return t.date.year == now.year;
      }
    }).toList();

    final lineChartCard = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Trajectory',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                ),
              ),
              const Icon(Icons.show_chart_rounded, color: AppColors.emeraldGreen, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cumulative daily expense progression',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 190,
            child: _buildLineChart(finance, isDark),
          ),
        ],
      ),
    );

    final barChartCard = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Breakdown',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                ),
              ),
              const Icon(Icons.bar_chart_rounded, color: AppColors.teal, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Day-by-day distribution for current cycle',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 190,
            child: _buildBarChart(filteredTransactions, isDark),
          ),
        ],
      ),
    );

    final donutChartCard = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Distribution',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                ),
              ),
              const Icon(Icons.donut_large_rounded, color: AppColors.purpleAccent, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Percentage breakdown by spending categories',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 190,
            child: _buildDonutChart(finance, isDark),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildCategoryLegend(finance, isDark),
        ],
      ),
    );

    final incomeExpenseCard = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Income vs Expense Comparison',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                ),
              ),
              const Icon(Icons.compare_arrows_rounded, color: AppColors.emeraldGreen, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cashflow balance and net savings ratio',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 190,
            child: _buildIncomeVsExpenseChart(totalIncome, totalSpent, savings, isDark),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFlowPill('Income', totalIncome, AppColors.emeraldGreen, isDark),
              _buildFlowPill('Expenses', totalSpent, AppColors.redError, isDark),
              _buildFlowPill('Savings', savings, AppColors.teal, isDark),
            ],
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Time Range Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending Analytics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.emeraldGreen),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMMM yyyy').format(now),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Segmented Range Selector
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: ['Week', 'Month', 'Year'].map((range) {
                    final isSelected = _timeRange == range;
                    return InkWell(
                      onTap: () => setState(() => _timeRange = range),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.emeraldGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          range,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextSecondary : AppColors.slateDark),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Key Stat Grid (Responsive: 4 across on desktop, 2x2 on mobile)
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: _buildStatTile('Total Spent', CurrencyHelper.format(totalSpent), AppColors.redError, Icons.arrow_upward_rounded, isDark),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatTile('Daily Average', CurrencyHelper.format(dailyAvg), AppColors.teal, Icons.trending_up_rounded, isDark),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatTile('Net Savings', CurrencyHelper.format(savings), AppColors.emeraldGreen, Icons.savings_outlined, isDark),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatTile('Remaining Budget', CurrencyHelper.format(remaining), AppColors.purpleAccent, Icons.pie_chart_outline_rounded, isDark),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatTile('Total Spent', CurrencyHelper.format(totalSpent), AppColors.redError, Icons.arrow_upward_rounded, isDark),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatTile('Daily Average', CurrencyHelper.format(dailyAvg), AppColors.teal, Icons.trending_up_rounded, isDark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile('Net Savings', CurrencyHelper.format(savings), AppColors.emeraldGreen, Icons.savings_outlined, isDark),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatTile('Remaining Budget', CurrencyHelper.format(remaining), AppColors.purpleAccent, Icons.pie_chart_outline_rounded, isDark),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          // Responsive Charts (2-Column Grid on Desktop, Stacked on Mobile)
          if (isDesktop) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: lineChartCard),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: barChartCard),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: donutChartCard),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: incomeExpenseCard),
              ],
            ),
          ] else ...[
            lineChartCard,
            const SizedBox(height: AppSpacing.lg),
            barChartCard,
            const SizedBox(height: AppSpacing.lg),
            donutChartCard,
            const SizedBox(height: AppSpacing.lg),
            incomeExpenseCard,
          ],
          const SizedBox(height: AppSpacing.lg),

          // Specialist Recommendation Card (from Stitch Screen 2)
          InsightCard(
            title: 'Financial Specialist Recommendation',
            message: finance.generatedInsights.isNotEmpty
                ? finance.generatedInsights.first
                : 'Maintain consistent expense logging to enable automated AI spend forecasting.',
          ),
          const SizedBox(height: AppSpacing.lg),

          // Export Monthly PDF Summary CTA
          PrimaryButton(
            text: 'Download Monthly PDF Summary (Report Export)',
            isOutlined: true,
            width: double.infinity,
            icon: Icons.picture_as_pdf_outlined,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Monthly Report for ${DateFormat('MMMM yyyy').format(now)} generated successfully! Ready for export.',
                  ),
                  backgroundColor: AppColors.emeraldGreen,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowPill(String title, double amount, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(CurrencyHelper.format(amount), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildIncomeVsExpenseChart(double income, double expense, double savings, bool isDark) {
    final maxY = [income, expense, savings].reduce((a, b) => a > b ? a : b);
    final topLimit = maxY > 0 ? (maxY * 1.2) : 10000.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topLimit,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label = group.x == 0 ? 'Income' : (group.x == 1 ? 'Expense' : 'Savings');
              return BarTooltipItem(
                '$label\n${CurrencyHelper.format(rod.toY)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final text = val.toInt() == 0
                    ? 'Income'
                    : (val.toInt() == 1 ? 'Expense' : 'Savings');
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
            strokeWidth: 1,
          ),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: income,
                color: AppColors.emeraldGreen,
                width: 28,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: expense,
                color: AppColors.redError,
                width: 28,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: savings,
                color: AppColors.teal,
                width: 28,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(FinanceProvider finance, bool isDark) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final List<FlSpot> spots = [];

    double cumulative = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      if (day <= now.day) {
        final dayExpenses = finance.currentMonthTransactions
            .where((t) => t.isExpense && t.date.day == day)
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
          horizontalInterval: 10000,
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
              reservedSize: 38,
              interval: 10000,
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
            color: AppColors.emeraldGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.emeraldGreen.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> transactions, bool isDark) {
    final List<double> weekdayTotals = List.filled(7, 0.0);
    for (final tx in transactions) {
      final idx = tx.date.weekday - 1;
      if (idx >= 0 && idx < 7) {
        weekdayTotals[idx] += tx.amount;
      }
    }

    final barGroups = List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: weekdayTotals[i],
            color: weekdayTotals[i] > 2000 ? AppColors.emeraldGreen : AppColors.teal,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
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
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                return Text(
                  days[idx],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonutChart(FinanceProvider finance, bool isDark) {
    final activeCategories = finance.categories.where((c) => c.currentSpent > 0).toList();
    final totalSpent = finance.currentMonthExpenses;

    if (activeCategories.isEmpty || totalSpent == 0) {
      return const Center(child: Text('No expense data available for current cycle.'));
    }

    final sections = activeCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final cat = entry.value;
      final isTouched = index == _touchedPieIndex;
      final radius = isTouched ? 65.0 : 55.0;
      final pct = (cat.currentSpent / totalSpent) * 100;

      return PieChartSectionData(
        color: cat.color,
        value: cat.currentSpent,
        title: '${pct.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedPieIndex = -1;
                return;
              }
              _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 3,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    );
  }

  Widget _buildCategoryLegend(FinanceProvider finance, bool isDark) {
    final activeCategories = finance.categories.where((c) => c.currentSpent > 0).toList()
      ..sort((a, b) => b.currentSpent.compareTo(a.currentSpent));
    final totalSpent = finance.currentMonthExpenses;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: activeCategories.map((cat) {
        final pct = totalSpent > 0 ? ((cat.currentSpent / totalSpent) * 100).toStringAsFixed(0) : '0';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '${cat.name} ($pct%)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextPrimary : AppColors.slateDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
