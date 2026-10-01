import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';
import '../models/bill_model.dart';
import '../models/alert_model.dart';
import '../models/savings_goal_model.dart';
import '../models/user_profile_model.dart';
import '../services/storage_service.dart';
import '../services/demo_data.dart';
import '../services/firebase_service.dart';

class FinanceProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  List<BudgetModel> _budgets = [];
  List<BillModel> _bills = [];
  List<AlertModel> _alerts = [];
  List<SavingsGoalModel> _savingsGoals = [];
  UserProfileModel _userProfile = DemoData.userProfile;

  bool _isLoading = true;
  DateTime? _lastCloudSyncTime;
  bool _isSyncingCloud = false;
  String? _cloudSyncStatus;

  FinanceProvider(this._storage) {
    _initializeData();
  }

  bool get isLoading => _isLoading;

  // Getters
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<BudgetModel> get budgets => List.unmodifiable(_budgets);
  List<BillModel> get bills => List.unmodifiable(_bills);
  List<AlertModel> get alerts => List.unmodifiable(_alerts);
  List<SavingsGoalModel> get savingsGoals => List.unmodifiable(_savingsGoals);
  UserProfileModel get userProfile => _userProfile;
  DateTime? get lastCloudSyncTime => _lastCloudSyncTime;
  bool get isSyncingCloud => _isSyncingCloud;
  String? get cloudSyncStatus => _cloudSyncStatus;
  bool get isFirebaseConnected => FirebaseService().isInitialized;

  // Initialization & Seeding
  Future<void> _initializeData() async {
    _isLoading = true;
    notifyListeners();

    if (!_storage.hasInitialized) {
      // First time launch -> seed with realistic demo data
      _transactions = DemoData.transactions;
      _categories = DemoData.categories;
      _budgets = DemoData.budgets;
      _bills = DemoData.bills;
      _alerts = DemoData.alerts;
      _savingsGoals = DemoData.savingsGoals;
      _userProfile = DemoData.userProfile;

      await _persistAll();
      await _storage.setHasInitialized(true);
    } else {
      _transactions = _storage.loadTransactions() ?? DemoData.transactions;
      _categories = _storage.loadCategories() ?? DemoData.categories;
      _budgets = _storage.loadBudgets() ?? DemoData.budgets;
      _bills = _storage.loadBills() ?? DemoData.bills;
      _alerts = _storage.loadAlerts() ?? DemoData.alerts;
      _savingsGoals = _storage.loadSavingsGoals() ?? DemoData.savingsGoals;
      _userProfile = _storage.loadUserProfile() ?? DemoData.userProfile;
    }

    _recalculateAll();
    _isLoading = false;
    notifyListeners();

    // Ensure Firebase user authentication is connected
    FirebaseService().ensureUser().then((_) {
      syncWithCloud();
    });
  }

  // --- Dynamic Financial Calculations ---

  double get totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpenses {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalBalance {
    return totalIncome - totalExpenses;
  }

  // Current Month calculations
  List<TransactionModel> get currentMonthTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();
  }

  double get currentMonthExpenses {
    return currentMonthTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get currentMonthIncome {
    return currentMonthTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyBudget {
    final overall = _budgets.firstWhere(
      (b) => b.categoryId == null,
      orElse: () => BudgetModel(
        id: 'default_monthly',
        name: 'Overall Monthly Budget',
        totalAmount: _userProfile.totalMonthlyBudget,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      ),
    );
    return overall.totalAmount;
  }

  double get remainingMonthlyBudget {
    return (monthlyBudget - currentMonthExpenses).clamp(0.0, double.infinity);
  }

  double get monthlyBudgetPercentageUsed {
    return monthlyBudget > 0 ? (currentMonthExpenses / monthlyBudget) : 0.0;
  }

  double get dailyAverageSpending {
    final now = DateTime.now();
    final day = now.day > 0 ? now.day : 1;
    return currentMonthExpenses / day;
  }

  int get unreadAlertsCount {
    return _alerts.where((a) => !a.isRead).length;
  }

  int get activeRecurringBillsCount {
    return _bills.where((b) => !b.isPaid).length;
  }

  int get dueSoonBillsCount {
    return _bills.where((b) => b.dynamicStatus == 'due_soon' || b.dynamicStatus == 'overdue').length;
  }

  double get totalMonthlyBillsCommitment {
    return _bills
        .where((b) => !b.isPaid)
        .fold(0.0, (sum, b) => sum + b.amount);
  }

  CategoryModel? get highestSpendingCategory {
    CategoryModel? highest;
    double maxSpent = -1;
    for (final cat in _categories) {
      if (cat.currentSpent > maxSpent && cat.currentSpent > 0) {
        maxSpent = cat.currentSpent;
        highest = cat;
      }
    }
    return highest;
  }

  CategoryModel? get lowestSpendingCategory {
    CategoryModel? lowest;
    double minSpent = double.infinity;
    for (final cat in _categories) {
      if (cat.currentSpent > 0 && cat.currentSpent < minSpent) {
        minSpent = cat.currentSpent;
        lowest = cat;
      }
    }
    return lowest;
  }

  // --- Dynamic Insights ---
  List<String> get generatedInsights {
    final insights = <String>[];
    final now = DateTime.now();

    if (_transactions.isEmpty) {
      insights.add('Keep adding transactions to unlock personalized insights.');
      return insights;
    }

    // 1. Highest category insight
    final highest = highestSpendingCategory;
    if (highest != null && currentMonthExpenses > 0) {
      final pct = ((highest.currentSpent / currentMonthExpenses) * 100).toStringAsFixed(0);
      insights.add(
        '${highest.name} is your highest spending category, accounting for $pct% of your total expenses this month.',
      );
    }

    // 2. Budget trajectory insight
    final rem = remainingMonthlyBudget;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;
    if (daysLeft > 0) {
      final safeDaily = (rem / daysLeft).toStringAsFixed(0);
      insights.add(
        'You have ₹${rem.toStringAsFixed(0)} remaining for the next $daysLeft days. Daily safe limit: ₹$safeDaily.',
      );
    }

    // 3. Weekly comparison insight
    final last7DaysExpenses = _transactions.where((t) {
      return t.isExpense &&
          t.date.isAfter(now.subtract(const Duration(days: 7))) &&
          t.date.isBefore(now);
    }).fold(0.0, (sum, t) => sum + t.amount);

    final previous7DaysExpenses = _transactions.where((t) {
      return t.isExpense &&
          t.date.isAfter(now.subtract(const Duration(days: 14))) &&
          t.date.isBefore(now.subtract(const Duration(days: 7)));
    }).fold(0.0, (sum, t) => sum + t.amount);

    if (previous7DaysExpenses > 0) {
      final diff = ((last7DaysExpenses - previous7DaysExpenses) / previous7DaysExpenses) * 100;
      if (diff > 0) {
        insights.add(
          'Your spending this week is ${diff.toStringAsFixed(0)}% higher than the previous week.',
        );
      } else {
        insights.add(
          'Great discipline! Your spending is ${(-diff).toStringAsFixed(0)}% lower than last week.',
        );
      }
    }

    // 4. Weekend spending insight
    double weekendExpenses = 0.0;
    double weekdayExpenses = 0.0;
    for (final t in currentMonthTransactions.where((t) => t.isExpense)) {
      if (t.date.weekday == DateTime.saturday || t.date.weekday == DateTime.sunday) {
        weekendExpenses += t.amount;
      } else {
        weekdayExpenses += t.amount;
      }
    }
    if (weekendExpenses + weekdayExpenses > 0) {
      final weekendPct = ((weekendExpenses / (weekendExpenses + weekdayExpenses)) * 100).round();
      if (weekendPct > 35) {
        insights.add(
          'Weekend surge: $weekendPct% of your monthly expenditure occurs on Saturdays and Sundays.',
        );
      }
    }

    // 5. Bill reminders
    final dueSoon = _bills.where((b) => b.dynamicStatus == 'due_soon').toList();
    if (dueSoon.isNotEmpty) {
      insights.add(
        'Reminder: ${dueSoon.first.title} is ${dueSoon.first.dueLabel.toLowerCase()}. Avoid penalty by clearing it early.',
      );
    }

    return insights;
  }

  // --- Recalculation Engine ---
  void _recalculateAll() {
    final now = DateTime.now();

    // 1. Recalculate spending per category based on actual transactions this month
    final Map<String, double> categorySpendingMap = {};
    for (final tx in _transactions) {
      if (tx.isExpense && tx.date.year == now.year && tx.date.month == now.month) {
        categorySpendingMap[tx.category] =
            (categorySpendingMap[tx.category] ?? 0.0) + tx.amount;
      }
    }

    _categories = _categories.map((cat) {
      final spent = categorySpendingMap[cat.name] ?? 0.0;
      return cat.copyWith(currentSpent: spent);
    }).toList();

    // 2. Recalculate Budgets
    final totalSpentThisMonth = currentMonthExpenses;
    _budgets = _budgets.map((b) {
      if (b.categoryId == null) {
        // overall budget
        return b.copyWith(spentAmount: totalSpentThisMonth);
      } else {
        final cat = _categories.firstWhere(
          (c) => c.id == b.categoryId,
          orElse: () => CategoryModel(
            id: '',
            name: b.name,
            iconName: 'other',
            colorValue: 0,
          ),
        );
        return b.copyWith(spentAmount: cat.currentSpent);
      }
    }).toList();
  }

  // --- Alert Generation Logic ---
  void _checkAndGenerateAlerts(TransactionModel? newOrUpdatedTx) {
    final now = DateTime.now();

    // 1. Check if any category crossed threshold
    for (final cat in _categories) {
      if (cat.monthlyLimit > 0) {
        if (cat.isExceeded) {
          final existing = _alerts.any((a) =>
              a.type == 'budget_exceeded' &&
              a.relatedId == cat.id &&
              a.date.year == now.year &&
              a.date.month == now.month);
          if (!existing) {
            _alerts.insert(
              0,
              AlertModel(
                id: _uuid.v4(),
                title: 'Budget Exceeded: ${cat.name}',
                description:
                    'You have spent ₹${cat.currentSpent.toStringAsFixed(0)} of your ₹${cat.monthlyLimit.toStringAsFixed(0)} limit for ${cat.name}.',
                type: 'budget_exceeded',
                date: now,
                relatedId: cat.id,
              ),
            );
          }
        } else if (cat.isWarning) {
          final existing = _alerts.any((a) =>
              a.type == 'budget_warning' &&
              a.relatedId == cat.id &&
              a.date.year == now.year &&
              a.date.month == now.month);
          if (!existing) {
            _alerts.insert(
              0,
              AlertModel(
                id: _uuid.v4(),
                title: 'Threshold Reached (80%): ${cat.name}',
                description:
                    'You have utilized ${(cat.percentageUsed * 100).toStringAsFixed(0)}% of your ${cat.name} budget.',
                type: 'budget_warning',
                date: now,
                relatedId: cat.id,
              ),
            );
          }
        }
      }
    }

    // 2. Check if a high spending spike occurred
    if (newOrUpdatedTx != null && newOrUpdatedTx.isExpense) {
      final avg = dailyAverageSpending;
      if (avg > 0 && newOrUpdatedTx.amount > (avg * 2.5) && newOrUpdatedTx.amount >= 2000) {
        _alerts.insert(
          0,
          AlertModel(
            id: _uuid.v4(),
            title: 'High Spending Detected',
            description:
                '₹${newOrUpdatedTx.amount.toStringAsFixed(0)} spent on "${newOrUpdatedTx.title}". This is significantly above your daily average.',
            type: 'spending_spike',
            date: now,
          ),
        );
      }
    }

    // 3. Check for due bills
    for (final bill in _bills) {
      if (!bill.isPaid && (bill.dynamicStatus == 'due_soon' || bill.dynamicStatus == 'overdue')) {
        final existing = _alerts.any((a) => a.relatedId == bill.id && !a.isRead);
        if (!existing && bill.reminderEnabled) {
          _alerts.insert(
            0,
            AlertModel(
              id: _uuid.v4(),
              title: '${bill.title} is ${bill.dueLabel}',
              description:
                  'Amount: ₹${bill.amount.toStringAsFixed(0)}. Ensure timely payment to maintain good financial health.',
              type: bill.dynamicStatus == 'overdue' ? 'bill_overdue' : 'bill_due',
              date: now,
              relatedId: bill.id,
            ),
          );
        }
      }
    }
  }

  // --- CRUD: Transactions ---
  Future<void> addTransaction(TransactionModel tx) async {
    _transactions.insert(0, tx);
    _recalculateAll();
    _checkAndGenerateAlerts(tx);
    await _storage.saveTransactions(_transactions);
    await _storage.saveCategories(_categories);
    await _storage.saveBudgets(_budgets);
    await _storage.saveAlerts(_alerts);

    // Real-time Cloud Firestore Persistence (both Root 'transactions' and User subcollection)
    await FirebaseService().saveTransaction(tx);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final idx = _transactions.indexWhere((t) => t.id == tx.id);
    if (idx != -1) {
      _transactions[idx] = tx;
      _recalculateAll();
      _checkAndGenerateAlerts(tx);
      await _storage.saveTransactions(_transactions);
      await _storage.saveCategories(_categories);
      await _storage.saveBudgets(_budgets);
      await _storage.saveAlerts(_alerts);

      // Real-time Cloud Firestore Update
      await FirebaseService().saveTransaction(tx);
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    _recalculateAll();
    await _storage.saveTransactions(_transactions);
    await _storage.saveCategories(_categories);
    await _storage.saveBudgets(_budgets);

    // Real-time Cloud Firestore Deletion
    await FirebaseService().deleteTransaction(id);
    notifyListeners();
  }

  // --- Cloud Sync ---
  Future<bool> syncWithCloud() async {
    var user = FirebaseService().currentUser;
    if (user == null) {
      // Auto-connect with Firebase Auth so sync immediately works
      try {
        final email = _userProfile.email.isNotEmpty ? _userProfile.email : 'demo@budgetbuddy.app';
        final cred = await FirebaseService().signInOrCreate(
          email: email,
          password: 'Password123!',
          displayName: _userProfile.name,
        );
        user = cred?.user;
      } catch (_) {
        try {
          final cred = await FirebaseService().signInAnonymously();
          user = cred?.user;
        } catch (_) {}
      }
    }

    if (user == null) {
      _cloudSyncStatus = 'Please check internet or Firebase connection.';
      notifyListeners();
      return false;
    }

    _isSyncingCloud = true;
    _cloudSyncStatus = 'Syncing data to Firebase Firestore...';
    notifyListeners();

    try {
      final success = await FirebaseService().syncAllToCloud(
        userId: user.uid,
        transactions: _transactions,
        budgets: _budgets,
        bills: _bills,
        savingsGoals: _savingsGoals,
      );

      // Merge remote transactions if any
      final cloudData = await FirebaseService().pullCloudData(user.uid);
      if (cloudData != null && cloudData['transactions'] != null) {
        final List<TransactionModel> cloudTx = List<TransactionModel>.from(cloudData['transactions']);
        final existingIds = _transactions.map((t) => t.id).toSet();
        for (final remote in cloudTx) {
          if (!existingIds.contains(remote.id)) {
            _transactions.add(remote);
          }
        }
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        _recalculateAll();
        await _persistAll();
      }

      _isSyncingCloud = false;
      if (success) {
        _lastCloudSyncTime = DateTime.now();
        _cloudSyncStatus = 'Successfully synced with Cloud Firestore!';
      } else {
        _cloudSyncStatus = 'Sync completed with local persistence.';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _isSyncingCloud = false;
      _cloudSyncStatus = 'Sync notice: $e';
      notifyListeners();
      return false;
    }
  }

  // --- CRUD: Categories ---
  Future<void> addCategory(CategoryModel cat) async {
    _categories.add(cat);
    _recalculateAll();
    await _storage.saveCategories(_categories);
    await FirebaseService().saveCategory(cat);
    notifyListeners();
  }

  Future<void> updateCategory(CategoryModel cat) async {
    final idx = _categories.indexWhere((c) => c.id == cat.id);
    if (idx != -1) {
      _categories[idx] = cat;
      _recalculateAll();
      await _storage.saveCategories(_categories);
      await FirebaseService().saveCategory(cat);
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    _recalculateAll();
    await _storage.saveCategories(_categories);
    await FirebaseService().deleteCategory(id);
    notifyListeners();
  }

  // --- CRUD: Budgets ---
  Future<void> addBudget(BudgetModel budget) async {
    _budgets.add(budget);
    _recalculateAll();
    await _storage.saveBudgets(_budgets);
    await FirebaseService().saveBudget(budget);
    notifyListeners();
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final idx = _budgets.indexWhere((b) => b.id == budget.id);
    if (idx != -1) {
      _budgets[idx] = budget;
      _recalculateAll();
      await _storage.saveBudgets(_budgets);
      await FirebaseService().saveBudget(budget);
      notifyListeners();
    }
  }

  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((b) => b.id == id);
    await _storage.saveBudgets(_budgets);
    await FirebaseService().deleteBudget(id);
    notifyListeners();
  }

  // --- CRUD: Bills ---
  Future<void> addBill(BillModel bill) async {
    _bills.insert(0, bill);
    _checkAndGenerateAlerts(null);
    await _storage.saveBills(_bills);
    await _storage.saveAlerts(_alerts);
    await FirebaseService().saveBill(bill);
    notifyListeners();
  }

  Future<void> updateBill(BillModel bill) async {
    final idx = _bills.indexWhere((b) => b.id == bill.id);
    if (idx != -1) {
      _bills[idx] = bill;
      await _storage.saveBills(_bills);
      await FirebaseService().saveBill(bill);
      notifyListeners();
    }
  }

  Future<void> deleteBill(String id) async {
    _bills.removeWhere((b) => b.id == id);
    await _storage.saveBills(_bills);
    await FirebaseService().deleteBill(id);
    notifyListeners();
  }

  Future<void> markBillAsPaid(String billId, {bool createTransaction = true}) async {
    final idx = _bills.indexWhere((b) => b.id == billId);
    if (idx != -1) {
      final bill = _bills[idx];
      _bills[idx] = bill.copyWith(
        status: 'paid',
        paidDate: DateTime.now(),
      );

      if (createTransaction) {
        final tx = TransactionModel(
          id: _uuid.v4(),
          title: 'Bill: ${bill.title}',
          amount: bill.amount,
          category: bill.category,
          date: DateTime.now(),
          paymentMethod: 'UPI',
          notes: 'Paid recurring bill',
          type: 'expense',
        );
        _transactions.insert(0, tx);
        _recalculateAll();
        await _storage.saveTransactions(_transactions);
        await FirebaseService().saveTransaction(tx);
      }

      // Add success alert
      _alerts.insert(
        0,
        AlertModel(
          id: _uuid.v4(),
          title: 'Bill Paid Successfully',
          description: 'Payment of ₹${bill.amount.toStringAsFixed(0)} for ${bill.title} was recorded.',
          type: 'success',
          date: DateTime.now(),
        ),
      );

      await _storage.saveBills(_bills);
      await _storage.saveAlerts(_alerts);
      await FirebaseService().saveBill(_bills[idx]);
      notifyListeners();
    }
  }

  // --- CRUD: Alerts ---
  Future<void> markAlertAsRead(String id) async {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _alerts[idx] = _alerts[idx].copyWith(isRead: true);
      await _storage.saveAlerts(_alerts);
      notifyListeners();
    }
  }

  Future<void> markAllAlertsAsRead() async {
    _alerts = _alerts.map((a) => a.copyWith(isRead: true)).toList();
    await _storage.saveAlerts(_alerts);
    notifyListeners();
  }

  Future<void> deleteAlert(String id) async {
    _alerts.removeWhere((a) => a.id == id);
    await _storage.saveAlerts(_alerts);
    notifyListeners();
  }

  // --- CRUD: Savings Goals ---
  Future<void> addSavingsGoal(SavingsGoalModel goal) async {
    _savingsGoals.add(goal);
    await _storage.saveSavingsGoals(_savingsGoals);
    await FirebaseService().saveSavingsGoal(goal);
    notifyListeners();
  }

  Future<void> addSavingsToGoal(String goalId, double amount) async {
    final idx = _savingsGoals.indexWhere((g) => g.id == goalId);
    if (idx != -1) {
      final goal = _savingsGoals[idx];
      final newSaved = goal.currentSaved + amount;
      final completed = newSaved >= goal.targetAmount;
      _savingsGoals[idx] = goal.copyWith(
        currentSaved: newSaved,
        isCompleted: completed,
      );

      if (completed) {
        _alerts.insert(
          0,
          AlertModel(
            id: _uuid.v4(),
            title: '🎯 Savings Goal Conquered!',
            description: 'Congratulations! You hit your ₹${goal.targetAmount.toStringAsFixed(0)} goal for ${goal.name}.',
            type: 'success',
            date: DateTime.now(),
          ),
        );
        await _storage.saveAlerts(_alerts);
      }

      await _storage.saveSavingsGoals(_savingsGoals);
      await FirebaseService().saveSavingsGoal(_savingsGoals[idx]);
      notifyListeners();
    }
  }

  Future<void> updateSavingsGoal(SavingsGoalModel goal) async {
    final idx = _savingsGoals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      _savingsGoals[idx] = goal;
      await _storage.saveSavingsGoals(_savingsGoals);
      await FirebaseService().saveSavingsGoal(goal);
      notifyListeners();
    }
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    _savingsGoals.removeWhere((g) => g.id == goalId);
    await _storage.saveSavingsGoals(_savingsGoals);
    await FirebaseService().deleteSavingsGoal(goalId);
    notifyListeners();
  }

  // --- Profile & Preferences ---
  Future<void> updateUserProfile(UserProfileModel profile) async {
    _userProfile = profile;
    await _storage.saveUserProfile(_userProfile);
    // update overall budget total amount if budget model exists
    final idx = _budgets.indexWhere((b) => b.categoryId == null);
    if (idx != -1) {
      _budgets[idx] = _budgets[idx].copyWith(totalAmount: profile.totalMonthlyBudget);
      await _storage.saveBudgets(_budgets);
    }
    notifyListeners();
  }

  // Reset to Demo Data
  Future<void> resetToDemoData() async {
    _transactions = DemoData.transactions;
    _categories = DemoData.categories;
    _budgets = DemoData.budgets;
    _bills = DemoData.bills;
    _alerts = DemoData.alerts;
    _savingsGoals = DemoData.savingsGoals;
    _userProfile = DemoData.userProfile;
    _recalculateAll();
    await _persistAll();
    notifyListeners();
  }

  // Clear All Data
  Future<void> clearAllData() async {
    _transactions.clear();
    _budgets.clear();
    _bills.clear();
    _alerts.clear();
    _savingsGoals.clear();
    _recalculateAll();
    await _storage.clearAll();
    await _storage.setHasInitialized(true);
    notifyListeners();
  }

  Future<void> _persistAll() async {
    await _storage.saveTransactions(_transactions);
    await _storage.saveCategories(_categories);
    await _storage.saveBudgets(_budgets);
    await _storage.saveBills(_bills);
    await _storage.saveAlerts(_alerts);
    await _storage.saveSavingsGoals(_savingsGoals);
    await _storage.saveUserProfile(_userProfile);
  }
}
