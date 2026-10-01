import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../models/bill_model.dart';
import '../providers/finance_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/bill_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditBillDialog(BuildContext context, {BillModel? billToEdit}) {
    final finance = context.read<FinanceProvider>();
    final isEdit = billToEdit != null;
    final titleController = TextEditingController(text: billToEdit?.title ?? '');
    final amountController = TextEditingController(
      text: billToEdit != null ? billToEdit.amount.toStringAsFixed(0) : '',
    );
    String selectedCategory = billToEdit?.category ?? 'Bills & Utilities';
    String selectedFrequency = billToEdit?.frequency ?? 'Monthly';
    DateTime selectedDueDate = billToEdit?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    bool reminderEnabled = billToEdit?.reminderEnabled ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Recurring Bill' : 'Add Recurring Bill / Subscription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Title / Provider',
                    hintText: 'e.g. Electricity, JioFiber, Netflix',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    hintText: 'e.g. 2450',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: finance.categories.map((c) {
                    return DropdownMenuItem(value: c.name, child: Text(c.name));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedFrequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'Quarterly', child: Text('Quarterly')),
                    DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedFrequency = val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDueDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDueDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(selectedDueDate),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Send Due Reminders', style: TextStyle(fontSize: 13)),
                    Switch(
                      value: reminderEnabled,
                      activeColor: AppColors.emeraldGreen,
                      onChanged: (val) => setDialogState(() => reminderEnabled = val),
                    ),
                  ],
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
                final title = titleController.text.trim();
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (title.isEmpty || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid bill details.')),
                  );
                  return;
                }

                if (isEdit) {
                  final updated = billToEdit.copyWith(
                    title: title,
                    amount: amount,
                    category: selectedCategory,
                    frequency: selectedFrequency,
                    dueDate: selectedDueDate,
                    reminderEnabled: reminderEnabled,
                  );
                  finance.updateBill(updated);
                } else {
                  final newBill = BillModel(
                    id: const Uuid().v4(),
                    title: title,
                    amount: amount,
                    category: selectedCategory,
                    dueDate: selectedDueDate,
                    frequency: selectedFrequency,
                    reminderEnabled: reminderEnabled,
                  );
                  finance.addBill(newBill);
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Bill updated' : 'Recurring bill added'),
                    backgroundColor: AppColors.emeraldGreen,
                  ),
                );
              },
              child: Text(isEdit ? 'Save' : 'Add Bill'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBill(BuildContext context, BillModel bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bill?'),
        content: Text('Are you sure you want to remove "${bill.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.redError),
            onPressed: () {
              context.read<FinanceProvider>().deleteBill(bill.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bill deleted'), backgroundColor: AppColors.redError),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _payBill(BuildContext context, BillModel bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Bill Payment'),
        content: Text(
          'Mark "${bill.title}" of ${CurrencyHelper.format(bill.amount)} as paid? This will also log an expense transaction in your history.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
            onPressed: () {
              context.read<FinanceProvider>().markBillAsPaid(bill.id, createTransaction: true);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment of ${CurrencyHelper.format(bill.amount)} recorded!'),
                  backgroundColor: AppColors.emeraldGreen,
                ),
              );
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finance = context.watch<FinanceProvider>();
    final upcomingBills = finance.bills.where((b) => !b.isPaid).toList();
    final paidBills = finance.bills.where((b) => b.isPaid).toList();
    final totalCommitment = finance.totalMonthlyBillsCommitment;
    final dueSoonCount = finance.dueSoonBillsCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Add CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recurring Bills',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Subscriptions, utilities, and scheduled expenses',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditBillDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Bill'),
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

          // Total Commitment Card (Deep Navy)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: isDark ? AppColors.darkCard : AppColors.deepNavy,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Monthly Commitment',
                      style: TextStyle(color: AppColors.slateLight, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyHelper.format(totalCommitment),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${upcomingBills.length} Active • $dueSoonCount Due Soon',
                      style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_repeat_rounded,
                    color: AppColors.orangeWarning,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Due Soon Alert Banner
          if (dueSoonCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.orangeWarning),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: AppColors.orangeWarning, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      '$dueSoonCount bill${dueSoonCount == 1 ? '' : 's'} due within the next 3 days! Clear them to avoid disruptions.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Tabs: Upcoming vs Paid
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.emeraldGreen,
              labelColor: isDark ? Colors.white : AppColors.slatePrimary,
              unselectedLabelColor: AppColors.slateSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Upcoming (${upcomingBills.length})'),
                Tab(text: 'Paid History (${paidBills.length})'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Content of Tabs
          AnimatedBuilder(
            animation: _tabController,
            builder: (ctx, _) {
              final isUpcoming = _tabController.index == 0;
              final list = isUpcoming ? upcomingBills : paidBills;

              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: isUpcoming ? 'No upcoming bills' : 'No paid bills yet',
                  message: isUpcoming
                      ? 'You have cleared all scheduled bills for this period.'
                      : 'Bills you mark as paid will appear here.',
                  actionText: isUpcoming ? 'Add New Bill' : null,
                  onAction: isUpcoming ? () => _showAddEditBillDialog(context) : null,
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (ctx, index) {
                  final bill = list[index];
                  return BillCard(
                    bill: bill,
                    onMarkPaid: !bill.isPaid ? () => _payBill(context, bill) : null,
                    onEdit: () => _showAddEditBillDialog(context, billToEdit: bill),
                    onDelete: () => _confirmDeleteBill(context, bill),
                    onToggleReminder: (val) {
                      finance.updateBill(bill.copyWith(reminderEnabled: val));
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            text: '+ Add New Bill / Subscription',
            isOutlined: true,
            width: double.infinity,
            onPressed: () => _showAddEditBillDialog(context),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
