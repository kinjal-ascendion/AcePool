import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentSaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PaymentSaveButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D1D1D),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          "Save Changes",
          style: GoogleFonts.mulish(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 20 / 16,
          ),
        ),
      ),
    );
  }
}