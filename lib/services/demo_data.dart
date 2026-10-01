import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';
import '../models/bill_model.dart';
import '../models/alert_model.dart';
import '../models/savings_goal_model.dart';
import '../models/user_profile_model.dart';

class DemoData {
  static List<CategoryModel> get categories => [
        const CategoryModel(
          id: 'cat_food',
          name: 'Food & Dining',
          iconName: 'restaurant',
          colorValue: 0xFF10B981,
          monthlyLimit: 10000.0,
        ),
        const CategoryModel(
          id: 'cat_shopping',
          name: 'Shopping',
          iconName: 'shopping',
          colorValue: 0xFF8B5CF6,
          monthlyLimit: 8000.0,
        ),
        const CategoryModel(
          id: 'cat_bills',
          name: 'Bills & Utilities',
          iconName: 'bills',
          colorValue: 0xFFF59E0B,
          monthlyLimit: 10000.0,
        ),
        const CategoryModel(
          id: 'cat_transport',
          name: 'Transport',
          iconName: 'transport',
          colorValue: 0xFF3B82F6,
          monthlyLimit: 3000.0,
        ),
        const CategoryModel(
          id: 'cat_entertainment',
          name: 'Entertainment',
          iconName: 'entertainment',
          colorValue: 0xFFEC4899,
          monthlyLimit: 2500.0,
        ),
        const CategoryModel(
          id: 'cat_health',
          name: 'Healthcare',
          iconName: 'health',
          colorValue: 0xFFEF4444,
          monthlyLimit: 3000.0,
        ),
        const CategoryModel(
          id: 'cat_education',
          name: 'Education',
          iconName: 'education',
          colorValue: 0xFF14B8A6,
          monthlyLimit: 3000.0,
        ),
        const CategoryModel(
          id: 'cat_personal',
          name: 'Personal Care',
          iconName: 'personal',
          colorValue: 0xFF06B6D4,
          monthlyLimit: 2000.0,
        ),
        const CategoryModel(
          id: 'cat_other',
          name: 'Other',
          iconName: 'other',
          colorValue: 0xFF64748B,
          monthlyLimit: 2000.0,
        ),
      ];

