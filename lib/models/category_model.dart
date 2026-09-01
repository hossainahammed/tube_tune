import 'package:flutter/material.dart';

/// Represents a filterable content category
class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<String> keywords;
  final String description;
  final bool isEnabled;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.keywords,
    this.description = '',
    this.isEnabled = true,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    List<String>? keywords,
    String? description,
    bool? isEnabled,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      keywords: keywords ?? this.keywords,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isEnabled': isEnabled,
      'keywords': keywords,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json, CategoryModel defaultTemplate) {
    return defaultTemplate.copyWith(
      isEnabled: json['isEnabled'] as bool? ?? defaultTemplate.isEnabled,
    );
  }
}
