import 'package:flutter/material.dart';
import 'package:acepool/features/home/presentation/widgets/location_field.dart';

class LocationSwapRow extends StatelessWidget {
  const LocationSwapRow({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    required this.onSwap,
  });

  final String? fromAddress;
  final String? toAddress;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            children: [
              LocationField(
                address: fromAddress,
                placeholder: 'Choose home location',
                isFilled: false,
                // TODO: open a map/places location picker once that feature exists
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              LocationField(
                address: toAddress,
                placeholder: 'Choose office location',
                isFilled: true,
                // TODO: open a map/places location picker once that feature exists
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onSwap,
          icon: const Icon(Icons.swap_vert, color: Colors.black87),
        ),
      ],
    );
  }
}
