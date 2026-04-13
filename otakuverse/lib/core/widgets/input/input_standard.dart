import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';

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
            color: _isFocused ? AppColors.primary : AppColors.textMuted,
            fontSize: 14,
          ),
          helperText: widget.helperText,
          helperStyle: const TextStyle(
            color: AppColors.textDisabled,
            fontSize: 12,
          ),
          filled: true,
          fillColor: widget.enabled ? AppColors.bgCard : AppColors.bgCard.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),

          // Prefix icon
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: _isFocused ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                )
              : null,

          // Suffix icon (password toggle)
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : null,

          // Borders
          enabledBorder: _border(AppColors.border),
          focusedBorder: _border(AppColors.primary),
          errorBorder: _border(AppColors.error),
          focusedErrorBorder: _border(AppColors.error),
          disabledBorder: _border(AppColors.bgCard),

          // Error style
          errorStyle: const TextStyle(
            color: AppColors.error,
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