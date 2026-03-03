import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/core/constants/text_styles.dart';

class InputStandard extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool isPassword;
  final String? helperText;
  final TextInputType keyboardType;
  final bool enabled;
  final int maxLines;

  const InputStandard({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.validator,
    this.isPassword = false,
    this.helperText,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  State<InputStandard> createState() => _InputStandardState();
}

class _InputStandardState extends State<InputStandard> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscureText,
        keyboardType: widget.keyboardType,
        enabled: widget.enabled,
        maxLines: widget.isPassword ? 1 : widget.maxLines,
        validator: widget.validator,
        style: AppTextStyles.inputHint,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: _isFocused ? AppColors.crimsonRed : AppColors.mediumGray,
            fontSize: 14,
          ),
          helperText: widget.helperText,
          helperStyle: const TextStyle(
            color: AppColors.lightGray,
            fontSize: 12,
          ),
          filled: true,
          fillColor: widget.enabled ? AppColors.darkGray : AppColors.darkGray.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),

          // Prefix icon
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: _isFocused ? AppColors.crimsonRed : AppColors.mediumGray,
                  size: 20,
                )
              : null,

          // Suffix icon (password toggle)
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.mediumGray,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : null,

          // Borders
          enabledBorder: _border(AppColors.border),
          focusedBorder: _border(AppColors.crimsonRed),
          errorBorder: _border(AppColors.errorRed),
          focusedErrorBorder: _border(AppColors.errorRed),
          disabledBorder: _border(AppColors.darkGray),

          // Error style
          errorStyle: const TextStyle(
            color: AppColors.errorRed,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: 1),
    );
  }
}