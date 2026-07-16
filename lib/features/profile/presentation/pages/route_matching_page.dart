import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouteMatchingPage extends StatefulWidget {
  const RouteMatchingPage({super.key});

  @override
  State<RouteMatchingPage> createState() => _RouteMatchingPageState();
}

class _RouteMatchingPageState extends State<RouteMatchingPage> {
  double radius = 5;

  Future<void> _saveRadius() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('route_matching_radius', radius);
}
@override
void initState() {
  super.initState();
  _loadRadius();
}

Future<void> _loadRadius() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    radius = prefs.getDouble('route_matching_radius') ?? 5;
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
          "Accept drives within a set radius from the route of the driver.",
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 28),

        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
            ),
          ),
          child: Slider(
            value: radius,
            min: 5,
            max: 10,
            divisions: 5,
            activeColor: Colors.black,
            inactiveColor: Colors.grey.shade300,
            label: "${radius.round()} km",
            onChanged: (value) {
              setState(() {
                radius = value;
              });
            },
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "5 km",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              "10 km",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),

        const SizedBox(height: 22),

        Row(
          children: [
            Expanded(
              child: const Text(
                "Set a radius from your location",
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ),

            Container(
              width: 90,
              height: 46,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        "${radius.round()} km",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  Container(
                    width: 32,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.grey.shade300,
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
                                  radius++;
                                });
                              }
                            },
                            child: const Icon(
                              Icons.keyboard_arrow_up,
                              size: 18,
                            ),
                          ),
                        ),
                        Divider(height: 1),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (radius > 5) {
                                setState(() {
                                  radius--;
                                });
                              }
                            },
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
            onPressed: () {
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
            onPressed: () async {
  await _saveRadius();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        "Radius saved: ${radius.round()} km",
      ),
    ),
  );

  Navigator.pop(context);
},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Save Changes"),
          ),
        ),
      ),
    ],
  );
}
  }
