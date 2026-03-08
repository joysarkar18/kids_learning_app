import 'package:equatable/equatable.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/product_model.dart';
import 'package:kids_learning/modules/daily_challenge/data/services/products_firebase_service.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductsEvent {
  const LoadProducts();
}

class LoadProductDetails extends ProductsEvent {
  final String productId;

  const LoadProductDetails(this.productId);

  @override
  List<Object?> get props => [productId];
}

class RedeemProduct extends ProductsEvent {
  final ProductModel product;
  final DeliveryAddress address;

  const RedeemProduct({
    required this.product,
    required this.address,
  });

  @override
  List<Object?> get props => [product, address];
}

class LoadUserRedemptions extends ProductsEvent {
  const LoadUserRedemptions();
}

class RefreshProducts extends ProductsEvent {
  const RefreshProducts();
}
