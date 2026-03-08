import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/modules/daily_challenge/data/services/products_firebase_service.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget for collecting Indian delivery address from user
class IndianAddressForm extends StatefulWidget {
  final Function(DeliveryAddress address)? onAddressValidated;
  final Function()? onNonIndianAddress;
  final String supportEmail;

  const IndianAddressForm({
    super.key,
    this.onAddressValidated,
    this.onNonIndianAddress,
    this.supportEmail = 'byteberg18@gmail.com',
  });

  @override
  State<IndianAddressForm> createState() => _IndianAddressFormState();
}

class _IndianAddressFormState extends State<IndianAddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _landmarkController = TextEditingController();

  bool _isSubmitting = false;
  bool _showNonIndianDialog = false;

  // Indian states for dropdown
  final List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  String? _selectedState;

  @override
  void initState() {
    super.initState();
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

  void _validateAndSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final pincode = _pincodeController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();

    // Validate Indian pincode (6 digits, starts with 1-9)
    final pincodeRegex = RegExp(r'^[1-9][0-9]{5}$');
    if (!pincodeRegex.hasMatch(pincode)) {
      _showInvalidPincodeDialog();
      return;
    }

    // Validate Indian phone number (10 digits, starts with 6-9)
    final phoneDigits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final phoneRegex = RegExp(r'^[6-9][0-9]{9}$');
    if (!phoneRegex.hasMatch(phoneDigits)) {
      _showInvalidPhoneDialog();
      return;
    }

    // Check if state is Indian
    final isIndianAddress = _indianStates.contains(_selectedState);

    if (!isIndianAddress) {
      _showNonIndianAddressDialog();
      return;
    }

    // All validations passed
    final address = DeliveryAddress(
      fullName: _fullNameController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _selectedState!,
      pincode: pincode,
      phoneNumber: phoneDigits,
      landmark: _landmarkController.text.trim(),
      isIndianAddress: true,
    );

    widget.onAddressValidated?.call(address);
  }

  void _showInvalidPincodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 32.sp),
            SizedBox(width: 8.w),
            Text(
              'Invalid Pincode',
              style: GoogleFonts.bubblegumSans(fontSize: 20.sp),
            ),
          ],
        ),
        content: Text(
          'Please enter a valid 6-digit Indian pincode.\n\nExample: 110001, 400001, 560001',
          style: GoogleFonts.bubblegumSans(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.bubblegumSans(
                fontSize: 16.sp,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInvalidPhoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 32.sp),
            SizedBox(width: 8.w),
            Text(
              'Invalid Phone Number',
              style: GoogleFonts.bubblegumSans(fontSize: 20.sp),
            ),
          ],
        ),
        content: Text(
          'Please enter a valid 10-digit Indian mobile number.\n\nIt should start with 6, 7, 8, or 9.',
          style: GoogleFonts.bubblegumSans(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.bubblegumSans(
                fontSize: 16.sp,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNonIndianAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_rounded, color: Colors.blue, size: 32.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Delivery Limited to India',
                style: GoogleFonts.bubblegumSans(fontSize: 18.sp),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We are currently working on increasing our delivery partners to serve you better!',
              style: GoogleFonts.bubblegumSans(fontSize: 16.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              'In the meantime, please write to us at:',
              style: GoogleFonts.bubblegumSans(fontSize: 14.sp),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () => _launchEmail(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.email_rounded,
                      size: 18.sp,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      widget.supportEmail,
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 14.sp,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onNonIndianAddress?.call();
            },
            child: Text(
              'OK',
              style: GoogleFonts.bubblegumSans(
                fontSize: 16.sp,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: widget.supportEmail,
      query: 'subject=Delivery Inquiry - Non-Indian Address',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        LoggerService.logInfo('Email client launched');
      } else {
        LoggerService.logError('Could not launch email client');
      }
    } catch (e) {
      LoggerService.logError('Error launching email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Address',
                          style: GoogleFonts.bubblegumSans(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'We only deliver within India',
                          style: GoogleFonts.bubblegumSans(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Full Name
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              hint: 'Enter full name',
              icon: Icons.person_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter full name';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),

            SizedBox(height: 16.h),

            // Address Line 1
            _buildTextField(
              controller: _addressLine1Controller,
              label: 'Address Line 1',
              hint: 'House/Flat No., Building Name',
              icon: Icons.home_rounded,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
            ),

            SizedBox(height: 16.h),

            // Address Line 2
            _buildTextField(
              controller: _addressLine2Controller,
              label: 'Address Line 2 (Optional)',
              hint: 'Street, Area, Locality',
              icon: Icons.streetview_rounded,
              maxLines: 2,
            ),

            SizedBox(height: 16.h),

            // Landmark
            _buildTextField(
              controller: _landmarkController,
              label: 'Landmark (Optional)',
              hint: 'Nearby landmark',
              icon: Icons.place_rounded,
            ),

            SizedBox(height: 16.h),

            // City and State row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'Enter city',
                    icon: Icons.location_city_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 3,
                  child: _buildDropdownField(
                    value: _selectedState,
                    items: _indianStates,
                    label: 'State',
                    hint: 'Select state',
                    icon: Icons.map_rounded,
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Pincode and Phone row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _pincodeController,
                    label: 'Pincode',
                    hint: '6-digit pincode',
                    icon: Icons.pin_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (value.length != 6) {
                        return 'Must be 6 digits';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTextField(
                    controller: _phoneNumberController,
                    label: 'Phone Number',
                    hint: '10-digit mobile',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (value.length != 10) {
                        return 'Must be 10 digits';
                      }
                      if (!RegExp(r'^[6-9]').hasMatch(value)) {
                        return 'Must start with 6-9';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: _GamingButton(
                text: 'Verify & Continue',
                onPressed: _isSubmitting ? null : _validateAndSubmit,
                isLoading: _isSubmitting,
              ),
            ),

            SizedBox(height: 16.h),

            // Support info
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.amber,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'For non-Indian addresses, please contact us at ${widget.supportEmail}',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 12.sp,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
          ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: GoogleFonts.bubblegumSans(
            fontSize: 14.sp,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.bubblegumSans(
              fontSize: 14.sp,
              color: Colors.white38,
            ),
            prefixIcon: Icon(icon, color: Colors.white54, size: 20.sp),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7CFF6B), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String label,
    required String hint,
    required IconData icon,
    required void Function(String?) onChanged,
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
          ),
        ),
        SizedBox(height: 6.h),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.bubblegumSans(
              fontSize: 14.sp,
              color: Colors.white38,
            ),
          ),
          items: items.map((state) {
            return DropdownMenuItem(
              value: state,
              child: Text(
                state,
                style: GoogleFonts.bubblegumSans(
                  fontSize: 12.sp,
                  color: Colors.white,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          dropdownColor: const Color(0xFF0D2137),
          style: GoogleFonts.bubblegumSans(
            fontSize: 14.sp,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white54, size: 20.sp),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7CFF6B), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
          ),
        ),
      ],
    );
  }
}

/// Gaming button widget for the form
class _GamingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GamingButton({
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: onPressed == null || isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF7CFF6B), Color(0xFF28A060)],
                ),
          color: onPressed == null || isLoading ? Colors.grey : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (onPressed != null && !isLoading)
              BoxShadow(
                color: const Color(0xFF7CFF6B).withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  height: 24.h,
                  width: 24.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
