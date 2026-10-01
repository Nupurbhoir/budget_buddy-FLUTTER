import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/finance_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/add_edit_expense_screen.dart';
import '../screens/alerts_screen.dart';

class ResponsiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final bool showFloatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.body,
    required this.title,
    this.actions,
    this.showFloatingActionButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finance = context.watch<FinanceProvider>();
    final unreadAlerts = finance.unreadAlertsCount;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Desktop Sidebar
            _buildSidebar(context, isDark, finance, unreadAlerts),
            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Desktop Header
                  _buildDesktopHeader(context, isDark, unreadAlerts),
                  // Content with max width constraint
                  Expanded(
                    child: Container(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile & Tablet Scaffold
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        actions: [
          // Notification Bell
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 24),
                tooltip: 'Alerts & Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AlertsScreen()),
                  );
                },
              ),
              if (unreadAlerts > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.redError,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadAlerts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (actions != null) ...actions!,
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildMobileDrawer(context, isDark, finance, unreadAlerts),
      body: body,
      floatingActionButton: showFloatingActionButton
          ? FloatingActionButton(
              backgroundColor: AppColors.emeraldGreen,
              elevation: 4,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
                );
              },
              tooltip: 'Add Transaction',
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex.clamp(0, 4),
        onTap: onNavigationChanged,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline_rounded),
            activeIcon: Icon(Icons.pie_chart_rounded),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            activeIcon: Icon(Icons.insights_rounded),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, bool isDark, int unreadAlerts) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
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
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slatePrimary,
            ),
          ),
          Row(
            children: [
              // Notification Bell with Badge
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, size: 24),
                    tooltip: 'Alerts & Notifications',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AlertsScreen()),
                      );
                    },
                  ),
                  if (unreadAlerts > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.redError,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadAlerts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              // Add Expense CTA
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    bool isDark,
    FinanceProvider finance,
    int unreadAlerts,
  ) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.deepNavy,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo & Branding
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BudgetBuddy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Take control of your money',
                      style: TextStyle(
                        color: AppColors.slateLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: AppSpacing.sm),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sidebarItem(0, 'Dashboard', Icons.grid_view_rounded),
                _sidebarItem(1, 'Transactions', Icons.receipt_long_rounded),
                _sidebarItem(2, 'Budgets', Icons.pie_chart_rounded),
                _sidebarItem(3, 'Analytics', Icons.insights_rounded),
                _sidebarItem(5, 'Recurring Bills', Icons.event_repeat_rounded),
                _sidebarItem(6, 'Savings Challenge', Icons.flag_rounded),
                _sidebarItem(7, 'Categories', Icons.category_outlined),
                _sidebarItem(
                  8,
                  'Alerts',
                  Icons.notifications_active_outlined,
                  badgeCount: unreadAlerts,
                ),
                _sidebarItem(4, 'Settings & Profile', Icons.settings_outlined),
              ],
            ),
          ),
          // User profile snippet & theme toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1E293B), width: 1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.emeraldGreen.withOpacity(0.2),
                  child: const Icon(Icons.person, color: AppColors.emeraldGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        finance.userProfile.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Pro Member',
                        style: TextStyle(
                          color: AppColors.emeraldGreen,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Consumer<ThemeProvider>(
                  builder: (ctx, themeProv, _) => IconButton(
                    icon: Icon(
                      themeProv.isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: AppColors.slateLight,
                      size: 20,
                    ),
                    tooltip: 'Toggle Theme',
                    onPressed: () => themeProv.toggleTheme(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, String label, IconData icon, {int badgeCount = 0}) {
    final isSelected = currentIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.emeraldGreen.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        onTap: () => onNavigationChanged(index),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.emeraldGreen : AppColors.slateLight,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.slateLight,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.redError,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildMobileDrawer(
    BuildContext context,
    bool isDark,
    FinanceProvider finance,
    int unreadAlerts,
  ) {
    return Drawer(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.deepNavy),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppColors.emeraldGreen,
              child: Icon(Icons.person, color: Colors.white, size: 36),
            ),
            accountName: Text(
              finance.userProfile.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            accountEmail: Text(
              finance.userProfile.email,
              style: const TextStyle(color: AppColors.slateLight, fontSize: 12),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_repeat_rounded, color: AppColors.orangeWarning),
            title: const Text('Recurring Bills'),
            subtitle: Text('${finance.activeRecurringBillsCount} active bills'),
            onTap: () {
              Navigator.pop(context);
              onNavigationChanged(5);
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_rounded, color: AppColors.teal),
            title: const Text('Savings Challenge'),
            subtitle: Text('${finance.savingsGoals.length} goals tracking'),
            onTap: () {
              Navigator.pop(context);
              onNavigationChanged(6);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined, color: AppColors.purpleAccent),
            title: const Text('Categories'),
            subtitle: Text('${finance.categories.length} categories configured'),
            onTap: () {
              Navigator.pop(context);
              onNavigationChanged(7);
            },
          ),
          ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.notifications_active_outlined, color: AppColors.emeraldGreen),
                if (unreadAlerts > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.redError,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: const Text('Alerts & Notifications'),
            trailing: unreadAlerts > 0
                ? Chip(
                    label: Text(
                      '$unreadAlerts',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    backgroundColor: AppColors.redError,
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              );
            },
          ),
          const Divider(),
          Consumer<ThemeProvider>(
            builder: (ctx, themeProv, _) => ListTile(
              leading: Icon(
                themeProv.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: AppColors.slateSecondary,
              ),
              title: Text(themeProv.isDarkMode ? 'Light Mode' : 'Dark Mode'),
              trailing: Switch(
                value: themeProv.isDarkMode,
                onChanged: (_) => themeProv.toggleTheme(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
