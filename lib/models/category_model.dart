import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final int colorValue;
  final double monthlyLimit;
  final double currentSpent;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconName = 'other',
    required this.colorValue,
    this.monthlyLimit = 0.0,
    this.currentSpent = 0.0,
  });

  IconData get icon {
    switch (iconName.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'transport':
      case 'commute':
        return Icons.directions_car_outlined;
      case 'bills':
      case 'utilities':
        return Icons.receipt_long_outlined;
      case 'entertainment':
      case 'movie':
        return Icons.movie_outlined;
      case 'health':
      case 'medical':
        return Icons.medical_services_outlined;
      case 'education':
      case 'school':
        return Icons.school_outlined;
      case 'personal':
      case 'spa':
        return Icons.spa_outlined;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color get color => Color(colorValue);

  double get percentageUsed =>
      monthlyLimit > 0 ? (currentSpent / monthlyLimit).clamp(0.0, 2.0) : 0.0;

  bool get isWarning => percentageUsed >= 0.8 && percentageUsed < 1.0;
  bool get isExceeded => percentageUsed >= 1.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'colorValue': colorValue,
        'monthlyLimit': monthlyLimit,
        'currentSpent': currentSpent,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        iconName: json['iconName'] as String? ?? 'other',
        colorValue: json['colorValue'] as int,
        monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble() ?? 0.0,
        currentSpent: (json['currentSpent'] as num?)?.toDouble() ?? 0.0,
      );

  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconName,
    int? colorValue,
    double? monthlyLimit,
    double? currentSpent,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentSpent: currentSpent ?? this.currentSpent,
    );
  }
}
