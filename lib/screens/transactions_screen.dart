import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/empty_state.dart';
import 'add_edit_expense_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedType = 'all'; // 'all', 'expense', 'income'
  String _sortBy = 'date_desc'; // 'date_desc', 'date_asc', 'amount_desc', 'amount_asc'
  
  // Advanced Filter state
  String? _selectedPaymentMethod;
  DateTimeRange? _selectedDateRange;
  double? _minAmount;
  double? _maxAmount;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, FinanceProvider finance, TransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this transaction?'),
        content: Text(
          'Are you sure you want to delete "${tx.title}" of ${CurrencyHelper.format(tx.amount)}? All dependent budget and analytics calculations will update immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redError,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              finance.deleteTransaction(tx.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${tx.title}"'),
                  backgroundColor: AppColors.redError,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final minCtrl = TextEditingController(text: _minAmount != null ? _minAmount!.toStringAsFixed(0) : '');
    final maxCtrl = TextEditingController(text: _maxAmount != null ? _maxAmount!.toStringAsFixed(0) : '');
    String? tempMethod = _selectedPaymentMethod;
    DateTimeRange? tempRange = _selectedDateRange;

    final methods = ['All Methods', 'UPI', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Cash', 'Net Banking'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Advanced Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedPaymentMethod = null;
                          _selectedDateRange = null;
                          _minAmount = null;
                          _maxAmount = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset All'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Date Range Filter
                const Text('Date Range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDateRange: tempRange,
                    );
                    if (picked != null) {
                      setModalState(() => tempRange = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.date_range_outlined, size: 20),
                      hintText: 'Select Custom Date Range',
                    ),
                    child: Text(
                      tempRange != null
                          ? '${DateFormat('dd MMM').format(tempRange!.start)} - ${DateFormat('dd MMM yyyy').format(tempRange!.end)}'
                          : 'Any Time Period',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Payment Method
                const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: tempMethod ?? 'All Methods',
                  items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    setModalState(() => tempMethod = val == 'All Methods' ? null : val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Amount Range
                const Text('Amount Range (₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Min ₹', hintText: '0'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max ₹', hintText: '50000'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
                    onPressed: () {
                      setState(() {
                        _selectedPaymentMethod = tempMethod;
                        _selectedDateRange = tempRange;
                        _minAmount = double.tryParse(minCtrl.text.trim());
                        _maxAmount = double.tryParse(maxCtrl.text.trim());
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final finance = context.watch<FinanceProvider>();
    final allCategories = ['All', ...finance.categories.map((c) => c.name)];

    // Filter transactions
    var filtered = finance.transactions.where((t) {
      // Search query
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchesTitle = t.title.toLowerCase().contains(query);
        final matchesCategory = t.category.toLowerCase().contains(query);
        final matchesNotes = t.notes.toLowerCase().contains(query);
        final matchesMethod = t.paymentMethod.toLowerCase().contains(query);
        if (!matchesTitle && !matchesCategory && !matchesNotes && !matchesMethod) {
          return false;
        }
      }

      // Type filter
      if (_selectedType == 'expense' && !t.isExpense) return false;
      if (_selectedType == 'income' && !t.isIncome) return false;

      // Category filter
      if (_selectedCategory != 'All' && t.category != _selectedCategory) {
        return false;
      }

      // Payment Method filter
      if (_selectedPaymentMethod != null && t.paymentMethod != _selectedPaymentMethod) {
        return false;
      }

      // Date Range filter
      if (_selectedDateRange != null) {
        if (t.date.isBefore(_selectedDateRange!.start) ||
            t.date.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Min & Max Amount
      if (_minAmount != null && t.amount < _minAmount!) return false;
      if (_maxAmount != null && t.amount > _maxAmount!) return false;

      return true;
    }).toList();

    // Sort transactions
    if (_sortBy == 'date_desc') {
      filtered.sort((a, b) => b.date.compareTo(a.date));
    } else if (_sortBy == 'date_asc') {
      filtered.sort((a, b) => a.date.compareTo(b.date));
    } else if (_sortBy == 'amount_desc') {
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_sortBy == 'amount_asc') {
      filtered.sort((a, b) => a.amount.compareTo(b.amount));
    }

    final totalSpentFiltered = filtered
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalIncomeFiltered = filtered
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final hasActiveAdvancedFilters =
        _selectedPaymentMethod != null || _selectedDateRange != null || _minAmount != null || _maxAmount != null;

    return Column(
      children: [
        // Top Search & Sort Controls
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
          color: isDark ? AppColors.darkCard : Colors.white,
          child: Column(
            children: [
              // Search Input & Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search payee, merchant, note...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Advanced Filter Button
                  Stack(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => _showFilterBottomSheet(context),
                        icon: const Icon(Icons.filter_list_rounded, size: 20),
                        tooltip: 'Filter Criteria',
                      ),
                      if (hasActiveAdvancedFilters)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.emeraldGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Sort Menu
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardElevated : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                        ),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 20),
                    ),
                    tooltip: 'Sort Options',
                    onSelected: (val) => setState(() => _sortBy = val),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'date_desc',
                        child: Text('Date: Newest First'),
                      ),
                      const PopupMenuItem(
                        value: 'date_asc',
                        child: Text('Date: Oldest First'),
                      ),
                      const PopupMenuItem(
                        value: 'amount_desc',
                        child: Text('Amount: High to Low'),
                      ),
                      const PopupMenuItem(
                        value: 'amount_asc',
                        child: Text('Amount: Low to High'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Type Selector Chips (All, Expense, Income)
              Row(
                children: [
                  _buildTypeChip('all', 'All Transactions'),
                  const SizedBox(width: 8),
                  _buildTypeChip('expense', 'Expenses Only'),
                  const SizedBox(width: 8),
                  _buildTypeChip('income', 'Income Only'),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Category Filter Horizontal Scroll
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: allCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, index) {
                    final cat = allCategories[index];
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextPrimary : AppColors.slateDark),
                      ),
                      selectedColor: AppColors.emeraldGreen,
                      backgroundColor: isDark ? AppColors.darkCardElevated : AppColors.surfaceMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.emeraldGreen
                              : (isDark ? AppColors.darkBorder : AppColors.borderLight),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Filter Summary Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : AppColors.offWhiteBg,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Spent: ${CurrencyHelper.format(totalSpentFiltered)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.redError,
                    ),
                  ),
                  if (totalIncomeFiltered > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• +${CurrencyHelper.format(totalIncomeFiltered)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emeraldGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matching transactions',
                  message: 'Try adjusting your search terms or filters.',
                  actionText: 'Reset Filters',
                  onAction: () {
                    setState(() {
                      _searchController.clear();
                      _selectedCategory = 'All';
                      _selectedType = 'all';
                      _selectedPaymentMethod = null;
                      _selectedDateRange = null;
                      _minAmount = null;
                      _maxAmount = null;
                    });
                  },
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 960 : double.infinity),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (ctx, index) {
                        final tx = filtered[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                            ),
                          ),
                          child: TransactionTile(
                            transaction: tx,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddEditExpenseScreen(transaction: tx),
                                ),
                              );
                            },
                            onDelete: () => _confirmDelete(context, finance, tx),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (type == 'expense'
                  ? AppColors.redError
                  : (type == 'income' ? AppColors.emeraldGreen : AppColors.deepNavy))
              : (isDark ? AppColors.darkCardElevated : AppColors.surfaceMuted),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary),
          ),
        ),
      ),
    );
  }
}
