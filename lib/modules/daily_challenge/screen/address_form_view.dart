import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/product_model.dart';
import 'package:kids_learning/modules/daily_challenge/data/services/products_firebase_service.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AddressFormView extends StatefulWidget {
  final String productId;

  const AddressFormView({super.key, required this.productId});

  @override
  State<AddressFormView> createState() => _AddressFormViewState();
}

class _AddressFormViewState extends State<AddressFormView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _landmarkController = TextEditingController();

  bool _isLoading = false;
  ProductModel? _product;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final product = await ProductsFirebaseService().getProductById(
        widget.productId,
      );
      if (mounted) {
        setState(() {
          _product = product;
        });
      }
    } catch (e) {
      LoggerService.logError('Error loading product: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneNumberController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_product == null) {
      return Scaffold(
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
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

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
          l10n?.deliveryAddress ?? 'Delivery Address',
          style: GoogleFonts.bubblegumSans(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Summary Card
                      _buildProductSummary(_product!, l10n),

                      SizedBox(height: 24.h),

                      // Info Banner
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFF2196F3,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF2196F3),
                              size: 24,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                l10n?.addressInfo ??
                                    'We currently only deliver to Indian addresses. Please provide a valid Indian address.',
                                style: GoogleFonts.bubblegumSans(
                                  fontSize: 13.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Full Name
                      _buildTextField(
                        controller: _fullNameController,
                        label: l10n?.fullName ?? 'Full Name',
                        hintText: l10n?.fullNameHint ?? 'Enter full name',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n?.nameRequired ??
                                'Please enter full name';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Address Line 1
                      _buildTextField(
                        controller: _addressLine1Controller,
                        label: l10n?.addressLine1 ?? 'Address Line 1',
                        hintText:
                            l10n?.addressLine1Hint ??
                            'House no., Building name',
                        icon: Icons.home,
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n?.addressLine1Required ??
                                'Please enter address';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Address Line 2
                      _buildTextField(
                        controller: _addressLine2Controller,
                        label: l10n?.addressLine2 ?? 'Address Line 2',
                        hintText: l10n?.addressLine2Hint ?? 'Area, Locality',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),

                      SizedBox(height: 16.h),

                      // Landmark
                      _buildTextField(
                        controller: _landmarkController,
                        label: l10n?.landmark ?? 'Landmark',
                        hintText:
                            l10n?.landmarkHint ?? 'Nearby landmark (optional)',
                        icon: Icons.place,
                      ),

                      SizedBox(height: 16.h),

                      // City
                      _buildTextField(
                        controller: _cityController,
                        label: l10n?.city ?? 'City',
                        hintText: l10n?.cityHint ?? 'Enter city',
                        icon: Icons.location_city,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n?.cityRequired ?? 'Please enter city';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16.h),

                      // State
                      _buildTextField(
                        controller: _stateController,
                        label: l10n?.state ?? 'State',
                        hintText: l10n?.stateHint ?? 'Enter state',
                        icon: Icons.map,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n?.stateRequired ?? 'Please enter state';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Pincode
                      _buildTextField(
                        controller: _pincodeController,
                        label: l10n?.pincode ?? 'Pincode',
                        hintText: l10n?.pincodeHint ?? 'Enter 6-digit pincode',
                        icon: Icons.pin_drop,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n?.pincodeRequired ??
                                'Please enter pincode';
                          }
                          if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(value)) {
                            return l10n?.invalidPincode ??
                                'Please enter a valid 6-digit Indian pincode';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Phone Number
                      _buildTextField(
                        controller: _phoneNumberController,
                        label: l10n?.phoneNumber ?? 'Phone Number',
                        hintText:
                            l10n?.phoneHint ?? 'Enter 10-digit mobile number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n?.phoneRequired ??
                                'Please enter phone number';
                          }
                          if (!RegExp(
                            r'^[6-9][0-9]{9}$',
                          ).hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
                            return l10n?.invalidPhone ??
                                'Please enter a valid 10-digit Indian mobile number';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 32.h),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7CFF6B),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: 32.w,
                              vertical: 16.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade500,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 24.h,
                                  width: 24.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.black,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 24.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      l10n?.confirmRedeem ??
                                          'Confirm Redemption',
                                      style: GoogleFonts.bubblegumSans(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Email Support Link
                      Center(
                        child: TextButton.icon(
                          onPressed: _openEmailClient,
                          icon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF2196F3),
                          ),
                          label: Text(
                            l10n?.needHelpContactUs ?? 'Need help? Contact us',
                            style: GoogleFonts.bubblegumSans(
                              fontSize: 14.sp,
                              color: const Color(0xFF2196F3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading Overlay
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF7CFF6B),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            l10n?.processingRedemption ??
                                'Processing your redemption...',
                            style: GoogleFonts.bubblegumSans(
                              fontSize: 14.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSummary(ProductModel product, AppLocalizations? l10n) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7CFF6B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: product.imageUrl,
              width: 80.w,
              height: 80.w,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 80.w,
                height: 80.w,
                color: Colors.white.withValues(alpha: 0.1),
                child: const Icon(Icons.image_outlined, color: Colors.white54),
              ),
              errorWidget: (context, url, error) => Container(
                width: 80.w,
                height: 80.w,
                color: Colors.white.withValues(alpha: 0.1),
                child: const Icon(Icons.broken_image, color: Colors.white54),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.getLocalizedName(isBn),
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${product.pointsRequired} ${l10n?.points ?? "Points"}',
                        style: GoogleFonts.bubblegumSans(
                          fontSize: 12.sp,
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    int? maxLines = 1,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.bubblegumSans(
            fontSize: 14.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.bubblegumSans(
              fontSize: 14.sp,
              color: Colors.white54,
            ),
            prefixIcon: Icon(icon, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7CFF6B), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
          style: GoogleFonts.bubblegumSans(
            fontSize: 14.sp,
            color: Colors.white,
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!mounted) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate Indian address
    final pincode = _pincodeController.text.trim();
    final phone = _phoneNumberController.text.trim().replaceAll(
      RegExp(r'\D'),
      '',
    );

    // Check if pincode matches Indian format
    final isIndianPincode = RegExp(r'^[1-9][0-9]{5}$').hasMatch(pincode);
    // Check if phone matches Indian format
    final isIndianPhone = RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone);

    if (!isIndianPincode || !isIndianPhone) {
      if (!mounted) return;
      _showNonIndianAddressDialog();
      return;
    }

    if (_product == null) {
      if (!mounted) return;
      _showFailureDialog('Product not found');
      return;
    }

    // Create delivery address
    final address = DeliveryAddress(
      fullName: _fullNameController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: pincode,
      phoneNumber: phone,
      landmark: _landmarkController.text.trim(),
      isIndianAddress: true,
    );

    // Submit redemption
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ProductsFirebaseService().createRedemption(
        product: _product!,
        address: address,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        _showSuccessDialog(result.redemptionId ?? '', result.message);
      } else {
        if (result.errorCode == RedemptionErrorCode.nonIndianAddress) {
          _showNonIndianAddressDialog();
        } else {
          _showFailureDialog(result.message);
        }
      }
    } catch (e) {
      LoggerService.logError('Error creating redemption: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showFailureDialog('Failed to process redemption. Please try again.');
    }
  }

  void _showSuccessDialog(String redemptionId, String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: const BoxDecoration(
                color: Color(0xFF7CFF6B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              l10n?.redemptionSuccess ?? 'Redemption Successful!',
              style: GoogleFonts.bubblegumSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              style: GoogleFonts.bubblegumSans(
                fontSize: 14.sp,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Redemption ID: $redemptionId',
              style: GoogleFonts.bubblegumSans(
                fontSize: 12.sp,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                context.pop(); // Go back to products list
                context.pop(); // Go back to daily challenge
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7CFF6B),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n?.ok ?? 'OK',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.red[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red[700],
                size: 48,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              l10n?.redemptionFailed ?? 'Redemption Failed',
              style: GoogleFonts.bubblegumSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              style: GoogleFonts.bubblegumSans(
                fontSize: 14.sp,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n?.tryAgain ?? 'Try Again',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNonIndianAddressDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delivery_dining,
                color: Colors.orange[700],
                size: 48,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              l10n?.limitedDelivery ?? 'Limited Delivery Areas',
              style: GoogleFonts.bubblegumSans(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              l10n?.limitedDeliveryMessage ??
                  'We are currently working on increasing our delivery partners to serve you better. At present, we only deliver to Indian addresses with valid Indian pincodes and phone numbers.',
              style: GoogleFonts.bubblegumSans(
                fontSize: 14.sp,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              l10n?.pleaseContactUs ?? 'Please contact us for assistance',
              style: GoogleFonts.bubblegumSans(
                fontSize: 13.sp,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  child: Text(
                    l10n?.cancel ?? 'Cancel',
                    style: GoogleFonts.bubblegumSans(fontSize: 14.sp),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _openEmailClient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email, size: 18),
                      SizedBox(width: 4.w),
                      Text(
                        l10n?.emailUs ?? 'Email Us',
                        style: GoogleFonts.bubblegumSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openEmailClient() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'byteberg18@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'Redemption Delivery Inquiry',
        'body':
            'Hello,\n\nI need assistance with delivery for a redemption. Please help.\n\nThank you.',
      }),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback: Show email in snackbar
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email: byteberg18@gmail.com'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // Clipboard.copy('byteberg18@gmail.com');
              },
            ),
          ),
        );
      }
    } catch (e) {
      LoggerService.logError('Error opening email client: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email us at: byteberg18@gmail.com')),
      );
    }
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}
