import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../services/notification_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/app_text_field.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final TransactionModel? transaction;
  final String initialType; // 'expense' or 'income'

  const AddEditExpenseScreen({
    super.key,
    this.transaction,
    this.initialType = 'expense',
  });

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late String _type;
  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _paymentMethods = [
    'UPI',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'Cash',
    'Net Banking',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _amountController.text = t.amount.toStringAsFixed(t.amount.truncateToDouble() == t.amount ? 0 : 2);
      _titleController.text = t.title;
      _notesController.text = t.notes;
      _type = t.type;
      _selectedCategory = t.category;
      _selectedPaymentMethod = t.paymentMethod;
      _selectedDate = t.date;
      _selectedTime = TimeOfDay.fromDateTime(t.date);
    } else {
      _type = widget.initialType;
      _selectedCategory = _type == 'income' ? 'Income' : 'Food & Dining';
      _selectedPaymentMethod = 'UPI';
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: AppColors.emeraldGreen,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: AppColors.emeraldGreen,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than zero.')),
      );
      return;
    }

    final fullDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final finance = context.read<FinanceProvider>();

    if (widget.transaction != null) {
      // Edit mode
      final updated = widget.transaction!.copyWith(
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: fullDate,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim(),
        type: _type,
      );
      Navigator.pop(context);
      await finance.updateTransaction(updated);
      if (mounted) {
        NotificationService.showSuccess(
          context,
          'Transaction Updated ✏️',
          'Updated ${_titleController.text.trim()} (${CurrencyHelper.format(amount)})',
        );
      }
    } else {
      // Add mode
      final newTx = TransactionModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: fullDate,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim(),
        type: _type,
      );
      Navigator.pop(context);
      await finance.addTransaction(newTx);

      // Check if this expense pushed category over budget
      final cat = finance.categories.firstWhere((c) => c.name == _selectedCategory, orElse: () => finance.categories.first);
      final budget = finance.budgets.firstWhere((b) => b.categoryId == cat.id, orElse: () => finance.budgets.first);
      if (budget.percentageUsed >= 0.8 && _type == 'expense') {
        NotificationService.showBudgetAlert(context, cat.name, budget.percentageUsed);
      } else {
        NotificationService.showSuccess(
          context,
          'Transaction Recorded 💰',
          'Logged ${CurrencyHelper.format(amount)} for ${_titleController.text.trim()} • Synced to Firebase ☁️',
        );
      }
    }
  }

  void _deleteTransaction() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this transaction?'),
        content: const Text(
          'This action cannot be undone. All related dashboard balances and budget limits will automatically update.',
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
              context.read<FinanceProvider>().deleteTransaction(widget.transaction!.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Go back to transactions list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction deleted'),
                  backgroundColor: AppColors.redError,
                ),
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
    final isEdit = widget.transaction != null;
    final finance = context.watch<FinanceProvider>();

    // Calculate budget impact if expense
    double? categoryLimit;
    double? impactPct;
    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (_type == 'expense' && enteredAmount > 0) {
      final cat = finance.categories.firstWhere(
        (c) => c.name == _selectedCategory,
        orElse: () => finance.categories.first,
      );
      if (cat.monthlyLimit > 0) {
        categoryLimit = cat.monthlyLimit;
        impactPct = (enteredAmount / cat.monthlyLimit) * 100;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Transaction Details' : 'Add Transaction',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.redError),
              tooltip: 'Delete Transaction',
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Type Toggle: Expense vs Income
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _type = 'expense';
                                if (_selectedCategory == 'Income') {
                                  _selectedCategory = 'Food & Dining';
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _type == 'expense'
                                    ? AppColors.redError
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Text(
                                'Expense',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _type == 'expense'
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _type = 'income';
                                _selectedCategory = 'Income';
                              });
                            },
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _type == 'income'
                                    ? AppColors.emeraldGreen
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Text(
                                'Income',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _type == 'income'
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Big Amount Display / Input
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
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
                        Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: _type == 'income'
                                    ? AppColors.emeraldGreen
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: _type == 'income'
                                      ? AppColors.emeraldGreen
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary),
                                ),
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  fillColor: Colors.transparent,
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter an amount';
                                  }
                                  final numVal = double.tryParse(val.trim());
                                  if (numVal == null || numVal <= 0) {
                                    return 'Enter a positive valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Title / Merchant
                  AppTextField(
                    controller: _titleController,
                    label: _type == 'expense' ? 'Expense Title / Merchant' : 'Income Title / Source',
                    hint: _type == 'expense' ? 'e.g. Swiggy Food Delivery, Zara' : 'e.g. Salary, Client Payout',
                    prefixIcon: Icons.edit_note_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Title cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Category Selector
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.slateDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_type == 'income'
                            ? ['Income', 'Investment', 'Refund', 'Freelance', 'Other']
                            : finance.categories.map((c) => c.name).toList())
                        .map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        selectedColor: AppColors.emeraldGreen,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.slateDark),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Date and Time Pickers
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                            ),
                            child: Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Time',
                              prefixIcon: Icon(Icons.access_time_outlined, size: 18),
                            ),
                            child: Text(
                              _selectedTime.format(context),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Payment Method
                  DropdownButtonFormField<String>(
                    value: _selectedPaymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: Icon(Icons.payment_outlined, size: 20),
                    ),
                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPaymentMethod = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes
                  AppTextField(
                    controller: _notesController,
                    label: 'Notes & Reference (Optional)',
                    hint: 'Add any notes, invoice number, or memo',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Dynamic Budget Impact Card (from Stitch Screen 10)
                  if (impactPct != null && categoryLimit != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: impactPct > 100
                            ? AppColors.redBg
                            : (impactPct > 50 ? AppColors.warningBg : AppColors.greenBg),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            impactPct > 100
                                ? Icons.warning_amber_rounded
                                : Icons.pie_chart_outline_rounded,
                            color: impactPct > 100
                                ? AppColors.redError
                                : (impactPct > 50 ? AppColors.orangeWarning : AppColors.emeraldDark),
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Budget Impact Preview',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: impactPct > 100
                                        ? AppColors.redError
                                        : (impactPct > 50 ? AppColors.orangeWarning : AppColors.emeraldDark),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'This expense utilizes ${impactPct.toStringAsFixed(1)}% of your monthly $_selectedCategory budget (${CurrencyHelper.format(categoryLimit)}).',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),

                  // Save Action
                  PrimaryButton(
                    text: isEdit ? 'Save Changes' : 'Save Expense',
                    onPressed: _saveTransaction,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (isEdit)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.redError,
                        side: const BorderSide(color: AppColors.redError),
                      ),
                      onPressed: _deleteTransaction,
                      child: const Text('Delete Expense'),
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
}
