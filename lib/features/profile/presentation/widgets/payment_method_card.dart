import 'package:flutter/material.dart';

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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Receive Earnings Via",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              "Choose how passengers pay and how you collect",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 10),

            _paymentTile(
              icon: Icons.account_balance_wallet_outlined,
              title: "UPI",
              subtitle: "Instant transfer",
              value: "UPI",
            ),

            const SizedBox(height: 10),

            _paymentTile(
              icon: Icons.payments_outlined,
              title: "Cash",
              subtitle: "Collect On Trip",
              value: "Cash",
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Builder(
      builder: (context) {
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [

                Icon(icon),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                           fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                Radio<String>(
                  value: value,
                  groupValue: selectedMethod,
                  activeColor: Colors.green,
                  onChanged: (v) {
                    onChanged(v!);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}