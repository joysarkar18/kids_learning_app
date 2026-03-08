import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/daily_challenge/bloc/products_bloc_event.dart';
import 'package:kids_learning/modules/daily_challenge/bloc/products_bloc_state.dart';
import 'package:kids_learning/modules/daily_challenge/data/services/products_firebase_service.dart';
import 'package:kids_learning/services/logger_service.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductsFirebaseService _firebaseService;

  ProductsBloc({ProductsFirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? ProductsFirebaseService(),
        super(const ProductsInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadProductDetails>(_onLoadProductDetails);
    on<RedeemProduct>(_onRedeemProduct);
    on<LoadUserRedemptions>(_onLoadUserRedemptions);
    on<RefreshProducts>(_onRefreshProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      emit(const ProductsLoading());
      final products = await _firebaseService.getAvailableProducts();
      emit(ProductsLoaded(products));
    } catch (e) {
      LoggerService.logError('Error loading products: $e');
      emit(const ProductsError('Failed to load products'));
    }
  }

  Future<void> _onLoadProductDetails(
    LoadProductDetails event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      final product = await _firebaseService.getProductById(event.productId);
      if (product != null) {
        emit(ProductDetailsLoaded(product));
      } else {
        emit(const ProductsError('Product not found'));
      }
    } catch (e) {
      LoggerService.logError('Error loading product details: $e');
      emit(const ProductsError('Failed to load product details'));
    }
  }

  Future<void> _onRedeemProduct(
    RedeemProduct event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      emit(const RedemptionProcessing());

      final result = await _firebaseService.createRedemption(
        product: event.product,
        address: event.address,
      );

      if (result.success) {
        emit(RedemptionSuccess(
          redemptionId: result.redemptionId ?? '',
          message: result.message,
        ));
      } else {
        emit(RedemptionFailure(
          message: result.message,
          errorCode: result.errorCode,
        ));
      }
    } catch (e) {
      LoggerService.logError('Error redeeming product: $e');
      emit(const RedemptionFailure(
        message: 'Failed to process redemption. Please try again.',
      ));
    }
  }

  Future<void> _onLoadUserRedemptions(
    LoadUserRedemptions event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      final redemptions = await _firebaseService.getUserRedemptions();
      emit(UserRedemptionsLoaded(redemptions));
    } catch (e) {
      LoggerService.logError('Error loading user redemptions: $e');
      emit(const ProductsError('Failed to load redemption history'));
    }
  }

  Future<void> _onRefreshProducts(
    RefreshProducts event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      final products = await _firebaseService.getAvailableProducts();
      if (state is ProductsLoaded) {
        emit(ProductsLoaded(products));
      }
    } catch (e) {
      LoggerService.logError('Error refreshing products: $e');
    }
  }
}
