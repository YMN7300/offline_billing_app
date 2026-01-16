import 'package:flutter/material.dart';

class CustomDropdownField extends StatelessWidget {
  final String? value;
  // final String helperText;
  final String hintText;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const CustomDropdownField({
    Key? key,
    required this.value,
    // required this.helperText,
    required this.hintText,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        // // helperText: helperText,
        // helperStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
      hint: Text(hintText),
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }
}

// DropdownButtonFormField<String>(
// value: selectedUnit,
// hint: Text("Select Unit"),
// items: [
// DropdownMenuItem(value: 'Kg', child: Text('Kilogram')),
// DropdownMenuItem(value: 'Litre', child: Text('Litre')),
// DropdownMenuItem(value: 'Piece', child: Text('Piece')),
// DropdownMenuItem(value: 'Dozen', child: Text('Dozen')),
// ],
// onChanged: (String? newValue) {
// setState(() {
// selectedUnit = newValue;
// });
// },
// decoration: InputDecoration(
// labelText: 'Unit',
// border: OutlineInputBorder(),
// ),
// ),
