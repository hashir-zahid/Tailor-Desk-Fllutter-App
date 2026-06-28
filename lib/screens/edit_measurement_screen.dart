// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailor_desk_app/services/measurement_service.dart';
import 'package:tailor_desk_app/utils/app_colors.dart';

class EditMeasurementScreen extends StatefulWidget {
  final String measurementId;
  final String customerId;

  const EditMeasurementScreen({super.key, required this.measurementId, required this.customerId});

  @override
  State<EditMeasurementScreen> createState() => _EditMeasurementScreenState();
}

class _EditMeasurementScreenState extends State<EditMeasurementScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _shoulderController = TextEditingController();
  final _sleeveController = TextEditingController();
  final _neckController = TextEditingController();
  final _shirtController = TextEditingController();
  final _trouserController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _customerName = '';
  String _customerPhone = '';

  late AnimationController _animController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnimations = List.generate(6, (i) {
      final start = 0.1 * i;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(CurvedAnimation(parent: _animController,
              curve: Interval(start.clamp(0, 1), end, curve: Curves.easeOutCubic)));
    });
    _fadeAnimations = List.generate(6, (i) {
      final start = 0.1 * i;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _animController,
          curve: Interval(start.clamp(0, 1), end, curve: Curves.easeOut)));
    });
    _loadMeasurement();
  }

  Future<void> _loadMeasurement() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("measurements").doc(widget.measurementId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _chestController.text = data['chest'].toString();
        _waistController.text = data['waist'].toString();
        _hipController.text = data['hip'].toString();
        _shoulderController.text = data['shoulder'].toString();
        _sleeveController.text = data['sleeve_length'].toString();
        _neckController.text = data['neck'].toString();
        _shirtController.text = data['shirt_length'].toString();
        _trouserController.text = data['trouser_length'].toString();
        _priceController.text = data['price'].toString();
      }
      final customerDoc = await FirebaseFirestore.instance
          .collection("customers").doc(widget.customerId).get();
      if (customerDoc.exists) {
        final d = customerDoc.data()!;
        _customerName = d['name'] ?? 'Unknown';
        _customerPhone = d['phone'] ?? '';
      }
      setState(() => _isLoading = false);
      _animController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _chestController.dispose(); _waistController.dispose(); _hipController.dispose();
    _shoulderController.dispose(); _sleeveController.dispose(); _neckController.dispose();
    _shirtController.dispose(); _trouserController.dispose(); _priceController.dispose();
    _scrollController.dispose(); _animController.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) => FadeTransition(
        opacity: _fadeAnimations[index],
        child: SlideTransition(position: _slideAnimations[index], child: child),
      );

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final result = await MeasurementService.updateMeasurement(
        measurementId: widget.measurementId,
        chest: double.parse(_chestController.text),
        waist: double.parse(_waistController.text),
        hip: double.parse(_hipController.text),
        shoulder: double.parse(_shoulderController.text),
        sleeveLength: double.parse(_sleeveController.text),
        neck: double.parse(_neckController.text),
        shirtLength: double.parse(_shirtController.text),
        trouserLength: double.parse(_trouserController.text),
        price: double.parse(_priceController.text),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Measurement updated!', style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: const Color(0xFF1A9E5C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading)
              Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _animated(0, _buildCustomerCard()),
                        const SizedBox(height: 24),
                        _animated(1, _buildSectionLabel('Body measurements')),
                        const SizedBox(height: 14),
                        _animated(2, _buildMeasurementGrid()),
                        const SizedBox(height: 24),
                        _animated(3, _buildSectionLabel('Pricing')),
                        const SizedBox(height: 14),
                        _animated(4, _buildPriceField()),
                        const SizedBox(height: 32),
                        _animated(5, _buildSaveButton()),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade500),
                            child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF1A1A2E),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Edit measurement',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E), letterSpacing: -0.3)),
                if (_customerName.isNotEmpty)
                  Text(_customerName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_customerName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(_customerPhone,
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Editing',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(width: 3, height: 18,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(label.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.primary.withValues(alpha: 0.7), letterSpacing: 1.1)),
      ],
    );
  }

  Widget _buildMeasurementGrid() {
    final fields = [
      ('Chest', _chestController), ('Waist', _waistController),
      ('Hip', _hipController), ('Shoulder', _shoulderController),
      ('Sleeve', _sleeveController), ('Neck', _neckController),
      ('Shirt Length', _shirtController), ('Trouser', _trouserController),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fields.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.55,
      ),
      itemBuilder: (_, i) => _buildMeasurementTile(fields[i].$1, fields[i].$2),
    );
  }

  Widget _buildMeasurementTile(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.primary.withValues(alpha: 0.6), letterSpacing: 0.2)),
          const SizedBox(height: 6),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary),
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.grey.shade300),
                suffixText: 'in',
                suffixStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none,
                errorStyle: const TextStyle(fontSize: 10, height: 0.8),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter $label';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid number';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments_outlined, size: 22, color: AppColors.primary.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total price',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.primary.withValues(alpha: 0.6))),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
                  decoration: InputDecoration(
                    prefixText: 'Rs. ',
                    prefixStyle: TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.w700),
                    isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(fontSize: 20, color: Colors.grey.shade300, fontWeight: FontWeight.w700),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Price is required';
                    final n = double.tryParse(v);
                    if (n == null) return 'Invalid price';
                    if (n < 0) return 'Cannot be negative';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveMeasurement,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSaving
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Update measurement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1)),
                ],
              ),
      ),
    );
  }
}