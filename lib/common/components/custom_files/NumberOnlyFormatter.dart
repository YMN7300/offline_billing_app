import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberOnlyFormatter extends TextInputFormatter {
  final BuildContext context;
  final void Function(String message)? onError;

  NumberOnlyFormatter(this.context, {this.onError});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String input = newValue.text;

    if (_isValidDecimal(input)) {
      return newValue;
    } else {
      if (onError != null) {
        onError!("Only numbers allowed");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Only numbers allowed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return oldValue;
    }
  }

  bool _isValidDecimal(String input) {
    if (input.isEmpty) return true;

    final parts = input.split('.');
    if (parts.length > 2) return false;

    final beforeDecimal = parts[0];
    final afterDecimal = parts.length > 1 ? parts[1] : '';

    if (beforeDecimal.isNotEmpty && int.tryParse(beforeDecimal) == null) {
      return false;
    }

    if (afterDecimal.isNotEmpty) {
      if (int.tryParse(afterDecimal) == null || afterDecimal.length > 5) {
        return false;
      }
    }

    return true;
  }
}

class GstinFormatter extends TextInputFormatter {
  final BuildContext context;
  final void Function(String message)? onError;

  GstinFormatter(this.context, {this.onError});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Convert to uppercase
    final uppercaseText = newValue.text.toUpperCase();

    // Allow empty input
    if (uppercaseText.isEmpty) return newValue;

    // GSTIN pattern: 15 alphanumeric characters
    final regExp = RegExp(r'^[A-Z0-9]{0,15}$');

    if (regExp.hasMatch(uppercaseText)) {
      return newValue.copyWith(
        text: uppercaseText,
        selection: TextSelection.collapsed(offset: uppercaseText.length),
      );
    } else {
      if (onError != null) {
        onError!("GSTIN must contain only letters and numbers");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'GSTIN must contain only letters and numbers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return oldValue;
    }
  }
}
