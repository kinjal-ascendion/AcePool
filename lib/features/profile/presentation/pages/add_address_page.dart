import 'package:flutter/material.dart';
import 'package:acepool/features/home/domain/entities/picked_location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:acepool/features/home/presentation/pages/location_search_page.dart';

class AddAddressPage extends StatefulWidget {
  final PickedLocation location;
  final String category;

  final bool isEdit;
  final String? docId;

  const AddAddressPage({
    super.key,
    required this.location,
    required this.category,
    this.isEdit = false,
    this.docId,
  });

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
  
}

class _AddAddressPageState extends State<AddAddressPage> {
  late PickedLocation _selectedLocation;
  late final TextEditingController _addressController;
  final TextEditingController _landmarkController = TextEditingController();
  late TextEditingController _saveAsController;

  String _selectedType = "Home";

  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  CollectionReference<Map<String, dynamic>> _addressesRef() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return _db
        .collection('users')
        .doc(uid)
        .collection('addresses');
  }

  @override
  void initState() {
    super.initState();
     _selectedLocation = widget.location;
     _saveAsController = TextEditingController();

    _addressController = TextEditingController(
      text: widget.location.address,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }
Future<void> _saveAddress() async {
  try {
    if (_addressController.text.trim().isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Address is required"),
    ),
  );
  return;
}
    final ref = _addressesRef();

    final category = _selectedType == "Other"
        ? _saveAsController.text.trim()
        : _selectedType;

    final data = {
      'category': category.toLowerCase(),
      'label': category,
      'address': _addressController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'lat': _selectedLocation.lat,
      'lng': _selectedLocation.lng,
      'isDefault': true,
    };

    if (widget.isEdit) {
      await ref.doc(widget.docId).update(data);
    } else {
      await ref.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  } catch (e) {
    debugPrint("SAVE ERROR: $e");
  }
}
Widget _categoryChip({
  required IconData icon,
  required String label,
}) {
  final selected = _selectedType == label;

  return ChoiceChip(
    selected: selected,
    showCheckmark: false,

    avatar: Icon(
      icon,
      size: 18,
      color: selected ? Colors.black : Colors.grey,
    ),

    label: Text(
      label,
      style: TextStyle(
        color: selected ? Colors.black : Colors.grey,
        fontWeight: selected
            ? FontWeight.w600
            : FontWeight.w500,
      ),
    ),

    backgroundColor: Colors.white,
    selectedColor: Colors.white,

    elevation: 0,
    pressElevation: 0,

    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
      side: BorderSide(
  color: selected ? Colors.black : Colors.grey,
  width: selected ? 1 : 1,
),
    ),

    onSelected: (_) {
      setState(() {
        _selectedType = label;

        if (label == "Other") {
          _saveAsController.clear();
        }
      });
    },
  );
}
@override
Widget build(BuildContext context) {
  debugPrint("Latitude: ${widget.location.lat}");
debugPrint("Longitude: ${widget.location.lng}");
  return Scaffold(
    backgroundColor: Colors.white,

    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Address",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
      ),
    ),

    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "ADD ADDRESS",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 14),

GestureDetector(
  onTap: () async {
  final result = await Navigator.push<PickedLocation>(
    context,
    MaterialPageRoute(
      builder: (_) => const LocationSearchPage(
        title: "Search Location",
      ),
    ),
  );

  if (result == null) return;

  setState(() {
    _selectedLocation = result;
    _addressController.text = result.address;
  });
},
  child: AbsorbPointer(
    child: TextField(
      decoration: InputDecoration(
        hintText: "Search for a location",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xffF6F6F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  ),
),

            const SizedBox(height: 16),

            SizedBox(
              height: 250,

              child: Stack(
                children: [

                  ClipRRect(
  borderRadius: BorderRadius.circular(22),
  child: GoogleMap(
    initialCameraPosition: CameraPosition(
      target: LatLng(
  _selectedLocation.lat ?? 0.0,
  _selectedLocation.lng ?? 0.0,
),
      zoom: 16,
    ),
    myLocationButtonEnabled: false,
    zoomControlsEnabled: false,
    mapToolbarEnabled: false,
  ),
),

                  Positioned(
                    top: 18,
                    left: 30,
                    right: 30,

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),

                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                          )
                        ],
                      ),

                      child: const Text(
                        "Drag the map to adjust the pin",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                                    const Positioned(
                    top: 105,
                    left: 0,
                    right: 0,
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 42,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "ADDRESS",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Enter address",
                hintStyle: TextStyle(
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "LANDMARK (OPTIONAL)",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _landmarkController,
              decoration: InputDecoration(
                hintText: "Enter landmark",
                hintStyle: TextStyle(
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
  "SAVE AS",
  style: TextStyle(
    fontSize: 12,
    color: Colors.black,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
  ),
),

const SizedBox(height: 10),

     Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [
    _categoryChip(
      icon: Icons.home_outlined,
      label: "Home",
    ),

    _categoryChip(
      icon: Icons.business_outlined,
      label: "Office",
    ),

    _categoryChip(
      icon: Icons.add,
      label: "Other",
    ),
  ],
),

if (_selectedType == "Other") ...[
  const SizedBox(height: 20),


  TextField(
    controller: _saveAsController,
    decoration: InputDecoration(
      hintText: "Enter category name",
      hintStyle: TextStyle(
                  color: Colors.grey,
                ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),

  const SizedBox(height: 20),
],

const SizedBox(height: 35),

SizedBox(
  width: double.infinity,
  height: 56,
  child: ElevatedButton(
    onPressed: _saveAddress,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    child: const Text(
      "Save Address",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),

const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}
}