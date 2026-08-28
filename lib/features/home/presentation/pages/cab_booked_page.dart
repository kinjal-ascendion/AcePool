import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CabBookedPage extends StatelessWidget {
  const CabBookedPage({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    required this.estimatedFare,
    required this.seatCount,
    required this.date,
    required this.time,
  });

  final String fromAddress;
  final String toAddress;
  final double estimatedFare;
  final int seatCount;
  final DateTime date;
  final TimeOfDay time;

  String _formatDate() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime() {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
          child: Column(
            children: [
              // SUCCESS ICON
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE3F5EA),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 36,
                    color: Color(0xFF1E8E5A),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // HEADING
              Text(
                'Cab Booked',
                textAlign: TextAlign.center,
                style: GoogleFonts.mulish(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 8),

              // SUBTEXT
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 320,
                ),
                child: Text(
                  'Your ride is confirmed. Sharing it with co-passengers.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8A8A8A),
                    height: 20 / 14,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // TRIP SUMMARY CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5E5E5),
                  ),
                ),
                child: Column(
                  children: [
                    // ROUTE + SHARE
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${fromAddress.trim()} - ${toAddress.trim()}'
                                .toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.mulish(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                              height: 20 / 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            // Share functionality can be added here later.
                          },
                          child: const Icon(
                            Icons.share,
                            size: 20,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    const Divider(
                      height: 1,
                      color: Color(0xFFEDEDED),
                    ),

                    // ESTIMATED FARE
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Fare',
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF8A8A8A),
                            ),
                          ),
                          Text(
                            '₹${estimatedFare.toStringAsFixed(0)}',
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E8E5A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SEATS
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Seats offered',
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF8A8A8A),
                            ),
                          ),Text(
  '$seatCount',
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color: Color(0xFFEDEDED),
                    ),

                    // DATE
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Color(0xFF1A1A1A),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            _formatDate(),
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color: Color(0xFFEDEDED),
                    ),

                    // TIME
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_outlined,
                            size: 18,
                            color: Color(0xFF1A1A1A),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            _formatTime(),
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // BACK TO HOME
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}