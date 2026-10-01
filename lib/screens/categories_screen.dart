import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../models/category_model.dart';
import '../providers/finance_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_edit_expense_screen.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  CategoryModel? _selectedCategoryForDetail;

  void _showAddCustomCategoryDialog(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    final nameController = TextEditingController();
    final limitController = TextEditingController();
    int selectedColor = 0xFF10B981;
    IconData selectedIcon = Icons.category_rounded;

    final colorOptions = [
      0xFF10B981, // Emerald
      0xFF14B8A6, // Teal
      0xFF3B82F6, // Blue
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
      0xFFF59E0B, // Amber
      0xFFEF4444, // Red
      0xFF06B6D4, // Cyan
    ];

    final iconOptions = [
      {'name': 'food', 'icon': Icons.fastfood_rounded},
      {'name': 'shopping', 'icon': Icons.shopping_bag_rounded},
      {'name': 'transport', 'icon': Icons.commute_rounded},
      {'name': 'entertainment', 'icon': Icons.movie_rounded},
      {'name': 'fitness', 'icon': Icons.fitness_center_rounded},
      {'name': 'travel', 'icon': Icons.flight_takeoff_rounded},
      {'name': 'coffee', 'icon': Icons.coffee_rounded},
      {'name': 'pets', 'icon': Icons.pets_rounded},
      {'name': 'education', 'icon': Icons.school_rounded},
      {'name': 'personal', 'icon': Icons.spa_rounded},
    ];
    String selectedIconName = 'coffee';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Custom Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Pet Care, Coffee & Snacks',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: limitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Budget Limit (₹)',
                    hintText: 'e.g. 5000',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Choose Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colorOptions.map((c) {
                    final isSel = selectedColor == c;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                        child: isSel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Choose Icon', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: iconOptions.map((opt) {
                    final isSel = selectedIconName == opt['name'];
                    final iconData = opt['icon'] as IconData;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedIconName = opt['name'] as String),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.emeraldGreen.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: isSel ? Border.all(color: AppColors.emeraldGreen) : null,
                        ),
                        child: Icon(iconData, color: isSel ? AppColors.emeraldGreen : AppColors.slateSecondary),
                      ),
                    );
                  }).toList(),
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
                final limit = double.tryParse(limitController.text.trim()) ?? 0.0;
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter category name.')),
                  );
                  return;
                }

                final newCat = CategoryModel(
                  id: const Uuid().v4(),
                  name: name,
                  iconName: selectedIconName,
                  colorValue: selectedColor,
                  monthlyLimit: limit,
                  currentSpent: 0.0,
                );

                finance.addCategory(newCat);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "$name" created!'),
                    backgroundColor: AppColors.emeraldGreen,
                  ),
                );
              },
              child: const Text('Create Category'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finance = context.watch<FinanceProvider>();
    final categories = finance.categories;

    if (_selectedCategoryForDetail != null) {
      return _buildCategoryDetailView(context, _selectedCategoryForDetail!, finance, isDark);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Create Category CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${categories.length} Active Categories with Limits',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddCustomCategoryDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Category'),
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

          // Total Overview Pill Card
          AppCard(
            color: isDark ? AppColors.darkCard : AppColors.deepNavy,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Budget Allowance', style: TextStyle(color: AppColors.slateLight, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyHelper.format(finance.monthlyBudget),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Spent', style: TextStyle(color: AppColors.slateLight, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyHelper.format(finance.currentMonthExpenses),
                      style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Category Cards Grid/List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (ctx, index) {
              final cat = categories[index];
              final txCount = finance.transactions.where((t) => t.category == cat.name).length;
              final pct = cat.percentageUsed.clamp(0.0, 1.0);
              final pctInt = (cat.percentageUsed * 100).toInt();

              return AppCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryDetailScreen(category: cat),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$txCount transaction${txCount == 1 ? '' : 's'} recorded',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyHelper.format(cat.currentSpent),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'of ${CurrencyHelper.format(cat.monthlyLimit)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 20, color: AppColors.slateLight),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Progress Bar
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
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildCategoryDetailView(
    BuildContext context,
    CategoryModel category,
    FinanceProvider finance,
    bool isDark,
  ) {
    final catTx = finance.transactions.where((t) => t.category == category.name).toList();
    final totalSpent = category.currentSpent;
    final limit = category.monthlyLimit;
    final pct = category.percentageUsed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedCategoryForDetail = null),
              ),
              const SizedBox(width: 4),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Detail Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Icon(category.icon, color: category.color, size: 26),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category Spending',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                              ),
                            ),
                            Text(
                              CurrencyHelper.format(totalSpent),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: category.isExceeded
                            ? AppColors.redBg
                            : (category.isWarning ? AppColors.warningBg : AppColors.greenBg),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '${(pct * 100).toInt()}% Used',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: category.isExceeded
                              ? AppColors.redError
                              : (category.isWarning ? AppColors.orangeWarning : AppColors.emeraldDark),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: isDark ? AppColors.darkBorder : AppColors.surfaceMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        category.isExceeded
                            ? AppColors.redError
                            : (category.isWarning ? AppColors.orangeWarning : category.color),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.isExceeded
                          ? 'Exceeded by ${CurrencyHelper.format(totalSpent - limit)}'
                          : '${CurrencyHelper.format((limit - totalSpent).clamp(0.0, double.infinity))} remaining',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: category.isExceeded ? AppColors.redError : AppColors.emeraldDark,
                      ),
                    ),
                    Text(
                      'Limit: ${CurrencyHelper.format(limit)}',
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
          const SizedBox(height: AppSpacing.lg),

          // Category Transactions List
          Text(
            'Transactions in ${category.name}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (catTx.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('No transactions recorded for this category yet.'),
              ),
            )
          else
            AppCard(
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
    );
  }
}
