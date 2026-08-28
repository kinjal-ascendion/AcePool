import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/presentation/bloc/route_matching_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class RouteMatchingPage extends StatefulWidget {
  const RouteMatchingPage({super.key});

  @override
  State<RouteMatchingPage> createState() => _RouteMatchingPageState();
}

class _RouteMatchingPageState extends State<RouteMatchingPage> {
  double radius = 0.0;
  late final TextEditingController _radiusController;
  late final RouteMatchingBloc _bloc;
  int _lastSavedTick = 0;

  @override
  void initState() {
    super.initState();
    _radiusController = TextEditingController(text: "0.0");
    _bloc = sl<RouteMatchingBloc>()..add(const RouteMatchingStarted());
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<RouteMatchingBloc, RouteMatchingState>(
        listenWhen: (previous, current) =>
            (previous.status != current.status &&
                current.status == RouteMatchingStatus.loaded) ||
            previous.savedTick != current.savedTick ||
            previous.saveError != current.saveError,
        listener: (context, state) {
          if (state.status == RouteMatchingStatus.loaded &&
              state.savedTick == 0 &&
              state.saveError == null) {
            setState(() {
              radius = state.radius;
              _radiusController.text = radius.toStringAsFixed(1);
            });
          }
          if (state.savedTick != _lastSavedTick) {
            _lastSavedTick = state.savedTick;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Radius saved: ${radius < 1 ? '${(radius * 1000).round()} m' : '${radius.toStringAsFixed(1)} km'}",
                ),
              ),
            );
            Navigator.pop(context, radius);
          }
          if (state.saveError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to save: ${state.saveError}")),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 26),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Route Matching',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.mulish(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D1D1D),
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          buildRadiusCard(),
                          const Spacer(),
                          buildNoRideCard(),
                          const SizedBox(height: 20),
                          buildButtons(state),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
    Widget buildRadiusCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFBBBEC5), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "RADIUS LIMIT",
          style: GoogleFonts.mulish(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: const Color(0xFF4C515B),
            height: 15 / 14,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          "Accept riders within a set radius from your location.",
          style: GoogleFonts.mulish(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF757474),
            height: 24 / 16,
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Text(
              "0 km",
              style: GoogleFonts.mulish(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: const Color(0xFF1D1D1D),
                height: 19.5 / 16,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: const Color(0xFF308666),
                  inactiveTrackColor: AppColors.grey200,
                  thumbColor: const Color(0xFF308666),
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                ),
                child: Slider(
                  value: radius,
                  min: 0.0,
                  max: 10,
                  onChanged: (value) {
                    setState(() {
                      radius = value;
                      _radiusController.text = radius.toStringAsFixed(1);
                    });
                  },
                ),
              ),
            ),
            Text(
              "10 km",
              style: GoogleFonts.mulish(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: const Color(0xFF757474),
                height: 18 / 16,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.grey200,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _radiusController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.end,
                      style: GoogleFonts.mulish(
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: const Color(0xFF757474),
                        height: 18 / 16,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.only(right: 4),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          setState(() {
                            radius = parsed.clamp(0.0, 10.0);
                          });
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      "km",
                      style: GoogleFonts.mulish(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF757474),
                        height: 18 / 16,
                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.grey200,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (radius < 10) {
                                setState(() {
                                  radius = (radius + 0.5).clamp(0.0, 10.0);
                                  _radiusController.text = radius.toStringAsFixed(1);
                                });
                              }
                            },
                            child: const Icon(
                              Icons.keyboard_arrow_up,
                              size: 14,
                              color: Color(0xFF757474),
                            ),
                          ),
                        ),
                        Divider(height: 1, color: AppColors.grey200),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (radius > 0) {
                                setState(() {
                                  radius = (radius - 0.5).clamp(0.0, 10.0);
                                  _radiusController.text = radius.toStringAsFixed(1);
                                });
                              }
                            },
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 14,
                              color: Color(0xFF757474),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Set a radius from your location",
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF757474),
                  height: 24 / 16,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget buildNoRideCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFFBBBEC5),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          color: Color(0xFF1E1E1E),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nothing nearby yet",
                style: GoogleFonts.mulish(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: const Color(0xFF1E1E1E),
                  height: 17 / 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "We couldn't find any rides within your selected radius. Increase the radius or try again later.",
                style: GoogleFonts.mulish(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: const Color(0xFF4C515B),
                  height: 18 / 14,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.close),
          iconSize: 20,
        ),
      ],
    ),
  );
}

Widget buildButtons(RouteMatchingState state) {
  return Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: state.isSaving ? null : () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1D1D1D),
              side: BorderSide(color: AppColors.grey300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Cancel",
              style: GoogleFonts.mulish(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),

      const SizedBox(width: 16),

      Expanded(
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: state.isSaving
                ? null
                : () => _bloc.add(RouteMatchingSaveRequested(radius)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : Text(
                  "Save Changes",
                  style: GoogleFonts.mulish(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.0,
                  ),
                ),
          ),
        ),
      ),
    ],
  );
}
  }