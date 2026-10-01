class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String paymentMethod;
  final String notes;
  final String type; // 'income' or 'expense'
  final DateTime createdAt;
  final String? receiptRef;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.paymentMethod,
    this.notes = '',
    required this.type,
    DateTime? createdAt,
    this.receiptRef,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'paymentMethod': paymentMethod,
        'notes': notes,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'receiptRef': receiptRef,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        paymentMethod: json['paymentMethod'] as String? ?? 'UPI',
        notes: json['notes'] as String? ?? '',
        type: json['type'] as String? ?? 'expense',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        receiptRef: json['receiptRef'] as String?,
      );

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? paymentMethod,
    String? notes,
    String? type,
    DateTime? createdAt,
    String? receiptRef,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      receiptRef: receiptRef ?? this.receiptRef,
    );
  }
}
