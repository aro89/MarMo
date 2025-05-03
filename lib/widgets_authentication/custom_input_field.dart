import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final List<String>? autofillHints;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350, // Less wide
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textAlign: TextAlign.left,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Colors.grey,
              width: 2.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Colors.blue,
              width: 3.0,
            ),
          ),
        ),
      ),
    );
  }
}
