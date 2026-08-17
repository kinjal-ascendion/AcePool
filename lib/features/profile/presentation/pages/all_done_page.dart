import 'package:flutter/material.dart';

class _AllDoneColors {
  _AllDoneColors._();

  static const Color ink = Color(0xFF1A1A1A);
  static const Color bodyGray = Color(0xFF8A8A8A);
  static const Color brandGreen = Color(0xFF1E8E5A);
  static const Color mintTint = Color(0xFFE3F5EA);
}

class AllDonePage extends StatelessWidget {
  final int passengerCount;
  final String? message;

  const AllDonePage({super.key, required this.passengerCount, this.message});

  @override
  Widget build(BuildContext context) {
    final topSpace = MediaQuery.sizeOf(context).height * 0.16;
    final subtext = message ??
        (passengerCount == 1
            ? 'Feedback submitted for 1 passenger.'
            : 'Feedback submitted for all $passengerCount passengers.');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 60,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 22,
            color: _AllDoneColors.ink,
          ),
          onPressed: () => Navigator.of(context).pop(),
          padding: const EdgeInsets.only(left: 16),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topSpace),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Center(
                    child: Semantics(
                      label: 'All feedback submitted',
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _AllDoneColors.mintTint,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          size: 36,
                          color: _AllDoneColors.brandGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'All Done',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _AllDoneColors.ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            subtext,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: _AllDoneColors.bodyGray,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _AllDoneColors.ink,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Back to Home'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}