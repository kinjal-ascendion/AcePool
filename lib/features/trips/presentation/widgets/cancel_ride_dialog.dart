import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CancelRideDialog extends StatefulWidget {
  final String fromAddress;
  final String toAddress;
  final int coPassengersCount;
  final Future<void> Function(String reason)? onCancelConfirmed;

  const CancelRideDialog({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    required this.coPassengersCount,
    this.onCancelConfirmed,
  });

  @override
  State<CancelRideDialog> createState() => _CancelRideDialogState();
}

class _CancelRideDialogState extends State<CancelRideDialog> {
  String? _selectedReason;
  bool _isLoading = false;
  final _otherReasonController = TextEditingController();
  final List<String> _reasons = [
    'Booked by mistake',
    'Plans changed',
    'Vehicle or driver issue',
    'Other',
  ];

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  bool get _isButtonEnabled {
    if (_selectedReason == null) return false;
    if (_selectedReason == 'Other') {
      return _otherReasonController.text.trim().isNotEmpty;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cancel this Ride?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : () => Navigator.pop(context),
                    child: Icon(Icons.close, color: AppColors.grey600, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.fromAddress.split(',').first.toUpperCase()} - ${widget.toAddress.split(',').first.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.coPassengersCount} co-passengers are relying on this trip',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFBBBEC5)),
              const SizedBox(height: 16),
              const Text(
                'Why are you cancelling?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              ..._reasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return Theme(
                  data: Theme.of(context).copyWith(
                    unselectedWidgetColor: const Color(0xFF6B7280),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFF6B7280),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        value: reason,
                        groupValue: _selectedReason,
                        onChanged: (value) {
                          setState(() {
                            _selectedReason = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: const Color(0xFF1E1E1E),
                        controlAffinity: ListTileControlAffinity.leading,
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -2),
                      ),
                      if (reason == 'Other' && _selectedReason == 'Other')
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: TextField(
                            controller: _otherReasonController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Mention your reason',
                              hintStyle: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFFBBBEC5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFFBBBEC5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1E1E1E)),
                              ),
                            ),
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBBBEC5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Keep Ride',
                        style: TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (_isLoading || !_isButtonEnabled)
                          ? null
                          : () async {
                              final finalReason = _selectedReason == 'Other'
                                  ? _otherReasonController.text.trim()
                                  : _selectedReason;

                              if (widget.onCancelConfirmed != null) {
                                setState(() => _isLoading = true);
                                try {
                                  await widget.onCancelConfirmed!(finalReason!);
                                } finally {
                                  if (mounted) setState(() => _isLoading = false);
                                }
                              } else {
                                Navigator.pop(context, finalReason);
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: (_isLoading || !_isButtonEnabled)
                              ? const Color(0xFFBBBEC5)
                              : const Color(0xFFDC2626),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFDC2626),
                              ),
                            )
                          : Text(
                              'Cancel Ride',
                              style: TextStyle(
                                color: (_isLoading || !_isButtonEnabled)
                                    ? const Color(0xFFBBBEC5)
                                    : const Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
