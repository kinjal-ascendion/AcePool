import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class RouteMatchingPage extends StatefulWidget {
  const RouteMatchingPage({super.key});

  @override
  State<RouteMatchingPage> createState() => _RouteMatchingPageState();
}

class _RouteMatchingPageState extends State<RouteMatchingPage> {
  double radius = 0.0;
  late final TextEditingController _radiusController;
  bool _isSaving = false;
  
  static final _db = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'acepool',
);

  Future<void> _saveRadius() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  await _db.collection('users').doc(uid).set(
    {
      'routeMatchingRadius': radius,
    },
    SetOptions(merge: true),
  );
}
@override
void initState() {
  super.initState();
  _radiusController = TextEditingController(text: "0.0");
  _loadRadius();
}

@override
void dispose() {
  _radiusController.dispose();
  super.dispose();
}

Future<void> _loadRadius() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final doc =
      await _db.collection('users').doc(uid).get();

  if (!doc.exists) {
    setState(() {
      radius = 0.0;
      _radiusController.text = "0.0";
    });
    return;
  }

  final data = doc.data();

  setState(() {
    radius =
        (data?['routeMatchingRadius'] as num?)?.toDouble() ?? 0.0;
    _radiusController.text = radius.toStringAsFixed(1);
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Route Matching",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),

      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [

              buildRadiusCard(),

              const Spacer(),

              buildNoRideCard(),

              const SizedBox(height: 20),

              buildButtons(),
            ],
          ),
        ),
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
        const Text(
          "RADIUS LIMIT",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          "Accept riders within a set radius from your location.",
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            const Text(
              "0 km",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: radius,
                  min: 0.0,
                  max: 10,
                  divisions: 20,
                  activeColor: AppColors.primaryGreen,
                  inactiveColor: AppColors.grey200,
                  onChanged: (value) {
                    setState(() {
                      radius = value;
                      _radiusController.text = radius.toStringAsFixed(1);
                    });
                  },
                ),
              ),
            ),
            const Text(
              "10 km",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
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
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text(
                      "km",
                      style: TextStyle(fontSize: 13, color: AppColors.black54),
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
            const Expanded(
              child: Text(
                "Set a radius from your location",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.black54,
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
        color: Colors.grey.shade300,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          color: Colors.black54,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Nothing nearby yet",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "We couldn't find any rides within your selected radius. Increase the radius or try again later.",
                style: TextStyle(
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}

Widget buildButtons() {
  return Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: _isSaving ? null : () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Cancel"),
          ),
        ),
      ),

      const SizedBox(width: 16),

      Expanded(
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : () async {
              setState(() {
                _isSaving = true;
              });

              try {
                await _saveRadius();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Radius saved: ${radius < 1 ? (radius * 1000).round().toString() + ' m' : radius.toStringAsFixed(1) + ' km'}",
                    ),
                  ),
                );

                Navigator.pop(context, radius);
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isSaving = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to save: $e")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving 
              ? const SizedBox(
                  height: 20, 
                  width: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : const Text("Save Changes"),
          ),
        ),
      ),
    ],
  );
}
  }