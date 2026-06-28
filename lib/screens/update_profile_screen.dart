// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailor_desk_app/services/tailor_auth.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _tailorId;
  String? _currentEmail;

  @override
  void initState() {
    super.initState();
    _loadTailorData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadTailorData() async {
    setState(() => _isLoading = true);

    try {
      _tailorId = TailorAuth.getCurrentTailorId();
      
      if (_tailorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login again'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection("tailors")
          .doc(_tailorId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _shopNameController.text = data['shop_name'] ?? '';
        _shopAddressController.text = data['shop_address'] ?? '';
        _emailController.text = data['email'] ?? '';
        _currentEmail = data['email'] ?? '';
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading tailor data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updateData = {
        "name": _nameController.text.trim(),
        "shop_name": _shopNameController.text.trim(),
        "shop_address": _shopAddressController.text.trim(),
        "updated_at": Timestamp.now(),
      };

      // If email changed, update it too
      if (_emailController.text.trim() != _currentEmail) {
        updateData["email"] = _emailController.text.trim();
      }

      await FirebaseFirestore.instance
          .collection("tailors")
          .doc(_tailorId)
          .update(updateData);

      // Update current tailor data in TailorAuth
      final updatedDoc = await FirebaseFirestore.instance
          .collection("tailors")
          .doc(_tailorId)
          .get();
      
      if (updatedDoc.exists) {
        final data = updatedDoc.data()!;
        // Update the stored tailor data
        final currentTailor = TailorAuth.getCurrentTailor();
        if (currentTailor != null) {
          currentTailor['name'] = data['name'];
          currentTailor['shop_name'] = data['shop_name'];
          currentTailor['shop_address'] = data['shop_address'];
          currentTailor['email'] = data['email'];
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Profile updated successfully ✅',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A9E5C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isEmail = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 20,
              color: AppColors.neutral.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.neutral.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.neutral.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label';
            }
            if (isEmail) {
              final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Enter a valid email address';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF1A1A2E),
        ),
        title: const Text(
          'Update Profile',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEF2)),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name
                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),

                    // Shop Name
                    _buildTextField(
                      label: 'Shop Name',
                      controller: _shopNameController,
                      icon: Icons.store_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Shop Address
                    _buildTextField(
                      label: 'Shop Address',
                      controller: _shopAddressController,
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _buildTextField(
                      label: 'Email Address',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      isEmail: true,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Update Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cancel
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}