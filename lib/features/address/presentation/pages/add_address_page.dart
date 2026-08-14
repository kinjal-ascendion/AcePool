import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/address/presentation/bloc/add_address_bloc.dart';
import 'package:acepool/features/home/domain/entities/picked_location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:acepool/features/home/presentation/pages/location_search_page.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAddressPage extends StatefulWidget {
  final PickedLocation location;
  final String category;
  final String landmark;

  final bool isEdit;
  final String? docId;

  const AddAddressPage({
    super.key,
    required this.location,
    required this.category,
    this.landmark = '',
    this.isEdit = false,
    this.docId,
  });

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  late PickedLocation _selectedLocation;
  late final TextEditingController _addressController;
  late final TextEditingController _landmarkController;
  late TextEditingController _saveAsController;
  late final AddAddressBloc _bloc;

  String _selectedType = "Home";

  @override
  void initState() {
    super.initState();
    _bloc = sl<AddAddressBloc>();
    _selectedLocation = widget.location;
    _saveAsController = TextEditingController();

    _addressController = TextEditingController(
      text: widget.location.address,
    );
    _landmarkController = TextEditingController(
      text: widget.landmark,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _saveAddress() {
    final category = _selectedType == "Other" ? _saveAsController.text.trim() : _selectedType;
    _bloc.add(AddAddressSaveRequested(
      isEdit: widget.isEdit,
      docId: widget.docId,
      category: category,
      label: category,
      address: _addressController.text,
      landmark: _landmarkController.text,
      lat: _selectedLocation.lat,
      lng: _selectedLocation.lng,
    ));
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.mulish(
        color: const Color(0xFF6B7280),
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 24 / 15,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
    );
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
        color: selected ? Colors.black : Colors.grey.shade600,
      ),

      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.grey.shade600,
          fontWeight: selected
              ? FontWeight.w600
              : FontWeight.w500,
        ),
      ),

      backgroundColor: Colors.white,
      selectedColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      color: WidgetStateProperty.all(Colors.white),

      elevation: 0,
      pressElevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(
    color: selected ? Colors.black : Colors.grey.shade300,
    width: selected ? 1.5 : 1,
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
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<AddAddressBloc, AddAddressState>(
        listener: (context, state) {
          if (state.status == AddAddressStatus.success) {
            Navigator.pop(context, true);
          } else if (state.status == AddAddressStatus.validationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message ?? 'Address is required')),
            );
          }
          // AddAddressStatus.saveError: matches original — no snackbar,
          // just stops the spinner (handled via state.status in builder).
        },
        builder: (context, state) {
          final saving = state.status == AddAddressStatus.saving;
          return Scaffold(
    backgroundColor: Colors.white,

    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Address",
        style: GoogleFonts.mulish(
          color: const Color(0xFF1E1E1E),
          fontWeight: FontWeight.w700,
          fontSize: 24,
          height: 1.0,
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

            Text(
              "ADD ADDRESS",
              style: GoogleFonts.mulish(
                fontSize: 14,
                color: const Color(0xFF1E1E1E),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                height: 19.5 / 14,
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
      style: GoogleFonts.mulish(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1E1E1E),
        height: 1.0,
      ),
      decoration: InputDecoration(
        hintText: "Search for a location",
        hintStyle: GoogleFonts.mulish(
          color: const Color(0xFF6B7280),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 24 / 15,
        ),
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

                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
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
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Icon(
                          Icons.location_pin,
                          color: Colors.black,
                          size: 42,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text.rich(
              TextSpan(
                text: "ADDRESS ",
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF1E1E1E),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  height: 16 / 12,
                ),
                children: const [
                  TextSpan(
                    text: "*",
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _addressController,
              maxLines: 2,
              style: GoogleFonts.mulish(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1E1E1E),
                height: 1.0,
              ),
              decoration: _fieldDecoration("Enter address"),
            ),

            const SizedBox(height: 20),

            Text(
              "FLAT, FLOOR, LANDMARK (OPTIONAL)",
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFF1E1E1E),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                height: 16 / 12,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _landmarkController,
              style: GoogleFonts.mulish(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1E1E1E),
                height: 1.0,
              ),
              decoration: _fieldDecoration("Enter landmark"),
            ),

            const SizedBox(height: 20),

            Text(
  "SAVE AS",
  style: GoogleFonts.dmSans(
    fontSize: 12,
    color: const Color(0xFF1E1E1E),
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 16 / 12,
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
    decoration: _fieldDecoration("Enter category name"),
  ),

  const SizedBox(height: 20),
],

const SizedBox(height: 35),

SizedBox(
  width: double.infinity,
  height: 56,
  child: ElevatedButton(
    onPressed: saving ? null : _saveAddress,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      disabledBackgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: saving
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Text(
            "Save Address",
            textAlign: TextAlign.center,
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.0,
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
        },
      ),
    );
  }
}
