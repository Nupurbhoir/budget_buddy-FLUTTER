import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../models/budget_model.dart';
import '../providers/finance_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/primary_button.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  bool _dismissedBanner = false;

  void _showAddEditBudgetDialog(BuildContext context, {BudgetModel? budgetToEdit}) {
    final finance = context.read<FinanceProvider>();
    final isEdit = budgetToEdit != null;
    final nameController = TextEditingController(text: budgetToEdit?.name ?? '');
    final amountController = TextEditingController(
      text: budgetToEdit != null
          ? budgetToEdit.totalAmount.toStringAsFixed(0)
          : '',
    );
    String? selectedCategoryId = budgetToEdit?.categoryId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Budget' : 'Create Category Budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Name',
                    hintText: 'e.g. Dining Out, Shopping, Fuel',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Limit (₹)',
                    hintText: 'e.g. 10000',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String?>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Link to Category'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Overall Monthly Budget'),
                    ),
                    ...finance.categories.map((c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: (val) {
                    setDialogState(() {
                      selectedCategoryId = val;
                      if (val != null) {
                        final cat = finance.categories.firstWhere((c) => c.id == val);
                        if (nameController.text.isEmpty) {
                          nameController.text = cat.name;
                        }
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
              onPressed: () {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (name.isEmpty || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid name and amount.')),
                  );
                  return;
                }

                final now = DateTime.now();
                final start = DateTime(now.year, now.month, 1);
                final end = DateTime(now.year, now.month + 1, 0);

                if (isEdit) {
                  final updated = budgetToEdit.copyWith(
                    name: name,
                    totalAmount: amount,
                    categoryId: selectedCategoryId,
                  );
                  finance.updateBudget(updated);
                } else {
                  final newBudget = BudgetModel(
                    id: const Uuid().v4(),
                    name: name,
                    categoryId: selectedCategoryId,
                    totalAmount: amount,
                    startDate: start,
                    endDate: end,
                  );
                  finance.addBudget(newBudget);
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Budget updated' : 'Budget created successfully'),
                    backgroundColor: AppColors.emeraldGreen,
                  ),
                );
              },
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBudget(BuildContext context, BudgetModel budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: Text('Are you sure you want to delete the budget "${budget.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.redError),
            onPressed: () {
              context.read<FinanceProvider>().deleteBudget(budget.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Budget deleted'), backgroundColor: AppColors.redError),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finance = context.watch<FinanceProvider>();
    final spent = finance.currentMonthExpenses;
    final total = finance.monthlyBudget;
    final remaining = finance.remainingMonthlyBudget;
    final pct = finance.monthlyBudgetPercentageUsed;
    final pctInt = (pct * 100).toInt();

    // Check for any category exceeding 80%
    final warningBudget = finance.budgets.firstWhere(
      (b) => b.isWarning || b.isExceeded,
      orElse: () => BudgetModel(
        id: '',
        name: '',
        totalAmount: 0,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Create Budget CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Health',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Track spending limits and avoid overdrafts',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditBudgetDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Main Monthly Budget Gauge Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: isDark ? AppColors.darkCard : AppColors.deepNavy,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Monthly Allowance',
                      style: TextStyle(
                        color: AppColors.slateLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '$pctInt% Utilized',
                        style: const TextStyle(
                          color: AppColors.emeraldGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  CurrencyHelper.format(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Circular or linear meter
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: SizedBox(
                    height: 10,
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct >= 1.0
                            ? AppColors.redError
                            : (pct >= 0.8 ? AppColors.orangeWarning : AppColors.emeraldGreen),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spent',
                          style: TextStyle(color: AppColors.slateLight, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyHelper.format(spent),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Remaining',
                          style: TextStyle(color: AppColors.slateLight, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyHelper.format(remaining),
                          style: const TextStyle(
                            color: AppColors.emeraldGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Threshold Limit Reached (Warning Banner from Stitch Screen 4)
          if (warningBudget.name.isNotEmpty && !_dismissedBanner) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: warningBudget.isExceeded ? AppColors.redBg : AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: warningBudget.isExceeded ? AppColors.redError : AppColors.orangeWarning,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: warningBudget.isExceeded
                            ? AppColors.redError
                            : AppColors.orangeWarning,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          warningBudget.isExceeded
                              ? 'Budget Exceeded (Alert)'
                              : 'Threshold Limit Reached (Warning)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: warningBudget.isExceeded
                                ? AppColors.redError
                                : AppColors.orangeWarning,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _dismissedBanner = true),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warningBudget.isExceeded
                        ? 'You have exceeded 100% of your ${warningBudget.name} budget. We recommend reviewing expenses.'
                        : 'You have utilized over 80% of your ${warningBudget.name} budget for this month.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: warningBudget.isExceeded
                              ? AppColors.redError
                              : AppColors.orangeWarning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () =>
                            _showAddEditBudgetDialog(context, budgetToEdit: warningBudget),
                        child: const Text('Review Budget', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        onPressed: () => setState(() => _dismissedBanner = true),
                        child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Category Budgets Header
          Text(
            'Category Budgets',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Category Budgets List
          ...finance.budgets.where((b) => b.categoryId != null).map((budget) {
            return BudgetProgressCard(
              budget: budget,
              onEdit: () => _showAddEditBudgetDialog(context, budgetToEdit: budget),
              onDelete: () => _confirmDeleteBudget(context, budget),
            );
          }),

          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            text: '+ Add New Category Budget',
            isOutlined: true,
            width: double.infinity,
            onPressed: () => _showAddEditBudgetDialog(context),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
