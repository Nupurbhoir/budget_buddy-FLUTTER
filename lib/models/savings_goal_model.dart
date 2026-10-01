class SavingsGoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentSaved;
  final DateTime targetDate;
  final String category;
  final bool isCompleted;
  final DateTime createdAt;

  SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentSaved = 0.0,
    required this.targetDate,
    this.category = 'General',
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get remainingAmount => (targetAmount - currentSaved).clamp(0.0, double.infinity);
  double get progressPercentage =>
      targetAmount > 0 ? (currentSaved / targetAmount).clamp(0.0, 1.0) : 0.0;

  String get motivationalInsight {
    final pct = (progressPercentage * 100).toInt();
    if (pct >= 100) return '🎉 Goal achieved! Exceptional discipline!';
    if (pct >= 80) return 'Almost there! You are $pct% closer to your $name!';
    if (pct >= 50) return 'Halfway mark conquered! Keep that momentum going!';
    if (pct >= 25) return 'Great start! Consistency is the key to wealth.';
    return 'Every small step counts towards your $name target!';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'currentSaved': currentSaved,
        'targetDate': targetDate.toIso8601String(),
        'category': category,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) =>
      SavingsGoalModel(
        id: json['id'] as String,
        name: json['name'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentSaved: (json['currentSaved'] as num?)?.toDouble() ?? 0.0,
        targetDate: DateTime.parse(json['targetDate'] as String),
        category: json['category'] as String? ?? 'General',
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  SavingsGoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentSaved,
    DateTime? targetDate,
    String? category,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentSaved: currentSaved ?? this.currentSaved,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
