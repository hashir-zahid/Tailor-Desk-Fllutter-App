// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:tailor_desk_app/screens/signup_screen.dart';
import 'package:tailor_desk_app/services/tailor_auth.dart';
import 'package:tailor_desk_app/screens/home_screen.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);

    final result = await TailorAuth.loginTailor(
      email: emailController.text,
      password: passwordController.text,
    );

    setState(() => isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Successful")));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
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
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to manage your tailor desk',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildLabel('Email address'),
                    const SizedBox(height: 8),
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    _buildPasswordField(),
                    const SizedBox(height: 32),
                    _buildLoginButton(),
                    const SizedBox(height: 24),
                    _buildSignupRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.content_cut_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tailor Desk',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your complete tailoring workspace',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: 'you@example.com',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(
          Icons.email_outlined,
          color: Colors.grey.shade400,
          size: 20,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: Colors.grey.shade400,
          size: 20,
        ),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : handleLogin,
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
                'Sign in',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  Widget _buildSignupRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignupScreen()),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: const Text(
            'Create one',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
