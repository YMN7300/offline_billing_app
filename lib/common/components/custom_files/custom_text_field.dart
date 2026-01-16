import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For inputFormatters

class CustomTextField extends StatelessWidget {
  final String? helperText;
  final String? labelText;
  final TextEditingController? controller;
  final IconData? icon;
  final Color? iconColor;

  // Optional parameters
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final bool obscureText;

  // Newly added optional parameters
  final bool readOnly;
  final void Function(String)? onChanged;

  // NEW: Validator for form validation
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    this.helperText,
    this.labelText,
    this.controller,
    this.icon,
    this.iconColor,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1, // default to 1 line
    this.readOnly = false,
    this.onChanged,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      readOnly: readOnly,
      onChanged: onChanged,
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        suffixIcon:
            icon != null ? Icon(icon, color: iconColor ?? Colors.grey) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }
}
