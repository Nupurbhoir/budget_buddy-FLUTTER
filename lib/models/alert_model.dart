class AlertModel {
  final String id;
  final String title;
  final String description;
  final String type; // 'budget_warning', 'budget_exceeded', 'bill_due', 'bill_overdue', 'spending_spike', 'insight', 'success'
  final DateTime date;
  final bool isRead;
  final String? relatedId;

  AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.date,
    this.isRead = false,
    this.relatedId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type,
        'date': date.toIso8601String(),
        'isRead': isRead,
        'relatedId': relatedId,
      };

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        type: json['type'] as String,
        date: DateTime.parse(json['date'] as String),
        isRead: json['isRead'] as bool? ?? false,
        relatedId: json['relatedId'] as String?,
      );

  AlertModel copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    DateTime? date,
    bool? isRead,
    String? relatedId,
  }) {
    return AlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
    );
  }
}
