import 'package:flutter/material.dart';
import 'package:madmet/theme/color.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor = primary,
    this.height = 60,
    this.borderRadius = 15,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
