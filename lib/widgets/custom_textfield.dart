import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final bool obscureText;
  final IconData? icon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.obscureText = false,
    this.icon,
    this.suffix,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  // Helper method to keep border code clean
  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        // prefixIcon inside InputDecoration fixes the alignment issue for multi-line fields
        prefixIcon: icon != null 
            ? Icon(icon, color: const Color(0xFF4A90E2)) 
            : null,
        suffixIcon: suffix,
        isDense: true, 
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        
        // Border Logic
        border: _border(Colors.grey.shade300),
        enabledBorder: _border(Colors.grey.shade300),
        focusedBorder: _border(const Color(0xFF4A90E2), width: 2),
        errorBorder: _border(Colors.red.shade400),
        focusedErrorBorder: _border(Colors.red.shade400, width: 2),
        
        // Styling for the error text itself
        errorStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}