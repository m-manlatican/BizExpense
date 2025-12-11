import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:flutter/material.dart';

class FormLabel extends StatelessWidget {
  final String text;
  const FormLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class RoundedTextField extends StatelessWidget {
  final String? hintText;
  final Widget? prefix;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final int maxLines;
  final TextEditingController? controller;
  final bool obscureText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const RoundedTextField({
    super.key,
    this.hintText,
    this.prefix,
    this.suffixIcon,
    this.keyboardType,
    this.readOnly = false,
    this.maxLines = 1,
    this.controller,
    this.obscureText = false,
    this.errorText,
    this.onChanged,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // Optimized: Removed the unnecessary Column wrapper
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onSubmitted: onFieldSubmitted,
      
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: prefix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: IconTheme(
                  data: IconThemeData(
                    color: errorText != null ? AppColors.expense : AppColors.textPrimary
                  ), 
                  child: prefix!
                ),
              ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        
        errorText: errorText, 
        errorStyle: const TextStyle(
          color: AppColors.expense, 
          fontWeight: FontWeight.w600,
          fontSize: 12
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.expense, width: 2),
        ),
        
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}