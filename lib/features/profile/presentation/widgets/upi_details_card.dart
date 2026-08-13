import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "UPI Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Linked UPI ID For Instant Payout",
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 12,
                        height: 1.3,
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
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFC4C4C4),
                ),
                label: Text(
                  "Edit",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isEditing
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFA8A8A8),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isEditing
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFA8A8A8),
                  side: BorderSide(
                    color: isEditing
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFC4C4C4),
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
          ),

          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.only(left: 4, top: 12, bottom: 6),
            child: Text(
              "PHONE NO",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Color(0xFF757575),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (label != null) ...[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF757575),
                ),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isEditing
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFF757575),
              ),
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFC4C4C4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
