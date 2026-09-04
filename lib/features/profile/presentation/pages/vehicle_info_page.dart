import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/theme/app_theme.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/domain/entities/vehicle.dart';
import 'package:acepool/features/profile/domain/repositories/vehicle_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/vehicle_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({super.key});

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  late final VehicleBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<VehicleBloc>()..add(const VehicleListStarted());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    await sl<VehicleRepository>().deleteVehicle(vehicleId);
  }

  Future<void> _confirmDelete(String vehicleId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove vehicle?'),
        content: Text('$name will be removed from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteVehicle(vehicleId);
    }
  }

  Future<void> _openAddVehicleSheet() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const _AddVehicleDialog(),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.mulish(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3B3F46),
          height: 1.285,
        ),
      ),
    );
  }

  Widget _vehicleCard(Vehicle vehicle) {
    final isFourWheeler = vehicle.isFourWheeler;
    final number = vehicle.number;
    final seats = vehicle.seats;
    final name = vehicle.displayName;

    return GestureDetector(
      onLongPress: () =>
          _confirmDelete(vehicle.id, name.isNotEmpty ? name : number),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                isFourWheeler ? Icons.directions_car : Icons.two_wheeler,
                color: const Color(0xFF1B8A3F),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'Vehicle',
                    style: GoogleFonts.mulish(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: const Color(0xFF1D1D1D),
                      height: 1.3125,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    number,
                    style: GoogleFonts.mulish(
                      color: AppColors.subheadingGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.125,
                    ),
                  ),
                ],
              ),
            ),
            _tag(isFourWheeler ? '4W' : '2W'),
            const SizedBox(width: 8),
            _tag('$seats seats'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const Expanded(
                    child: Text(
                      'Vehicle info',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: BlocProvider.value(
                value: _bloc,
                child: BlocBuilder<VehicleBloc, VehicleState>(
                  builder: (context, state) {
                    if (state.status == VehicleListStatus.initial ||
                        state.status == VehicleListStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.status == VehicleListStatus.error) {
                      return Center(child: Text('Error: ${state.errorMessage}'));
                    }

                    final vehicles = state.vehicles;

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          'My Vehicles',
                          style: GoogleFonts.mulish(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: const Color(0xFF1D1D1D),
                            height: 1.406,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final doc in vehicles) ...[
                          _vehicleCard(doc),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _openAddVehicleSheet,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add, color: AppColors.subheadingGrey, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  'Add vehicle',
                                  style: GoogleFonts.mulish(
                                    color: AppColors.subheadingGrey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    height: 1.125,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddVehicleDialog extends StatefulWidget {
  const _AddVehicleDialog();

  @override
  State<_AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<_AddVehicleDialog> {
  String _type = 'four_wheeler';
  int _seats = 4;
  bool _isDefault = true;
  bool _isSaving = false;

  final _numberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();

  List<int> get _seatOptions =>
      _type == 'four_wheeler' ? const [2, 3, 4, 5, 6, 7] : const [1];

  String get _nameHint => _type == 'four_wheeler'
      ? 'E.g., City, Swift, Creta, Nexon, Slavia'
      : 'E.g., Activa, Splendor, Pulsar, Access, FZ';

  String get _brandHint => _type == 'four_wheeler'
      ? 'E.g., Honda, Maruti Suzuki, Hyundai, Tata, Skoda'
      : 'E.g., Honda, TVS, Bajaj, Hero, Yamaha';

  @override
  void dispose() {
    _numberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _setType(String type) {
    setState(() {
      _type = type;
      if (!_seatOptions.contains(_seats)) {
        _seats = _seatOptions.first;
      }
    });
  }

  Future<void> _confirm() async {
    final number = _numberController.text.trim();
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();

    if (number.isEmpty || brand.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle number and brand are required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await sl<VehicleRepository>().addVehicle(
        type: _type,
        number: number,
        brand: brand,
        model: model,
        seats: _seats,
        isDefault: _isDefault,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding vehicle: $e')));
      }
    }
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.mulish(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF000000), // Assuming black based on "Choose an option - Default" requirement
        height: 1.285, // 18/14
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.mulish(
        color: const Color(0xFFB6B6B6),
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.285,
      ),
      filled: true,
      fillColor: AppColors.grey50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.black, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add vehicle',
                  style: GoogleFonts.mulish(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF000000),
                    height: 1.0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TypeOption(
                    label: '4-Wheeler',
                    selected: _type == 'four_wheeler',
                    onTap: () => _setType('four_wheeler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeOption(
                    label: '2-Wheeler',
                    selected: _type == 'two_wheeler',
                    onTap: () => _setType('two_wheeler'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _label('Vehicle number'),
            const SizedBox(height: 6),
            TextField(
              controller: _numberController,
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF000000),
                height: 1.285,
              ),
              decoration: _fieldDecoration('E.g., KA 52 MV 2931'),
            ),
            const SizedBox(height: 16),
            _label('Brand'),
            const SizedBox(height: 6),
            TextField(
              controller: _brandController,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF000000),
                height: 1.285,
              ),
              decoration: _fieldDecoration(_brandHint),
            ),
            const SizedBox(height: 16),
            _label('Vehicle name'),
            const SizedBox(height: 6),
            TextField(
              controller: _modelController,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF000000),
                height: 1.285,
              ),
              decoration: _fieldDecoration(_nameHint),
            ),
            const SizedBox(height: 16),
            _label('No. of seats available'),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _seatOptions.contains(_seats)
                  ? _seats
                  : _seatOptions.first,
              decoration: _fieldDecoration(''),
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF000000),
                height: 1.285,
              ),
              items: _seatOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _seats = value);
              },
            ),
            const SizedBox(height: 16),
            _label('Choose an option'),
            const SizedBox(height: 8),
            Row(
              children: [
                _RadioChoice(
                  label: 'Default',
                  selected: _isDefault,
                  onTap: () => setState(() => _isDefault = true),
                ),
                const SizedBox(width: 24),
                _RadioChoice(
                  label: 'Optional',
                  selected: !_isDefault,
                  onTap: () => setState(() => _isDefault = false),
                  isOptional: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1D1D1D),
                      side: BorderSide(color: AppColors.grey300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.mulish(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.scheduleButtonColor,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Confirm', // The user mentioned "Save changes" in text but "Confirm" is usually used here. 
                                     // Screenshot shows "Confirm". Applying Bold 16 style.
                            style: GoogleFonts.mulish(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              height: 1.0,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.scheduleButtonColor : AppColors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? AppTheme.scheduleButtonColor : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.mulish(
            color: selected ? AppColors.white : const Color(0xFF1D1D1D),
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.5, // 21/14
          ),
        ),
      ),
    );
  }
}

class _RadioChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isOptional;

  const _RadioChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
            color: selected ? AppTheme.scheduleButtonColor : AppColors.grey400,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.285,
              color: isOptional && !selected ? const Color(0xFF757474) : const Color(0xFF1D1D1D),
            ),
          ),
        ],
      ),
    );
  }
}
