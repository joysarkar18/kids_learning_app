import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/product_model.dart';
import 'package:kids_learning/services/logger_service.dart';

/// Service for managing products and redemptions with Firebase Firestore
class ProductsFirebaseService {
  static final ProductsFirebaseService _instance =
      ProductsFirebaseService._internal();
  factory ProductsFirebaseService() => _instance;
  ProductsFirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection reference for products
  CollectionReference get _productsCollection =>
      _firestore.collection('products');

  /// Collection reference for redemptions
  CollectionReference get _redemptionsCollection =>
      _firestore.collection('redemptions');

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get all available products from Firestore (real-time stream)
  Stream<List<ProductModel>> getAvailableProductsStream() {
    return _productsCollection
        .where('isAvailable', isEqualTo: true)
        .orderBy('pointsRequired', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => ProductModel.fromJson(
                  Map<String, dynamic>.from(doc.data() as Map),
                  id: doc.id,
                ),
              )
              .toList();
        });
  }

  /// Get all products (one-time fetch)
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final snapshot = await _productsCollection
          .orderBy('pointsRequired', descending: false)
          .get();

      return snapshot.docs
          .map(
            (doc) => ProductModel.fromJson(
              Map<String, dynamic>.from(doc.data() as Map),
              id: doc.id,
            ),
          )
          .toList();
    } catch (e) {
      LoggerService.logError('Error fetching products: $e');
      return [];
    }
  }

  /// Get available products only
  Future<List<ProductModel>> getAvailableProducts() async {
    try {
      final snapshot = await _productsCollection
          .where('isAvailable', isEqualTo: true)
          .orderBy('pointsRequired', descending: false)
          .get();

      return snapshot.docs
          .map(
            (doc) => ProductModel.fromJson(
              Map<String, dynamic>.from(doc.data() as Map),
              id: doc.id,
            ),
          )
          .where((product) => product.isInStock)
          .toList();
    } catch (e) {
      LoggerService.logError('Error fetching available products: $e');
      return [];
    }
  }

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _productsCollection
          .where('category', isEqualTo: category)
          .where('isAvailable', isEqualTo: true)
          .orderBy('pointsRequired', descending: false)
          .get();

      return snapshot.docs
          .map(
            (doc) => ProductModel.fromJson(
              Map<String, dynamic>.from(doc.data() as Map),
              id: doc.id,
            ),
          )
          .toList();
    } catch (e) {
      LoggerService.logError('Error fetching products by category: $e');
      return [];
    }
  }

  /// Get a specific product by ID
  Future<ProductModel?> getProductById(String id) async {
    try {
      final doc = await _productsCollection.doc(id).get();

      if (doc.exists) {
        return ProductModel.fromJson(
          Map<String, dynamic>.from(doc.data() as Map),
          id: doc.id,
        );
      }
      return null;
    } catch (e) {
      LoggerService.logError('Error fetching product: $e');
      return null;
    }
  }

  /// Get user's redemption history
  Stream<List<RedemptionModel>> getUserRedemptionsStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _redemptionsCollection
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => RedemptionModel.fromJson(
                  Map<String, dynamic>.from(doc.data() as Map),
                  id: doc.id,
                ),
              )
              .toList();
        });
  }

  /// Get user's total stars from Firestore
  Future<int> getUserStars() async {
    if (_currentUserId == null) {
      return 0;
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      if (userDoc.exists) {
        return userDoc.data()?['totalStars'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      LoggerService.logError('Error fetching user stars: $e');
      return 0;
    }
  }

  /// Get user's redemption history (one-time fetch)
  Future<List<RedemptionModel>> getUserRedemptions() async {
    if (_currentUserId == null) {
      return [];
    }

    try {
      final snapshot = await _redemptionsCollection
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('redeemedAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => RedemptionModel.fromJson(
              Map<String, dynamic>.from(doc.data() as Map),
              id: doc.id,
            ),
          )
          .toList();
    } catch (e) {
      LoggerService.logError('Error fetching user redemptions: $e');
      return [];
    }
  }

  /// Create a new redemption request
  Future<RedemptionResult> createRedemption({
    required ProductModel product,
    required DeliveryAddress address,
  }) async {
    if (_currentUserId == null) {
      return RedemptionResult(
        success: false,
        message: 'User not authenticated',
      );
    }

    try {
      // Check if user has enough stars
      final userStars = await getUserStars();
      if (userStars < product.pointsRequired) {
        return RedemptionResult(
          success: false,
          message:
              'Insufficient stars. You need ${product.pointsRequired - userStars} more stars to redeem this product.',
          errorCode: RedemptionErrorCode.insufficientPoints,
        );
      }

      // Validate Indian address
      if (!address.isIndianAddress) {
        return RedemptionResult(
          success: false,
          message: 'We currently only deliver to Indian addresses',
          errorCode: RedemptionErrorCode.nonIndianAddress,
        );
      }

      // Check if product is still available
      final productDoc = await _productsCollection.doc(product.id).get();
      if (!productDoc.exists) {
        return RedemptionResult(
          success: false,
          message: 'Product no longer available',
          errorCode: RedemptionErrorCode.productUnavailable,
        );
      }

      final productData = Map<String, dynamic>.from(productDoc.data() as Map);
      if (!(productData['isAvailable'] as bool? ?? true) ||
          (productData['stockCount'] as int? ?? 0) <= 0) {
        return RedemptionResult(
          success: false,
          message: 'Product out of stock',
          errorCode: RedemptionErrorCode.outOfStock,
        );
      }

      // Create redemption record
      final redemptionData = {
        'userId': _currentUserId,
        'productId': product.id,
        'productName': product.name,
        'productNameBn': product.nameBn,
        'productImageUrl': product.imageUrl,
        'pointsUsed': product.pointsRequired,
        'status':
            'pending', // pending, processing, shipped, delivered, cancelled
        'redeemedAt': FieldValue.serverTimestamp(),
        'deliveryAddress': address.toJson(),
        'isIndianAddress': address.isIndianAddress,
      };

      final docRef = await _redemptionsCollection.add(redemptionData);

      // Deduct points from user's stars
      await _firestore.collection('users').doc(_currentUserId).update({
        'totalStars': FieldValue.increment(-product.pointsRequired),
      });

      // Decrement product stock
      await _productsCollection.doc(product.id).update({
        'stockCount': FieldValue.increment(-1),
      });

      LoggerService.logInfo(
        'Redemption created: ${docRef.id} for product: ${product.name}',
      );

      return RedemptionResult(
        success: true,
        message:
            'Redemption successful! ${product.pointsRequired} stars deducted.',
        redemptionId: docRef.id,
      );
    } catch (e) {
      LoggerService.logError('Error creating redemption: $e');
      return RedemptionResult(
        success: false,
        message: 'Failed to process redemption. Please try again.',
        errorCode: RedemptionErrorCode.serverError,
      );
    }
  }

  /// Cancel a redemption (only if status is pending)
  Future<bool> cancelRedemption(String redemptionId) async {
    if (_currentUserId == null) return false;

    try {
      final docRef = _redemptionsCollection.doc(redemptionId);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = Map<String, dynamic>.from(doc.data() as Map);
      if (data['userId'] != _currentUserId) return false;

      if (data['status'] != 'pending') {
        return false; // Can only cancel pending redemptions
      }

      await docRef.update({'status': 'cancelled'});

      // Restore product stock
      final productId = data['productId'] as String;
      await _productsCollection.doc(productId).update({
        'stockCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      LoggerService.logError('Error cancelling redemption: $e');
      return false;
    }
  }

  /// Get redemption status
  Future<String?> getRedemptionStatus(String redemptionId) async {
    try {
      final doc = await _redemptionsCollection.doc(redemptionId).get();
      if (doc.exists) {
        return Map<String, dynamic>.from(doc.data() as Map)['status']
            as String?;
      }
      return null;
    } catch (e) {
      LoggerService.logError('Error fetching redemption status: $e');
      return null;
    }
  }
}

/// Model representing a delivery address
class DeliveryAddress {
  final String fullName;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String phoneNumber;
  final String? landmark;
  final bool isIndianAddress;

  const DeliveryAddress({
    required this.fullName,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phoneNumber,
    this.landmark,
    required this.isIndianAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phoneNumber': phoneNumber,
      'landmark': landmark ?? '',
      'isIndianAddress': isIndianAddress,
    };
  }

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      fullName: json['fullName'] as String? ?? '',
      addressLine1: json['addressLine1'] as String? ?? '',
      addressLine2: json['addressLine2'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      landmark: json['landmark'] as String?,
      isIndianAddress: json['isIndianAddress'] as bool? ?? false,
    );
  }

  /// Get formatted address
  String get formattedAddress {
    final parts = [
      addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      if (landmark != null && landmark!.isNotEmpty) 'Near $landmark',
      city,
      state,
      pincode,
    ];
    return parts.where((s) => s.isNotEmpty).join(', ');
  }

  /// Validate Indian pincode (6 digits)
  bool get isValidPincode => RegExp(r'^[1-9][0-9]{5}$').hasMatch(pincode);

  /// Validate Indian phone number (10 digits starting with 6-9)
  bool get isValidPhoneNumber => RegExp(
    r'^[6-9][0-9]{9}$',
  ).hasMatch(phoneNumber.replaceAll(RegExp(r'\D'), ''));
}

/// Model representing a redemption record
class RedemptionModel {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String productNameBn;
  final String productImageUrl;
  final int pointsUsed;
  final String status;
  final DateTime redeemedAt;
  final DeliveryAddress deliveryAddress;
  final bool isIndianAddress;

  const RedemptionModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productNameBn,
    required this.productImageUrl,
    required this.pointsUsed,
    required this.status,
    required this.redeemedAt,
    required this.deliveryAddress,
    required this.isIndianAddress,
  });

  factory RedemptionModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return RedemptionModel(
      id: id ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      productNameBn: json['productNameBn'] as String? ?? '',
      productImageUrl: json['productImageUrl'] as String? ?? '',
      pointsUsed: json['pointsUsed'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      redeemedAt: json['redeemedAt'] is Timestamp
          ? (json['redeemedAt'] as Timestamp).toDate()
          : DateTime.parse(json['redeemedAt'] as String),
      deliveryAddress: DeliveryAddress.fromJson(
        Map<String, dynamic>.from(json['deliveryAddress'] as Map),
      ),
      isIndianAddress: json['isIndianAddress'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'productNameBn': productNameBn,
      'productImageUrl': productImageUrl,
      'pointsUsed': pointsUsed,
      'status': status,
      'redeemedAt': redeemedAt.toIso8601String(),
      'deliveryAddress': deliveryAddress.toJson(),
      'isIndianAddress': isIndianAddress,
    };
  }

  /// Get localized product name
  String getLocalizedName(bool isBn) => isBn ? productNameBn : productName;
}

/// Result of a redemption operation
class RedemptionResult {
  final bool success;
  final String message;
  final String? redemptionId;
  final RedemptionErrorCode? errorCode;

  const RedemptionResult({
    required this.success,
    required this.message,
    this.redemptionId,
    this.errorCode,
  });
}

/// Error codes for redemption failures
enum RedemptionErrorCode {
  nonIndianAddress,
  productUnavailable,
  outOfStock,
  insufficientPoints,
  serverError,
}