  static List<TransactionModel> get transactions {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 'tx_1',
        title: 'Swiggy Food Delivery',
        amount: 850.0,
        category: 'Food & Dining',
        date: now.subtract(const Duration(hours: 3)),
        paymentMethod: 'UPI',
        notes: 'Lunch with colleagues',
        type: 'expense',
      ),
      TransactionModel(
        id: 'tx_2',
        title: 'Freelance UI Project',
        amount: 42000.0,
        category: 'Income',
        date: now.subtract(const Duration(days: 1, hours: 2)),
        paymentMethod: 'Bank Transfer',
        notes: 'Mobile app design milestone 2 payout',
        type: 'income',
      ),
      TransactionModel(
        id: 'tx_3',
        title: 'Uber Auto Ride',
        amount: 184.0,
        category: 'Transport',
        date: now.subtract(const Duration(days: 1, hours: 6)),
        paymentMethod: 'Cash',
        notes: 'Ride to metro station',
        type: 'expense',
      ),
      TransactionModel(
        id: 'tx_4',
        title: 'Zara Autumn Collection',
        amount: 3499.0,
        category: 'Shopping',
        date: now.subtract(const Duration(days: 2, hours: 4)),
        paymentMethod: 'Credit Card',
        notes: 'Winter jacket and shirt',
        type: 'expense',
      ),
      TransactionModel(
        id: 'tx_5',
        title: 'Adani Electricity Bill',
        amount: 2450.0,
        category: 'Bills & Utilities',
        date: now.subtract(const Duration(days: 3, hours: 1)),
        paymentMethod: 'UPI',
        notes: 'Monthly power consumption',
        type: 'expense',
      ),
      TransactionModel(
        id: 'tx_6',
        title: 'Croma Electronics Hub',
        amount: 12990.0,
        category: 'Shopping',
        date: now.subtract(const Duration(days: 4, hours: 5)),
        paymentMethod: 'Credit Card',
        notes: 'External 4K Monitor for workstation',
        type: 'expense',
      ),
      TransactionModel(
        id: 'tx_7',
        title: 'Salary Credit - TechCorp',
        amount: 65000.0,
        category: 'Income',
        date: now.subtract(const Duration(days: 5)),
        paymentMethod: 'Bank Transfer',
        notes: 'Monthly salary credit',
        type: 'income',
      ),
      TransactionModel(
        id: 'tx_8',
        title: 'Starbucks Coffee Reserve',
        amount: 450.0,
        category: 'Food & Dining',
        date: now.subtract(const Duration(days: 6, hours: 2)),
        paymentMethod: 'UPI',
        notes: 'Cold brew and croissant',
        type: 'expense',
      ),
      TransactionModel(
        id: 'tx_9',
        title: 'Coursera Online Specialization',
        amount: 1500.0,
        category: 'Education',
        date: now.subtract(const Duration(days: 7, hours: 3)),
        paymentMethod: 'Debit Card',
        notes: 'Advanced System Architecture certificate',
        type: 'expense',
      ),
      TransactionModel(
        id: 'tx_10',
        title: 'Netflix 4K Ultra Subscription',
        amount: 649.0,
        category: 'Entertainment',
        date: now.subtract(const Duration(days: 8)),
        paymentMethod: 'Credit Card',
        notes: 'Monthly renewal',
        type: 'expense',
      ),
      TransactionModel(
        id: 'tx_11',
        title: 'Apollo Pharmacy & Wellness',
        amount: 650.0,
        category: 'Healthcare',
        date: now.subtract(const Duration(days: 9)),
        paymentMethod: 'UPI',
        notes: 'Vitamins and first aid kit',
        type: 'expense',
      ),
      TransactionModel(
        id: 'tx_12',
        title: 'JioFiber Broadband Plan',
        amount: 999.0,
        category: 'Bills & Utilities',
        date: now.subtract(const Duration(days: 10)),
        paymentMethod: 'Net Banking',
        notes: '300 Mbps fiber connection',
        type: 'expense',
      ),
    ];
  }

  static List<BudgetModel> get budgets {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);

    return [
      BudgetModel(
        id: 'b_monthly',
        name: 'Overall Monthly Budget',
        categoryId: null,
        totalAmount: 50000.0,
        spentAmount: 23572.0,
        startDate: start,
        endDate: end,
        warningThreshold: 0.8,
      ),
      BudgetModel(
        id: 'b_food',
        name: 'Food & Dining',
        categoryId: 'cat_food',
        totalAmount: 10000.0,
        spentAmount: 8000.0, // 80% warning
        startDate: start,
        endDate: end,
        warningThreshold: 0.8,
      ),
      BudgetModel(
        id: 'b_shopping',
        name: 'Shopping & E-Commerce',
        categoryId: 'cat_shopping',
        totalAmount: 8000.0,
        spentAmount: 16489.0, // exceeded
        startDate: start,
        endDate: end,
        warningThreshold: 0.8,
      ),
      BudgetModel(
        id: 'b_transport',
        name: 'Transport & Fuel',
        categoryId: 'cat_transport',
        totalAmount: 3000.0,
        spentAmount: 1950.0, // 65% safe
        startDate: start,
        endDate: end,
        warningThreshold: 0.8,
      ),
      BudgetModel(
        id: 'b_bills',
        name: 'Bills & Utilities',
        categoryId: 'cat_bills',
        totalAmount: 10000.0,
        spentAmount: 9850.0, // 98.5% warning
        startDate: start,
        endDate: end,
        warningThreshold: 0.8,
      ),
      BudgetModel(
        id: 'b_ent',
        name: 'Entertainment & OTT',
        categoryId: 'cat_entertainment',
        totalAmount: 2500.0,
        spentAmount: 1200.0, // 48% safe
        startDate: start,
        endDate: end,
        warningThreshold: 0.8,
      ),
    ];
  }

  static List<BillModel> get bills {
    final now = DateTime.now();
    return [
      BillModel(
        id: 'bill_1',
        title: 'Electricity Bill (Adani / MSEB)',
        amount: 2450.0,
        category: 'Bills & Utilities',
        dueDate: now.add(const Duration(days: 2)),
        status: 'upcoming',
        reminderEnabled: true,
        recurring: true,
        frequency: 'Monthly',
      ),
      BillModel(
        id: 'bill_2',
        title: 'Broadband Internet (JioFiber)',
        amount: 1179.0,
        category: 'Bills & Utilities',
        dueDate: now.add(const Duration(days: 5)),
        status: 'upcoming',
        reminderEnabled: true,
        recurring: true,
        frequency: 'Monthly',
      ),
      BillModel(
        id: 'bill_3',
        title: 'Flat Rental Payment',
        amount: 18000.0,
        category: 'Bills & Utilities',
        dueDate: now.add(const Duration(days: 8)),
        status: 'upcoming',
        reminderEnabled: true,
        recurring: true,
        frequency: 'Monthly',
      ),
      BillModel(
        id: 'bill_4',
        title: 'Cult.fit Fitness Membership',
        amount: 1500.0,
        category: 'Healthcare',
        dueDate: now.add(const Duration(days: 12)),
        status: 'upcoming',
        reminderEnabled: true,
        recurring: true,
        frequency: 'Monthly',
      ),
      BillModel(
        id: 'bill_5',
        title: 'Netflix 4K Ultra Subscription',
        amount: 649.0,
        category: 'Entertainment',
        dueDate: now.subtract(const Duration(days: 8)),
        status: 'paid',
        reminderEnabled: false,
        recurring: true,
        frequency: 'Monthly',
        paidDate: now.subtract(const Duration(days: 8)),
      ),
    ];
  }

  static List<AlertModel> get alerts {
    final now = DateTime.now();
    return [
      AlertModel(
        id: 'alert_1',
        title: 'Budget Limit Reached: Shopping',
        description:
            'You have exceeded 100% of your Shopping budget for this month. We recommend adjusting spending limits.',
        type: 'budget_exceeded',
        date: now.subtract(const Duration(hours: 4)),
        isRead: false,
      ),
      AlertModel(
        id: 'alert_2',
        title: 'Electricity Bill Due in 2 Days',
        description:
            'Amount: ₹2,450 due on ${now.add(const Duration(days: 2)).day}th. Pay before the due date to avoid late fees.',
        type: 'bill_due',
        date: now.subtract(const Duration(hours: 12)),
        isRead: false,
      ),
      AlertModel(
        id: 'alert_3',
        title: 'Unusual High Spending Detected',
        description:
            '₹12,990 spent at Croma Electronics Hub. This is 320% higher than your daily average.',
        type: 'spending_spike',
        date: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
      AlertModel(
        id: 'alert_4',
        title: 'Weekly Budget Win!',
        description:
            'Great job! You stayed comfortably within your Transport budget this week, saving ₹900.',
        type: 'insight',
        date: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }

  static List<SavingsGoalModel> get savingsGoals {
    final now = DateTime.now();
    return [
      SavingsGoalModel(
        id: 'goal_1',
        name: 'Emergency Fund',
        targetAmount: 20000.0,
        currentSaved: 14250.0,
        targetDate: now.add(const Duration(days: 45)),
        category: 'Emergency',
      ),
      SavingsGoalModel(
        id: 'goal_2',
        name: 'Goa Vacation Trip',
        targetAmount: 15000.0,
        currentSaved: 9800.0,
        targetDate: now.add(const Duration(days: 30)),
        category: 'Travel',
      ),
      SavingsGoalModel(
        id: 'goal_3',
        name: 'MacBook Pro Upgrade',
        targetAmount: 85000.0,
        currentSaved: 35000.0,
        targetDate: now.add(const Duration(days: 120)),
        category: 'Gadgets',
      ),
    ];
  }

  static UserProfileModel get userProfile => UserProfileModel(
        name: 'Nupur Sharma',
        email: 'nupur@example.com',
        phone: '+91 98765 43210',
        currency: '₹',
        totalMonthlyBudget: 50000.0,
        isBiometricEnabled: true,
        billAlertsEnabled: true,
        budgetAlertsEnabled: true,
        dailyRecapEnabled: true,
      );
}
