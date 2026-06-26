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

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final showEye = widget.obscureText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.only(
            left: widget.prefixWidget != null ? 0 : 0,
            right: showEye || widget.suffixWidget != null ? 4 : 0,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(12),
            border: widget.errorText != null
                ? Border.all(color: Colors.red.shade400, width: 1.2)
                : null,
          ),
          child: Row(
            children: [
              if (widget.prefixWidget != null) widget.prefixWidget!,
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: _obscured,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  onChanged: widget.onChanged,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.prefixWidget != null ? 12 : 16,
                      vertical: 18,
                    ),
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
              ),
              if (showEye)
                GestureDetector(
                  onTap: () => setState(() => _obscured = !_obscured),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      _obscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black38,
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
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
