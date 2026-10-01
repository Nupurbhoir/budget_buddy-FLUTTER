class BillModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime dueDate;
  final String status; // 'upcoming', 'due_soon', 'paid', 'overdue'
  final bool reminderEnabled;
  final bool recurring;
  final String frequency; // 'Monthly', 'Quarterly', 'Yearly'
  final DateTime? paidDate;

  BillModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.dueDate,
    this.status = 'upcoming',
    this.reminderEnabled = true,
    this.recurring = true,
    this.frequency = 'Monthly',
    this.paidDate,
  });

  bool get isPaid => status == 'paid';

  // Dynamic status evaluation based on current date
  String get dynamicStatus {
    if (isPaid) return 'paid';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diffDays = due.difference(today).inDays;

    if (diffDays < 0) return 'overdue';
    if (diffDays <= 3) return 'due_soon';
    return 'upcoming';
  }

  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  String get dueLabel {
    if (isPaid) return 'Paid on ${dueDate.day}/${dueDate.month}';
    final days = daysUntilDue;
    if (days < 0) return 'Overdue by ${-days} day${-days == 1 ? '' : 's'}';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'dueDate': dueDate.toIso8601String(),
        'status': status,
        'reminderEnabled': reminderEnabled,
        'recurring': recurring,
        'frequency': frequency,
        'paidDate': paidDate?.toIso8601String(),
      };

  factory BillModel.fromJson(Map<String, dynamic> json) => BillModel(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        dueDate: DateTime.parse(json['dueDate'] as String),
        status: json['status'] as String? ?? 'upcoming',
        reminderEnabled: json['reminderEnabled'] as bool? ?? true,
        recurring: json['recurring'] as bool? ?? true,
        frequency: json['frequency'] as String? ?? 'Monthly',
        paidDate: json['paidDate'] != null
            ? DateTime.parse(json['paidDate'] as String)
            : null,
      );

  BillModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? dueDate,
    String? status,
    bool? reminderEnabled,
    bool? recurring,
    String? frequency,
    DateTime? paidDate,
  }) {
    return BillModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      recurring: recurring ?? this.recurring,
      frequency: frequency ?? this.frequency,
      paidDate: paidDate ?? this.paidDate,
    );
  }
}
