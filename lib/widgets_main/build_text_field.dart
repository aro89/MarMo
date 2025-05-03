import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget buildTextField({
  required TextEditingController controller,
  required String hintText,
  bool obscureText = false,
  bool readOnly = false,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  Function()? onTap,
  bool required = true,
  Widget? prefixIcon,
  int? maxLines = 1,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onTap: onTap,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: prefixIcon,
      ),
      validator: required
          ? (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      }
          : null,
    ),
  );
}