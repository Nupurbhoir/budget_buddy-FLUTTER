import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';
import '../models/bill_model.dart';
import '../models/alert_model.dart';
import '../models/savings_goal_model.dart';
import '../models/user_profile_model.dart';

class StorageService {
  static const String _keyTransactions = 'bb_transactions';
  static const String _keyCategories = 'bb_categories';
  static const String _keyBudgets = 'bb_budgets';
  static const String _keyBills = 'bb_bills';
  static const String _keyAlerts = 'bb_alerts';
  static const String _keyGoals = 'bb_savings_goals';
  static const String _keyProfile = 'bb_user_profile';
  static const String _keyInitialized = 'bb_has_initialized_data';
  static const String _keyThemeMode = 'bb_theme_mode';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool get hasInitialized => _prefs.getBool(_keyInitialized) ?? false;

  Future<void> setHasInitialized(bool val) async {
    await _prefs.setBool(_keyInitialized, val);
  }

  // Transactions
  List<TransactionModel>? loadTransactions() {
    final jsonString = _prefs.getString(_keyTransactions);
    if (jsonString == null) return null;
    try {
      final List list = jsonDecode(jsonString);
      return list.map((e) => TransactionModel.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTransactions(List<TransactionModel> items) async {
    final jsonString = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyTransactions, jsonString);
  }

  // Categories
  List<CategoryModel>? loadCategories() {
    final jsonString = _prefs.getString(_keyCategories);
    if (jsonString == null) return null;
    try {
      final List list = jsonDecode(jsonString);
      return list.map((e) => CategoryModel.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCategories(List<CategoryModel> items) async {
    final jsonString = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyCategories, jsonString);
  }

  // Budgets
  List<BudgetModel>? loadBudgets() {
    final jsonString = _prefs.getString(_keyBudgets);
    if (jsonString == null) return null;
    try {
      final List list = jsonDecode(jsonString);
      return list.map((e) => BudgetModel.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBudgets(List<BudgetModel> items) async {
    final jsonString = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyBudgets, jsonString);
  }

  // Bills
  List<BillModel>? loadBills() {
    final jsonString = _prefs.getString(_keyBills);
    if (jsonString == null) return null;
    try {
      final List list = jsonDecode(jsonString);
      return list.map((e) => BillModel.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBills(List<BillModel> items) async {
    final jsonString = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyBills, jsonString);
  }

  // Alerts
  List<AlertModel>? loadAlerts() {
    final jsonString = _prefs.getString(_keyAlerts);
    if (jsonString == null) return null;
    try {
      final List list = jsonDecode(jsonString);
      return list.map((e) => AlertModel.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAlerts(List<AlertModel> items) async {
    final jsonString = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyAlerts, jsonString);
  }

  // Savings Goals
  List<SavingsGoalModel>? loadSavingsGoals() {
    final jsonString = _prefs.getString(_keyGoals);
    if (jsonString == null) return null;
    try {
      final List list = jsonDecode(jsonString);
      return list.map((e) => SavingsGoalModel.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSavingsGoals(List<SavingsGoalModel> items) async {
    final jsonString = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyGoals, jsonString);
  }

  // User Profile
  UserProfileModel? loadUserProfile() {
    final jsonString = _prefs.getString(_keyProfile);
    if (jsonString == null) return null;
    try {
      final map = jsonDecode(jsonString);
      return UserProfileModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserProfile(UserProfileModel profile) async {
    final jsonString = jsonEncode(profile.toJson());
    await _prefs.setString(_keyProfile, jsonString);
  }

  // Theme Mode
  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'light';
  Future<void> setThemeMode(String mode) async =>
      await _prefs.setString(_keyThemeMode, mode);

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
