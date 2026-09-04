import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class UpiDetailsCard extends StatelessWidget {
  final bool isEditing;

  final TextEditingController upiController;
  final TextEditingController phoneController;

  /// Shown as the left-side label of the phone row (the user's name).
  final String phoneLabel;

  final VoidCallback onEdit;

  const UpiDetailsCard({
    super.key,
    required this.isEditing,
    required this.upiController,
    required this.phoneController,
    required this.phoneLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDDDDD)),
        boxShadow: const [
          BoxShadow(
            // rgba(0, 0, 0, 0.04) — soft card shadow.
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "UPI Details",
                      style: GoogleFonts.mulish(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1D1D1D),
                        height: 20 / 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Linked UPI ID For Instant Payout",
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF757474),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 16 / 14,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onEdit,
               icon: Icon(
  Icons.edit,
  size: 14,
  color: isEditing
      ? Colors.white
      : const Color(0xFF1D1D1D),
),
                label: Text(
                  "Edit",
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isEditing
    ? Colors.white
    : const Color(0xFF1D1D1D),
                    height: 16 / 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
  backgroundColor: isEditing
      ? const Color(0xFF000000)
      : Colors.white,
  foregroundColor: isEditing
      ? Colors.white
      : const Color(0xFF1D1D1D),
  side: BorderSide(
    color: isEditing
        ? const Color(0xFF000000)
        : const Color(0xFFDDDDDD),
    width: 1,
  ),
  padding: const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 6,
  ),
  shape: const StadiumBorder(),
  minimumSize: Size.zero,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _fieldRow(
            label: "UPI Id",
            controller: upiController,
            hint: "upi id",
            isCapitalize: false,
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.only(left: 4, top: 12, bottom: 6),
            child: Text(
              "PHONE NO",
              style: GoogleFonts.mulish(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF757474),
                height: 16 / 12,
              ),
            ),
          ),

          // Username as the left-side label, always-editable input on the
          // right — no hint text inside the field.
          _fieldRow(
            label: phoneLabel,
            controller: phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
        ],
      ),
    );
  }

  /// Label + value row: optional gray label on the left, editable input on
  /// the right. No hint text — the label describes the field.
  Widget _fieldRow({
    String? label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool isCapitalize = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x29DDDDDD),
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (label != null) ...[
            Text(
              isCapitalize ? label.substring(0, 1).toUpperCase() + label.substring(1).toLowerCase() : label,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF757474),
                height: 16 / 14,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isEditing,
              textAlign: TextAlign.right,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: GoogleFonts.mulish(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F1923),
                height: 20 / 16,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF757474),
                  height: 16 / 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
