class BudgetModel {
  final String id;
  final String name;
  final String? categoryId; // null means overall monthly budget
  final double totalAmount;
  final double spentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final double warningThreshold; // e.g. 0.8 (80%)

  BudgetModel({
    required this.id,
    required this.name,
    this.categoryId,
    required this.totalAmount,
    this.spentAmount = 0.0,
    required this.startDate,
    required this.endDate,
    this.warningThreshold = 0.8,
  });

  double get remainingAmount => (totalAmount - spentAmount).clamp(0.0, double.infinity);
  double get percentageUsed => totalAmount > 0 ? (spentAmount / totalAmount) : 0.0;
  bool get isWarning => percentageUsed >= warningThreshold && percentageUsed < 1.0;
  bool get isExceeded => percentageUsed >= 1.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'totalAmount': totalAmount,
        'spentAmount': spentAmount,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'warningThreshold': warningThreshold,
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        name: json['name'] as String,
        categoryId: json['categoryId'] as String?,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        warningThreshold: (json['warningThreshold'] as num?)?.toDouble() ?? 0.8,
      );

  BudgetModel copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? totalAmount,
    double? spentAmount,
    DateTime? startDate,
    DateTime? endDate,
    double? warningThreshold,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      totalAmount: totalAmount ?? this.totalAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      warningThreshold: warningThreshold ?? this.warningThreshold,
    );
  }
}
