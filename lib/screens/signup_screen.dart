// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:tailor_desk_app/screens/login_screen.dart';
import 'package:tailor_desk_app/services/tailor_auth.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    nameController.dispose();
    shopNameController.dispose();
    addressController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> handleSignup() async {
    if (nameController.text.isEmpty ||
        shopNameController.text.isEmpty ||
        addressController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await TailorAuth.signupTailor(
      name: nameController.text,
      shopName: shopNameController.text,
      shopAddress: addressController.text,
      email: emailController.text,
      password: passwordController.text,
    );

    setState(() => isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully")),
      );

      nameController.clear();
      shopNameController.clear();
      addressController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create your account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set up your tailor profile to get started',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 28),

                    _buildSectionLabel('Personal details'),
                    const SizedBox(height: 12),
                    _buildField(
                      hint: 'Full name',
                      controller: nameController,
                      icon: Icons.person_outline_rounded,
                    ),
                    _buildField(
                      hint: 'Email address',
                      controller: emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 8),
                    _buildSectionLabel('Shop details'),
                    const SizedBox(height: 12),
                    _buildField(
                      hint: 'Shop name',
                      controller: shopNameController,
                      icon: Icons.storefront_outlined,
                    ),
                    _buildField(
                      hint: 'Shop address',
                      controller: addressController,
                      icon: Icons.location_on_outlined,
                    ),

                    const SizedBox(height: 8),
                    _buildSectionLabel('Security'),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      hint: 'Password',
                      controller: passwordController,
                      obscure: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      hint: 'Confirm password',
                      controller: confirmPasswordController,
                      obscure: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),

                    const SizedBox(height: 28),
                    _buildCreateButton(),
                    const SizedBox(height: 20),
                    _buildLoginRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tailor Desk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'New account setup',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.content_cut_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary.withValues(alpha: 0.8),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(color: Colors.grey.shade200, thickness: 1),
        ),
      ],
    );
  }

  Widget _buildField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 20),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Create account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: const Text(
            'Sign in',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}