import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:acepool/core/theme/app_theme.dart';

class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({super.key});

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  static CollectionReference<Map<String, dynamic>> _vehiclesRef() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('vehicles');
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchVehicles() {
    return _vehiclesRef().get();
  }

  Future<void> _addVehicle(Map<String, dynamic> vehicle) async {
    final ref = _vehiclesRef();

    if (vehicle['isDefault'] == true) {
      final existing = await ref.get();
      final batch = _db.batch();
      for (final doc in existing.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      await batch.commit();
    }

    await ref.add({...vehicle, 'createdAt': FieldValue.serverTimestamp()});

    if (mounted) setState(() {});
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    await _vehiclesRef().doc(vehicleId).delete();
    if (mounted) setState(() {});
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
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteVehicle(vehicleId);
    }
  }

  Future<void> _openAddVehicleSheet() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddVehicleDialog(),
    );

    if (result != null) {
      await _addVehicle(result);
    }
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _vehicleCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final isFourWheeler = data['type'] == 'four_wheeler';
    final brand = data['brand'] as String? ?? '';
    final model = data['model'] as String? ?? '';
    final number = data['number'] as String? ?? '';
    final seats = data['seats'];
    final name = [brand, model].where((s) => s.isNotEmpty).join(' ');

    return GestureDetector(
      onLongPress: () => _confirmDelete(doc.id, name.isNotEmpty ? name : number),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isFourWheeler ? Icons.directions_car : Icons.two_wheeler,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'Vehicle',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    number,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Vehicle info',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: _fetchVehicles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final vehicles = snapshot.data?.docs ?? [];

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'My Vehicles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                for (final doc in vehicles) ...[
                  _vehicleCard(doc),
                  const SizedBox(height: 12),
                ],
                InkWell(
                  onTap: _openAddVehicleSheet,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Add vehicle',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
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

  final _numberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();

  List<int> get _seatOptions =>
      _type == 'four_wheeler' ? const [2, 4, 5, 6, 7] : const [1, 2];

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

  void _confirm() {
    if (_numberController.text.trim().isEmpty ||
        _brandController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle number and brand are required')),
      );
      return;
    }

    Navigator.pop(context, {
      'type': _type,
      'number': _numberController.text.trim(),
      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      'seats': _seats,
      'isDefault': _isDefault,
    });
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add vehicle',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
                decoration: _fieldDecoration('E.g., KA 52 MV 2931'),
              ),
              const SizedBox(height: 16),
              _label('Vehicle brand'),
              const SizedBox(height: 6),
              TextField(
                controller: _brandController,
                decoration: _fieldDecoration('Enter brand'),
              ),
              const SizedBox(height: 16),
              _label('Brand model'),
              const SizedBox(height: 6),
              TextField(
                controller: _modelController,
                decoration: _fieldDecoration('Enter model'),
              ),
              const SizedBox(height: 16),
              _label('No. of seats available'),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _seatOptions.contains(_seats)
                    ? _seats
                    : _seatOptions.first,
                decoration: _fieldDecoration(''),
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
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.scheduleButtonColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Confirm'),
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
          color: selected ? AppTheme.scheduleButtonColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? AppTheme.scheduleButtonColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
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

  const _RadioChoice({
    required this.label,
    required this.selected,
    required this.onTap,
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
            color: selected ? AppTheme.scheduleButtonColor : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
