// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:tailor_desk_app/screens/home_screen.dart';
import 'package:tailor_desk_app/services/customer_service.dart';
import 'package:tailor_desk_app/services/tailor_auth.dart';
import 'package:tailor_desk_app/widgets/custom_textfield.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;
  late AnimationController _animController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimations = List.generate(5, (i) {
      final start = 0.1 * i;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start.clamp(0, 1), end, curve: Curves.easeOutCubic),
        ),
      );
    });
    _fadeAnimations = List.generate(5, (i) {
      final start = 0.1 * i;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start.clamp(0, 1), end, curve: Curves.easeOut),
        ),
      );
    });
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) => FadeTransition(
    opacity: _fadeAnimations[index],
    child: SlideTransition(position: _slideAnimations[index], child: child),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final tailorId = TailorAuth.getCurrentTailorId();
    if (tailorId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await CustomerService.addCustomer(
      tailorId: tailorId,
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      note: _noteController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                '${_nameController.text.trim()} added successfully',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(initialIndex: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  children: [
                    _animated(0, _buildAvatarSection()),
                    const SizedBox(height: 28),
                    _animated(
                      1,
                      _SectionCard(
                        title: 'Basic Information',
                        icon: Icons.badge_outlined,
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            hint: 'e.g. Ahmed Khan',
                            label: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Customer name is required';
                              if (v.trim().length < 2)
                                return 'Name must be at least 2 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _phoneController,
                            hint: 'e.g. 0300-1234567',
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Phone number is required';
                              final digits = v.replaceAll(RegExp(r'\D'), '');
                              if (digits.length < 10)
                                return 'Enter a valid phone number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _animated(
                      2,
                      _SectionCard(
                        title: 'Optional Details',
                        icon: Icons.tune_rounded,
                        badge: 'Optional',
                        children: [
                          CustomTextField(
                            controller: _emailController,
                            hint: 'e.g. ahmed@email.com',
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final emailRegex = RegExp(
                                r'^[\w\.-]+@[\w\.-]+\.\w{2,}$',
                              );
                              if (!emailRegex.hasMatch(v.trim()))
                                return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _noteController,
                            hint: 'Any special notes about this customer...',
                            label: 'Note',
                            icon: Icons.sticky_note_2_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _animated(3, _buildSubmitButton()),
                    const SizedBox(height: 12),
                    _animated(
                      4,
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const HomeScreen(initialIndex: 1),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade500,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEF2))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(initialIndex: 1),
                ),
              );
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF1A1A2E),
          ),
          const Expanded(
            child: Text(
              'New Customer',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            onPressed: _clearForm,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text(
              'Clear',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 42,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'New Customer Profile',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary.withValues(alpha: 0.7),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add Customer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? badge;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: AppColors.primary.withValues(alpha: 0.08), height: 16),
          ...children,
        ],
      ),
    );
  }
}
