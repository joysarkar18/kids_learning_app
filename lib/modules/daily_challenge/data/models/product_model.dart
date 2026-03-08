import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a redeemable product from Firebase
class ProductModel {
  final String id;
  final String name;
  final String nameBn;
  final String description;
  final String descriptionBn;
  final String imageUrl;
  final int pointsRequired;
  final String category;
  final bool isAvailable;
  final int stockCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.nameBn,
    required this.description,
    required this.descriptionBn,
    required this.imageUrl,
    required this.pointsRequired,
    required this.category,
    required this.isAvailable,
    required this.stockCount,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return ProductModel(
      id: id ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameBn: json['nameBn'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionBn: json['descriptionBn'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      pointsRequired: json['pointsRequired'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool? ?? true,
      stockCount: json['stockCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String))
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['updatedAt'] as String))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameBn': nameBn,
      'description': description,
      'descriptionBn': descriptionBn,
      'imageUrl': imageUrl,
      'pointsRequired': pointsRequired,
      'category': category,
      'isAvailable': isAvailable,
      'stockCount': stockCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Get localized name based on language code
  String getLocalizedName(bool isBn) => isBn ? nameBn : name;

  /// Get localized description based on language code
  String getLocalizedDescription(bool isBn) => isBn ? descriptionBn : description;

  /// Check if product is in stock
  bool get isInStock => stockCount > 0 && isAvailable;

  /// Create a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? nameBn,
    String? description,
    String? descriptionBn,
    String? imageUrl,
    int? pointsRequired,
    String? category,
    bool? isAvailable,
    int? stockCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameBn: nameBn ?? this.nameBn,
      description: description ?? this.description,
      descriptionBn: descriptionBn ?? this.descriptionBn,
      imageUrl: imageUrl ?? this.imageUrl,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      stockCount: stockCount ?? this.stockCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
