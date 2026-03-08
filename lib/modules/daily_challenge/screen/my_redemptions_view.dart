import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/modules/daily_challenge/data/services/products_firebase_service.dart';
import 'package:kids_learning/services/logger_service.dart';

class MyRedemptionsView extends StatefulWidget {
  const MyRedemptionsView({super.key});

  @override
  State<MyRedemptionsView> createState() => _MyRedemptionsViewState();
}

class _MyRedemptionsViewState extends State<MyRedemptionsView> {
  Future<List<RedemptionModel>>? _redemptionsFuture;

  @override
  void initState() {
    super.initState();
    _loadRedemptions();
  }

  Future<void> _loadRedemptions() async {
    setState(() {
      _redemptionsFuture = ProductsFirebaseService().getUserRedemptions();
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
          l10n?.myRedemptions ?? 'My Redemptions',
          style: GoogleFonts.bubblegumSans(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRedemptions,
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
          child: FutureBuilder<List<RedemptionModel>>(
            future: _redemptionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (snapshot.hasError) {
                LoggerService.logError(
                  'Error loading redemptions: ${snapshot.error}',
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
                        l10n?.failedToLoadRedemptions ??
                            'Failed to load redemptions',
                        style: GoogleFonts.bubblegumSans(
                          color: Colors.white,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton.icon(
                        onPressed: _loadRedemptions,
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

              final redemptions = snapshot.data ?? [];

              if (redemptions.isEmpty) {
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
                        l10n?.noRedemptionsYet ?? 'No redemptions yet',
                        style: GoogleFonts.bubblegumSans(
                          color: Colors.white,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        l10n?.startRedeeming ??
                            'Start redeeming products to see your orders here!',
                        style: GoogleFonts.bubblegumSans(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await _loadRedemptions();
                },
                color: const Color(0xFF7CFF6B),
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: redemptions.length,
                  itemBuilder: (context, index) {
                    final redemption = redemptions[index];
                    return _RedemptionCard(redemption: redemption, isBn: isBn);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  final RedemptionModel redemption;
  final bool isBn;

  const _RedemptionCard({required this.redemption, required this.isBn});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA726);
      case 'processing':
        return const Color(0xFF42A5F5);
      case 'shipped':
        return const Color(0xFFAB47BC);
      case 'delivered':
        return const Color(0xFF66BB6A);
      case 'cancelled':
        return Colors.red[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.settings;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String status, AppLocalizations? l10n) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n?.statusPending ?? 'Pending';
      case 'processing':
        return l10n?.statusProcessing ?? 'Processing';
      case 'shipped':
        return l10n?.statusShipped ?? 'Shipped';
      case 'delivered':
        return l10n?.statusDelivered ?? 'Delivered';
      case 'cancelled':
        return l10n?.statusCancelled ?? 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(redemption.status).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Product Image + Name + Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: redemption.productImageUrl,
                  width: 80.w,
                  height: 80.w,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80.w,
                    height: 80.w,
                    color: Colors.white.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.image_outlined,
                      color: Colors.white54,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80.w,
                    height: 80.w,
                    color: Colors.white.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // Product Name + Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      redemption.getLocalizedName(isBn),
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          redemption.status,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(
                            redemption.status,
                          ).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(redemption.status),
                            color: _getStatusColor(redemption.status),
                            size: 16,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _getStatusLabel(redemption.status, l10n),
                            style: GoogleFonts.bubblegumSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(redemption.status),
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

          // Points and Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Points Used
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
                      size: 18,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${redemption.pointsUsed} ${l10n?.points ?? "Points"}',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
              ),

              // Date
              Text(
                dateFormat.format(redemption.redeemedAt),
                style: GoogleFonts.bubblegumSans(
                  fontSize: 12.sp,
                  color: Colors.white54,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1.h),
          SizedBox(height: 12.h),

          // Delivery Address
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.white54,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      redemption.deliveryAddress.fullName,
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 13.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      redemption.deliveryAddress.formattedAddress,
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 11.sp,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Redemption ID
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.tag, color: Colors.white54, size: 16.sp),
                SizedBox(width: 8.w),
                Text(
                  'ID: ${redemption.id}',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 10.sp,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
