import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
final bool isLoading;

const LoginButton({
  super.key,
  required this.onPressed,
  required this.isLoading,
});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 27, 138, 63),
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 56),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    child: isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Text(
            "Log In",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
  ),
);
  }
}