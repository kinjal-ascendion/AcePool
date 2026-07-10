import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.prefixWidget,
    this.suffixWidget,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final String? errorText;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured;
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showEye = widget.obscureText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: AppColors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.only(
            left: widget.prefixWidget != null ? 0 : 0,
            right: showEye || widget.suffixWidget != null ? 4 : 0,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.errorText != null
                  ? AppColors.red400
                  : _isFocused
                      ? AppColors.black
                      : AppColors.grey300,
              width: widget.errorText != null || _isFocused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (widget.prefixWidget != null) widget.prefixWidget!,
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: _obscured,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  onChanged: widget.onChanged,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: AppColors.placeholderGrey,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.prefixWidget != null ? 12 : 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(color: AppColors.black87, fontSize: 14),
                ),
              ),
              if (showEye)
                GestureDetector(
                  onTap: () => setState(() => _obscured = !_obscured),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      _obscured ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.black38,
                      size: 20,
                    ),
                  ),
                )
              else if (widget.suffixWidget != null)
                widget.suffixWidget!,
            ],
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.errorText!,
              style: TextStyle(color: AppColors.red600, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
