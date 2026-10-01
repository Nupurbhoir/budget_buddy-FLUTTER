class UserProfileModel {
  final String name;
  final String email;
  final String phone;
  final String currency;
  final double totalMonthlyBudget;
  final bool isBiometricEnabled;
  final bool billAlertsEnabled;
  final bool budgetAlertsEnabled;
  final bool dailyRecapEnabled;
  final String? profileImageUrl;

  UserProfileModel({
    required this.name,
    required this.email,
    this.phone = '+91 98765 43210',
    this.currency = '₹',
    this.totalMonthlyBudget = 50000.0,
    this.isBiometricEnabled = false,
    this.billAlertsEnabled = true,
    this.budgetAlertsEnabled = true,
    this.dailyRecapEnabled = true,
    this.profileImageUrl,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'currency': currency,
        'totalMonthlyBudget': totalMonthlyBudget,
        'isBiometricEnabled': isBiometricEnabled,
        'billAlertsEnabled': billAlertsEnabled,
        'budgetAlertsEnabled': budgetAlertsEnabled,
        'dailyRecapEnabled': dailyRecapEnabled,
        'profileImageUrl': profileImageUrl,
      };

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        name: json['name'] as String? ?? 'Nupur Sharma',
        email: json['email'] as String? ?? 'nupur@example.com',
        phone: json['phone'] as String? ?? '+91 98765 43210',
        currency: json['currency'] as String? ?? '₹',
        totalMonthlyBudget:
            (json['totalMonthlyBudget'] as num?)?.toDouble() ?? 50000.0,
        isBiometricEnabled: json['isBiometricEnabled'] as bool? ?? false,
        billAlertsEnabled: json['billAlertsEnabled'] as bool? ?? true,
        budgetAlertsEnabled: json['budgetAlertsEnabled'] as bool? ?? true,
        dailyRecapEnabled: json['dailyRecapEnabled'] as bool? ?? true,
        profileImageUrl: json['profileImageUrl'] as String?,
      );

  UserProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? currency,
    double? totalMonthlyBudget,
    bool? isBiometricEnabled,
    bool? billAlertsEnabled,
    bool? budgetAlertsEnabled,
    bool? dailyRecapEnabled,
    String? profileImageUrl,
  }) {
    return UserProfileModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      currency: currency ?? this.currency,
      totalMonthlyBudget: totalMonthlyBudget ?? this.totalMonthlyBudget,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      billAlertsEnabled: billAlertsEnabled ?? this.billAlertsEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      dailyRecapEnabled: dailyRecapEnabled ?? this.dailyRecapEnabled,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
