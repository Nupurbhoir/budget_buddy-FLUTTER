import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/alert_model.dart';
import '../providers/finance_provider.dart';
import '../services/notification_service.dart';
import '../widgets/alert_card.dart';
import '../widgets/empty_state.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finance = context.watch<FinanceProvider>();
    final alerts = finance.alerts;
    final budgetAlerts = alerts.where((a) => a.type.contains('budget')).toList();
    final billAlerts = alerts.where((a) => a.type.contains('bill')).toList();
    final insightAlerts = alerts.where((a) => a.type == 'insight' || a.type == 'spending_spike' || a.type == 'success').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Test Floating Notification',
            icon: const Icon(Icons.notification_add_outlined),
            onPressed: () {
              NotificationService.show(
                context,
                title: 'Upcoming Bill Due ⏰',
                message: 'Electricity Bill of ₹1,450 is due in 2 days. Tap to review.',
                type: NotificationType.billReminder,
              );
            },
          ),
          if (finance.unreadAlertsCount > 0)
            TextButton.icon(
              onPressed: () {
                finance.markAllAlertsAsRead();
                NotificationService.showSuccess(context, 'Alerts Cleared', 'All notifications marked as read.');
              },
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.emeraldGreen,
                labelColor: isDark ? Colors.white : AppColors.slatePrimary,
                unselectedLabelColor: AppColors.slateSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                tabs: [
                  Tab(text: 'All (${alerts.length})'),
                  Tab(text: 'Budgets (${budgetAlerts.length})'),
                  Tab(text: 'Bills (${billAlerts.length})'),
                  Tab(text: 'Insights (${insightAlerts.length})'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAlertList(context, alerts, finance),
                  _buildAlertList(context, budgetAlerts, finance),
                  _buildAlertList(context, billAlerts, finance),
                  _buildAlertList(context, insightAlerts, finance),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertList(BuildContext context, List<AlertModel> list, FinanceProvider finance) {
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'All caught up!',
        message: 'No active notifications or alerts in this category.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final alert = list[index];
        return AlertCard(
          alert: alert,
          onMarkRead: !alert.isRead ? () => finance.markAlertAsRead(alert.id) : null,
          onDelete: () => finance.deleteAlert(alert.id),
        );
      },
    );
  }
}
