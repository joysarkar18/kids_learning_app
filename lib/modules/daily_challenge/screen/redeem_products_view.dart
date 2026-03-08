import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/product_model.dart';
import 'package:kids_learning/modules/daily_challenge/data/services/products_firebase_service.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/services/logger_service.dart';

class RedeemProductsView extends StatefulWidget {
  const RedeemProductsView({super.key});

  @override
  State<RedeemProductsView> createState() => _RedeemProductsViewState();
}

class _RedeemProductsViewState extends State<RedeemProductsView> {
  Future<List<ProductModel>>? _productsFuture;
  Future<int>? _starsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadStars();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _productsFuture = ProductsFirebaseService().getAvailableProducts();
    });
  }

  Future<void> _loadStars() async {
    setState(() {
      _starsFuture = ProductsFirebaseService().getUserStars();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n?.redeemProducts ?? 'Redeem Products',
          style: GoogleFonts.bubblegumSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          // User's Stars Badge
          FutureBuilder<int>(
            future: _starsFuture,
            builder: (context, snapshot) {
              final stars = snapshot.data ?? 0;
              return Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD700),
                      size: 20,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '$stars',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // My Redemptions Button
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            tooltip: l10n?.myRedemptions ?? 'My Redemptions',
            onPressed: () => _navigateToMyRedemptions(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0D2137),
              Color(0xFF0B3328),
              Color(0xFF0E4A2A),
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<ProductModel>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (snapshot.hasError) {
                LoggerService.logError(
                  'Error loading products: ${snapshot.error}',
                );
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[300],
                        size: 64.sp,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        l10n?.noProductsAvailable ?? 'Failed to load products',
                        style: GoogleFonts.bubblegumSans(
                          color: Colors.white,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton.icon(
                        onPressed: _loadProducts,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n?.retry ?? 'Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7CFF6B),
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final products = snapshot.data ?? [];

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 80.sp,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        l10n?.noProductsAvailable ??
                            'No products available right now',
                        style: GoogleFonts.bubblegumSans(
                          color: Colors.white,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        l10n?.checkBackSoon ?? 'Check back soon!',
                        style: GoogleFonts.bubblegumSans(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await _loadProducts();
                  await _loadStars();
                },
                color: const Color(0xFF7CFF6B),
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductCard(
                      product: product,
                      isBn: isBn,
                      onRedeemPressed: () => _navigateToAddressForm(product),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToAddressForm(ProductModel product) {
    context.pushNamed(
      Names.addressForm,
      pathParameters: {'productId': product.id},
    );
  }

  void _navigateToMyRedemptions() {
    context.pushNamed(Names.myRedemptions);
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isBn;
  final VoidCallback onRedeemPressed;

  const _ProductCard({
    required this.product,
    required this.isBn,
    required this.onRedeemPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: product.isInStock
              ? const Color(0xFF7CFF6B).withValues(alpha: 0.4)
              : Colors.red.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: 100.w,
                  height: 100.w,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 100.w,
                    height: 100.w,
                    color: Colors.white.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.image_outlined,
                      color: Colors.white54,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 100.w,
                    height: 100.w,
                    color: Colors.white.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 16.w),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.getLocalizedName(isBn),
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      product.getLocalizedDescription(isBn),
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFD700),
                            size: 20,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${product.pointsRequired} ${l10n?.points ?? 'Points'}',
                            style: GoogleFonts.bubblegumSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Stock and Redeem Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    product.isInStock
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: product.isInStock
                        ? const Color(0xFF7CFF6B)
                        : Colors.red[300],
                    size: 18.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    product.isInStock
                        ? '${l10n?.inStock ?? 'In Stock'}: ${product.stockCount}'
                        : l10n?.outOfStock ?? 'Out of Stock',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 12.sp,
                      color: product.isInStock
                          ? Colors.white70
                          : Colors.red[300],
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: product.isInStock ? onRedeemPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: product.isInStock
                      ? const Color(0xFF7CFF6B)
                      : Colors.grey,
                  foregroundColor: product.isInStock
                      ? Colors.black
                      : Colors.white70,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.white70,
                ),
                child: Text(
                  l10n?.redeem ?? 'Redeem',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
