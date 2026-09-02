import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Local design tokens for the Payment Methods card. Kept here (not in
/// AppColors) until these values are confirmed against the design system.
class _PayColors {
  _PayColors._();

  static const Color brandGreen = Color(0xFF308666);
  static const Color mintTint = Color(0x0A308666);
  static const Color ink = Color(0xFF1D1D1D);

  /// Body/label grey text (darkened from #8A8A8A per design feedback).
  static const Color bodyGray = Color(0xFF757474);

  static const Color borderGray = Color(0xFFDDDDDD);
  static const Color badgeGray = Color(0x29DDDDDD);
  static const Color radioIdle = Color(0xFFC4C4C4);

  /// rgba(0, 0, 0, 0.04) — soft card shadow.
  static const Color cardShadow = Color(0x0A000000);
}

class PaymentMethodCard extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onChanged;

  const PaymentMethodCard({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PayColors.borderGray),
        boxShadow: const [
          BoxShadow(
            color: _PayColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Receive Earnings Via",
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _PayColors.ink,
              height: 20 / 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Choose how passengers pay and how you collect",
            style: GoogleFonts.mulish(
              color: _PayColors.bodyGray,
              fontSize: 14,
              height: 16 / 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          _paymentTile(title: "UPI", subtitle: "Instant transfer", value: "UPI"),
          const SizedBox(height: 10),
          _paymentTile(title: "Cash", subtitle: "Collect On Trip", value: "Cash"),
        ],
      ),
    );
  }

  Widget _paymentTile({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = selectedMethod == value;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
  color: isSelected
      ? _PayColors.mintTint
      : _PayColors.badgeGray,
  border: Border.all(
    color: isSelected
        ? _PayColors.brandGreen
        : _PayColors.borderGray,
    width: 1,
  ),
  borderRadius: BorderRadius.circular(12),
),
        child: Row(
          children: [
            Image.asset(
              value == "UPI"
      ? 'assets/images/currency_rupee_circle.png'
      : 'assets/images/universal_currency.png',
              width: 24,
              height: 24,
              color: Colors.black,
  colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.mulish(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w700,
                      fontSize: 16,
                      color: _PayColors.ink,
                      height: 20 / 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.mulish(
                      color: _PayColors.bodyGray,
                      fontSize: 14,
                      height: 16 / 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _RadioIndicator(selected: isSelected),
          ],
        ),
      ),
    );
  }
}

/// 32×32 rounded icon badge for a payment method.
class _MethodIcon extends StatelessWidget {
  final String value;
  final bool selected;

  const _MethodIcon({required this.value, required this.selected});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Two overlapping banknotes to read as "stacked cash notes".
class _StackedNotesIcon extends StatelessWidget {
  const _StackedNotesIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Two-layer radio: 20px outer ring (1.5px stroke) + 10px inner dot.
class _RadioIndicator extends StatelessWidget {
  final bool selected;

  const _RadioIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _PayColors.brandGreen : _PayColors.radioIdle,
          width: 1.5,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _PayColors.brandGreen,
                ),
              ),
            )
          : null,
    );
  }
}