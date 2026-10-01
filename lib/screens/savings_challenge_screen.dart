import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../models/savings_goal_model.dart';
import '../providers/finance_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/savings_goal_card.dart';

class SavingsChallengeScreen extends StatefulWidget {
  const SavingsChallengeScreen({super.key});

  @override
  State<SavingsChallengeScreen> createState() => _SavingsChallengeScreenState();
}

class _SavingsChallengeScreenState extends State<SavingsChallengeScreen> {
  void _showAddEditGoalDialog(BuildContext context, {SavingsGoalModel? goalToEdit}) {
    final finance = context.read<FinanceProvider>();
    final isEdit = goalToEdit != null;
    final nameController = TextEditingController(text: goalToEdit?.name ?? '');
    final targetController = TextEditingController(
      text: goalToEdit != null ? goalToEdit.targetAmount.toStringAsFixed(0) : '',
    );
    final savedController = TextEditingController(
      text: goalToEdit != null ? goalToEdit.currentSaved.toStringAsFixed(0) : '0',
    );
    String selectedCategory = goalToEdit?.category ?? 'General';
    DateTime selectedTargetDate =
        goalToEdit?.targetDate ?? DateTime.now().add(const Duration(days: 60));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Savings Goal' : 'Create Smart Savings Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    hintText: 'e.g. Emergency Fund, Goa Trip, MacBook',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (₹)',
                    hintText: 'e.g. 20000',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: savedController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Starting Saved Amount (₹)',
                    hintText: 'e.g. 5000',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'General', child: Text('General')),
                    DropdownMenuItem(value: 'Emergency', child: Text('Emergency Fund')),
                    DropdownMenuItem(value: 'Travel', child: Text('Travel & Vacation')),
                    DropdownMenuItem(value: 'Gadgets', child: Text('Gadgets & Electronics')),
                    DropdownMenuItem(value: 'Shopping', child: Text('Shopping & Lifestyle')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedTargetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTargetDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Target Accomplish Date',
                      prefixIcon: Icon(Icons.flag_outlined, size: 18),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(selectedTargetDate),
                    ),
                  ),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
              onPressed: () {
                final name = nameController.text.trim();
                final target = double.tryParse(targetController.text.trim()) ?? 0.0;
                final saved = double.tryParse(savedController.text.trim()) ?? 0.0;
                if (name.isEmpty || target <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid goal details.')),
                  );
                  return;
                }

                if (isEdit) {
                  final updated = goalToEdit.copyWith(
                    name: name,
                    targetAmount: target,
                    currentSaved: saved,
                    category: selectedCategory,
                    targetDate: selectedTargetDate,
                    isCompleted: saved >= target,
                  );
                  finance.updateSavingsGoal(updated);
                } else {
                  final newGoal = SavingsGoalModel(
                    id: const Uuid().v4(),
                    name: name,
                    targetAmount: target,
                    currentSaved: saved,
                    category: selectedCategory,
                    targetDate: selectedTargetDate,
                    isCompleted: saved >= target,
                  );
                  finance.addSavingsGoal(newGoal);
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Goal updated' : 'Savings challenge started!'),
                    backgroundColor: AppColors.teal,
                  ),
                );
              },
              child: Text(isEdit ? 'Save' : 'Start Goal'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(BuildContext context, SavingsGoalModel goal) {
    final depositController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deposit to ${goal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remaining to target: ${CurrencyHelper.format(goal.remainingAmount)}',
              style: const TextStyle(fontSize: 13, color: AppColors.slateSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: depositController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Deposit Amount (₹)',
                hintText: 'e.g. 2000',
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () {
              final amount = double.tryParse(depositController.text.trim()) ?? 0.0;
              if (amount <= 0) return;
              context.read<FinanceProvider>().addSavingsToGoal(goal.id, amount);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added ${CurrencyHelper.format(amount)} to ${goal.name}!'),
                  backgroundColor: AppColors.teal,
                ),
              );
            },
            child: const Text('Deposit'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGoal(BuildContext context, SavingsGoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Savings Goal?'),
        content: Text('Are you sure you want to delete "${goal.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.redError),
            onPressed: () {
              context.read<FinanceProvider>().deleteSavingsGoal(goal.id);
              Navigator.pop(ctx);
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
    final goals = finance.savingsGoals;

    final totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalSaved = goals.fold(0.0, (sum, g) => sum + g.currentSaved);
    final overallPct = totalTarget > 0 ? (totalSaved / totalTarget) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Create CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Savings Challenge',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gamified financial targets with milestone tracking',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditGoalDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Goal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Total Savings Progress Hero Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: isDark ? AppColors.darkCard : AppColors.deepNavy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cumulative Savings Progress',
                      style: TextStyle(color: AppColors.slateLight, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '${(overallPct * 100).toInt()}% Conquered',
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
                      CurrencyHelper.format(totalSaved),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'of ${CurrencyHelper.format(totalTarget)} target',
                      style: const TextStyle(color: AppColors.slateLight, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: overallPct.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick Preset Goals Chips
          Text(
            'Quick Inspiration Challenges',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slateDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip(context, 'Save ₹5,000 for Shopping', 5000, 'Shopping'),
              _buildPresetChip(context, 'Save ₹10,000 for Travel', 10000, 'Travel'),
              _buildPresetChip(context, 'Save ₹20,000 Emergency Fund', 20000, 'Emergency'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Active Goals List
          if (goals.isEmpty)
            EmptyState(
              icon: Icons.flag_outlined,
              title: 'No savings goals set yet',
              message: 'Challenge yourself to save for a vacation, gadget, or rainy day.',
              actionText: 'Create First Goal',
              onAction: () => _showAddEditGoalDialog(context),
            )
          else
            ...goals.map((goal) {
              return SavingsGoalCard(
                goal: goal,
                onAddSavings: () => _showDepositDialog(context, goal),
                onEdit: () => _showAddEditGoalDialog(context, goalToEdit: goal),
                onDelete: () => _confirmDeleteGoal(context, goal),
              );
            }),

          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            text: '+ Create Custom Savings Goal',
            isOutlined: true,
            width: double.infinity,
            onPressed: () => _showAddEditGoalDialog(context),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context, String label, double target, String category) {
    return ActionChip(
      avatar: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.teal),
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      onPressed: () {
        final newGoal = SavingsGoalModel(
          id: const Uuid().v4(),
          name: label.replaceAll('Save ₹', '').replaceAll(' for ', ' - '),
          targetAmount: target,
          currentSaved: 0.0,
          category: category,
          targetDate: DateTime.now().add(const Duration(days: 90)),
        );
        context.read<FinanceProvider>().addSavingsGoal(newGoal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added challenge: $label'),
            backgroundColor: AppColors.teal,
          ),
        );
      },
    );
  }
}
