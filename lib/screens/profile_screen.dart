import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/currency_helper.dart';
import '../providers/finance_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_card.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onLogOut;

  const ProfileScreen({super.key, required this.onLogOut});

  void _showEditProfileDialog(BuildContext context, FinanceProvider finance) {
    final profile = finance.userProfile;
    final nameCtrl = TextEditingController(text: profile.name);
    final emailCtrl = TextEditingController(text: profile.email);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final budgetCtrl = TextEditingController(text: profile.totalMonthlyBudget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile & Budget'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Default Monthly Budget (₹)',
                  prefixText: '₹ ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
            onPressed: () {
              final newBudget = double.tryParse(budgetCtrl.text.trim()) ?? profile.totalMonthlyBudget;
              final updated = profile.copyWith(
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                totalMonthlyBudget: newBudget,
              );
              finance.updateUserProfile(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully'),
                  backgroundColor: AppColors.emeraldGreen,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, FinanceProvider finance) {
    final currencies = [
      {'symbol': '₹', 'name': 'Indian Rupee (INR)'},
      {'symbol': '\$', 'name': 'US Dollar (USD)'},
      {'symbol': '€', 'name': 'Euro (EUR)'},
      {'symbol': '£', 'name': 'British Pound (GBP)'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Display Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((c) {
            final isSel = finance.userProfile.currency == c['symbol'];
            return ListTile(
              leading: Text(
                c['symbol']!,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              title: Text(c['name']!),
              trailing: isSel ? const Icon(Icons.check, color: AppColors.emeraldGreen) : null,
              onTap: () {
                finance.updateUserProfile(finance.userProfile.copyWith(currency: c['symbol']!));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Currency updated to ${c['name']}'),
                    backgroundColor: AppColors.emeraldGreen,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmResetData(BuildContext context, FinanceProvider finance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset to Demo Data?'),
        content: const Text(
          'This will reload the initial sample transactions, budgets, bills, and alerts. Any custom items will be replaced.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orangeWarning),
            onPressed: () {
              finance.resetToDemoData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset to realistic demo dataset'),
                  backgroundColor: AppColors.emeraldGreen,
                ),
              );
            },
            child: const Text('Reset Demo Data'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context, FinanceProvider finance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'Are you sure you want to erase all transactions, bills, and custom budgets? This action is irreversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.redError),
            onPressed: () {
              finance.clearAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All local data cleared'),
                  backgroundColor: AppColors.redError,
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finance = context.watch<FinanceProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final profile = finance.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile & Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // User Card from Stitch Screen 12
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: isDark ? AppColors.darkCard : AppColors.deepNavy,
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.emeraldGreen.withOpacity(0.2),
                      child: const Icon(Icons.person, color: AppColors.emeraldGreen, size: 36),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldGreen,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profile.email,
                            style: const TextStyle(color: AppColors.slateLight, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.phone,
                            style: const TextStyle(color: AppColors.slateLight, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: () => _showEditProfileDialog(context, finance),
                      tooltip: 'Edit Profile',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: Color(0xFF1E293B)),
                const SizedBox(height: AppSpacing.sm),
                // 3 Mini Quick Metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildUserStat('Monthly Limit', CurrencyHelper.format(profile.totalMonthlyBudget)),
                    _buildUserStat('Active Goals', '${finance.savingsGoals.length} Active'),
                    _buildUserStat('Health Score', '88% Optimal'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Firebase Cloud & History Sync Section
          Text(
            'Firebase Cloud & History Sync',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.orangeWarning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.cloud_sync_rounded, color: AppColors.orangeWarning, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Cloud Firestore Sync',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: finance.isFirebaseConnected
                                      ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                                      : AppColors.slateSecondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  finance.isFirebaseConnected ? 'CONNECTED' : 'LOCAL CACHE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: finance.isFirebaseConnected ? AppColors.emeraldGreen : AppColors.slateSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            FirebaseService().currentUser != null
                                ? 'Account: ${FirebaseService().currentUser!.email ?? 'Anonymous'}'
                                : 'Running in offline / local persistent mode',
                            style: const TextStyle(fontSize: 12, color: AppColors.slateSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Last Synced:',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.slateSecondary),
                      ),
                      Text(
                        finance.lastCloudSyncTime != null
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(finance.lastCloudSyncTime!)
                            : 'Pending manual sync',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: finance.isSyncingCloud
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(finance.isSyncingCloud ? 'Syncing to Cloud...' : 'Sync History with Firebase Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    onPressed: finance.isSyncingCloud
                        ? null
                        : () async {
                            final success = await finance.syncWithCloud();
                            if (context.mounted) {
                              if (success) {
                                NotificationService.showSuccess(
                                  context,
                                  'Cloud Synced! ☁️',
                                  'All transactions & history uploaded to Firebase Firestore.',
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(finance.cloudSyncStatus ?? 'Sync status updated.'),
                                    backgroundColor: AppColors.deepNavy,
                                  ),
                                );
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Preferences Section
          Text(
            'Preferences & Notifications',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Bill Due Reminders', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Get notified before bills are overdue', style: TextStyle(fontSize: 12)),
                  value: profile.billAlertsEnabled,
                  activeColor: AppColors.emeraldGreen,
                  onChanged: (val) {
                    finance.updateUserProfile(profile.copyWith(billAlertsEnabled: val));
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Budget Threshold Alerts', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Alert when spending reaches 80% or exceeds 100%', style: TextStyle(fontSize: 12)),
                  value: profile.budgetAlertsEnabled,
                  activeColor: AppColors.emeraldGreen,
                  onChanged: (val) {
                    finance.updateUserProfile(profile.copyWith(budgetAlertsEnabled: val));
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Daily Spending Recap', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Receive end-of-day summary highlights', style: TextStyle(fontSize: 12)),
                  value: profile.dailyRecapEnabled,
                  activeColor: AppColors.emeraldGreen,
                  onChanged: (val) {
                    finance.updateUserProfile(profile.copyWith(dailyRecapEnabled: val));
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Dark Mode Theme', style: TextStyle(fontSize: 14)),
                  subtitle: Text(themeProv.isDarkMode ? 'Currently using dark mode' : 'Currently using light mode', style: const TextStyle(fontSize: 12)),
                  value: themeProv.isDarkMode,
                  activeColor: AppColors.emeraldGreen,
                  onChanged: (_) => themeProv.toggleTheme(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined, color: AppColors.orangeWarning),
                  title: const Text('Test Notification Banner', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Preview how bill reminders and budget alerts appear', style: TextStyle(fontSize: 12)),
                  trailing: OutlinedButton(
                    onPressed: () {
                      NotificationService.show(
                        context,
                        title: 'Budget Alert (85%) ⚠️',
                        message: 'You have consumed ₹12,750 of your ₹15,000 Dining budget.',
                        type: NotificationType.budgetAlert,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Test', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // General Settings
          Text(
            'General & Data Management',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.teal),
                  title: const Text('Display Currency', style: TextStyle(fontSize: 14)),
                  trailing: Text(
                    profile.currency,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onTap: () => _showCurrencyDialog(context, finance),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: AppColors.blueInfo),
                  title: const Text('Export Financial Data (JSON)', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Backup all transactions, bills, and budgets', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    final data = {
                      'transactions': finance.transactions.map((t) => t.toJson()).toList(),
                      'budgets': finance.budgets.map((b) => b.toJson()).toList(),
                      'bills': finance.bills.map((b) => b.toJson()).toList(),
                      'savingsGoals': finance.savingsGoals.map((g) => g.toJson()).toList(),
                    };
                    final jsonStr = jsonEncode(data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Data backup prepared (${jsonStr.length} bytes)!'),
                        backgroundColor: AppColors.emeraldGreen,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded, color: AppColors.orangeWarning),
                  title: const Text('Reset Demo Data', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Reload default realistic sample records', style: TextStyle(fontSize: 12)),
                  onTap: () => _confirmResetData(context, finance),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: AppColors.redError),
                  title: const Text('Clear All Local Data', style: TextStyle(fontSize: 14, color: AppColors.redError)),
                  subtitle: const Text('Permanently remove all local data', style: TextStyle(fontSize: 12)),
                  onTap: () => _confirmClearData(context, finance),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Log Out CTA
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogOut,
              icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.redError),
              label: const Text('Log Out of BudgetBuddy', style: TextStyle(color: AppColors.redError)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.redError),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildUserStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.slateLight,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
