import 'package:flutter/material.dart';

/// Local design tokens for the Payment Methods card. Kept here (not in
/// AppColors) until these values are confirmed against the design system.
class _PayColors {
  _PayColors._();

  static const Color brandGreen = Color(0xFF1E8E5A);
  static const Color mintTint = Color(0xFFEAF7EF);
  static const Color ink = Color(0xFF1A1A1A);

  /// Body/label grey text (darkened from #8A8A8A per design feedback).
  static const Color bodyGray = Color(0xFF757575);

  /// Idle grey for the UPI icon badge — kept at the original shade since
  /// only font colors were darkened.
  static const Color iconIdle = Color(0xFF8A8A8A);
  static const Color borderGray = Color(0xFFE5E5E5);
  static const Color badgeGray = Color(0xFFF3F3F3);
  static const Color radioIdle = Color(0xFFC4C4C4);
  static const Color cashInk = Color(0xFF333333);

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
          const Text(
            "Receive Earnings Via",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _PayColors.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            "Choose how passengers pay and how you collect",
            style: TextStyle(
              color: _PayColors.bodyGray,
              fontSize: 12,
              height: 1.3,
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
          color: isSelected ? _PayColors.mintTint : Colors.white,
          border: Border.all(
            color: isSelected ? _PayColors.brandGreen : _PayColors.borderGray,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _MethodIcon(value: value, selected: isSelected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _PayColors.ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _PayColors.bodyGray,
                      fontSize: 13,
                      height: 1.3,
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
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: selected ? Colors.white : _PayColors.badgeGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: value == "UPI"
            ? Icon(
                Icons.currency_rupee,
                size: 20,
                color: selected ? _PayColors.brandGreen : _PayColors.iconIdle,
              )
            : const _StackedNotesIcon(),
      ),
    );
  }
}

/// Two overlapping banknotes to read as "stacked cash notes".
class _StackedNotesIcon extends StatelessWidget {
  const _StackedNotesIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-2, 2),
            child: const Icon(
              Icons.payments_outlined,
              size: 17,
              color: Color(0x66333333),
            ),
          ),
          Transform.translate(
            offset: const Offset(2, -2),
            child: const Icon(
              Icons.payments_outlined,
              size: 17,
              color: _PayColors.cashInk,
            ),
          ),
        ],
      ),
    );
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