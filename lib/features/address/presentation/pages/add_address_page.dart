import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/address/presentation/bloc/add_address_bloc.dart';
import 'package:acepool/features/home/domain/entities/picked_location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:acepool/features/home/presentation/pages/location_search_page.dart';

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
      hintStyle: const TextStyle(color: Colors.grey),
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

            const Text.rich(
              TextSpan(
                text: "ADDRESS ",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
                children: [
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
              decoration: _fieldDecoration("Enter address"),
            ),

            const SizedBox(height: 20),

            const Text(
              "FLAT, FLOOR, LANDMARK (OPTIONAL)",
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
              decoration: _fieldDecoration("Enter landmark"),
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
        : const Text(
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
        },
      ),
    );
  }
}
