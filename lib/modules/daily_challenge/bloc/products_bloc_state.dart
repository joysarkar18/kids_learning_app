import 'package:equatable/equatable.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/product_model.dart';
import 'package:kids_learning/modules/daily_challenge/data/services/products_firebase_service.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

class ProductsLoaded extends ProductsState {
  final List<ProductModel> products;

  const ProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class ProductsError extends ProductsState {
  final String message;

  const ProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductDetailsLoaded extends ProductsState {
  final ProductModel product;

  const ProductDetailsLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class RedemptionProcessing extends ProductsState {
  const RedemptionProcessing();
}

class RedemptionSuccess extends ProductsState {
  final String redemptionId;
  final String message;

  const RedemptionSuccess({
    required this.redemptionId,
    required this.message,
  });

  @override
  List<Object?> get props => [redemptionId, message];
}

class RedemptionFailure extends ProductsState {
  final String message;
  final RedemptionErrorCode? errorCode;

  const RedemptionFailure({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class UserRedemptionsLoaded extends ProductsState {
  final List<RedemptionModel> redemptions;

  const UserRedemptionsLoaded(this.redemptions);

  @override
  List<Object?> get props => [redemptions];
}
