import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/address/domain/repositories/address_repository.dart';
import 'package:acepool/features/address/presentation/bloc/addresses_bloc.dart';
import 'package:acepool/features/home/domain/entities/picked_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_address_page.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  late final AddressesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<AddressesBloc>()..add(const AddressesStarted());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _addAddress(String category, String label) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddAddressPage(
          location: PickedLocation(
            address: "",
            lat: null,
            lng: null,
          ),
          category: category,
        ),
      ),
    );

    if (saved == true && mounted) {
      _bloc.add(const AddressesStarted());
    }
  }

  Future<void> _editAddress(
    String docId,
    String label,
    String currentAddress,
    String currentLandmark,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddAddressPage(
          docId: docId,
          isEdit: true,
          location: PickedLocation(
            address: currentAddress,
            lat: null,
            lng: null,
          ),
          category: label,
          landmark: currentLandmark,
        ),
      ),
    );

    if (result == true && mounted) {
      _bloc.add(const AddressesStarted());
    }
  }

  Future<void> _deleteAddress(
      String docId, String category, bool wasDefault) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var removing = false;
        return StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> handleRemove() async {
            setDialogState(() => removing = true);
            try {
              await sl<AddressRepository>().deleteAddress(
                docId: docId,
                category: category,
                wasDefault: wasDefault,
              );

              if (ctx.mounted) Navigator.pop(ctx, true);
            } catch (e) {
              setDialogState(() => removing = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Could not remove address: $e')),
                );
              }
            }
          }

          return Dialog(
            backgroundColor: AppColors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.red50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_outline,
                        color: AppColors.red, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Remove address?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This address will be removed from your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.grey600, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              removing ? null : () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.black87,
                            side: BorderSide(color: AppColors.grey300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: removing ? null : handleRemove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            disabledBackgroundColor: AppColors.red,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: removing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text(
                                  'Remove',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        );
      },
    );

    if (confirmed == true && mounted) {
      _bloc.add(const AddressesStarted());
    }
  }

  Widget _sectionHeader(String label, VoidCallback? onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1D),
              letterSpacing: 1.3,
              height: 19.5 / 14,
            ),
          ),
          if (onAdd != null)
            InkWell(
              onTap: onAdd,
              child: Row(
                children: [
                  const Icon(Icons.add, size: 16, color: Color(0xFF1D1D1D)),
                  const SizedBox(width: 2),
                  Text(
                    'Add',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D1D1D),
                      height: 18 / 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _addressCard({
    required String docId,
    required String label,
    required IconData icon,
    required String address,
    required String landmark,
    required bool isDefault,
    required String category,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.black87),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: GoogleFonts.mulish(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: const Color(0xFF1D1D1D),
                                height: 22.5 / 16,
                              ),
                            ),
                          ),
                          if (isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Default',
                                style: GoogleFonts.mulish(
                                  fontSize: 12,
                                  color: AppColors.grey700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: GoogleFonts.mulish(
                          color: const Color(0xFF6A7282),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 21.13 / 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.grey300),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _editAddress(docId, label, address, landmark),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1D1D1D)),
                          const SizedBox(width: 6),
                          Text(
                            'Edit',
                            style: GoogleFonts.mulish(
                              color: const Color(0xFF1D1D1D),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 19.5 / 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, color: AppColors.grey300),
                Expanded(
                  child: InkWell(
                    onTap: () => _deleteAddress(docId, category, isDefault),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEA0000)),
                          const SizedBox(width: 6),
                          Text(
                            'Delete',
                            style: GoogleFonts.mulish(
                              color: const Color(0xFFEA0000),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 19.5 / 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyAddressPlaceholder(String category, VoidCallback onAdd) {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_outlined,
                  size: 18, color: AppColors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No $category address added',
                    style: const TextStyle(
                      color: AppColors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to add one now',
                    style: TextStyle(color: AppColors.grey500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: AppColors.white),
                  SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF000000), size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Address',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mulish(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF000000),
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
                child: BlocBuilder<AddressesBloc, AddressesState>(
                builder: (context, state) {
                  if (state.status == AddressesStatus.initial ||
                      state.status == AddressesStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = state.addresses;
                  final homeDocs =
                      docs.where((d) => d.category == 'home').toList();
                  final officeDocs =
                      docs.where((d) => d.category == 'office').toList();
                  final otherDocs = docs.where((d) {
                    final category = d.category.toLowerCase();
                    return category != "home" && category != "office";
                  }).toList();
                  final seenOtherCategories = <String>{};
                  String? firstHomeOrOfficeId;
                  for (final d in docs) {
                    if (d.category == 'home' || d.category == 'office') {
                      firstHomeOrOfficeId = d.id;
                      break;
                    }
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _sectionHeader(
                        'Home',
                        homeDocs.isEmpty ? null : () => _addAddress('home', 'Home'),
                      ),
                      if (homeDocs.isEmpty)
                        _emptyAddressPlaceholder('home', () => _addAddress('home', 'Home')),
                      for (var i = 0; i < homeDocs.length; i++)
                        _addressCard(
                          docId: homeDocs[i].id,
                          label: 'Home',
                          icon: Icons.home_outlined,
                          address: homeDocs[i].address,
                          landmark: homeDocs[i].landmark,
                          isDefault: homeDocs[i].id == firstHomeOrOfficeId,
                          category: 'home',
                        ),
                      _sectionHeader(
                        'Office',
                        officeDocs.isEmpty ? null : () => _addAddress('office', 'Office'),
                      ),
                      if (officeDocs.isEmpty)
                        _emptyAddressPlaceholder('office', () => _addAddress('office', 'Office')),
                      for (var i = 0; i < officeDocs.length; i++)
                        _addressCard(
                          docId: officeDocs[i].id,
                          label: 'Office',
                          icon: Icons.apartment_outlined,
                          address: officeDocs[i].address,
                          landmark: officeDocs[i].landmark,
                          isDefault: officeDocs[i].id == firstHomeOrOfficeId,
                          category: 'office',
                        ),

      if (otherDocs.isNotEmpty) ...[
        _sectionHeader('Saved', () => _addAddress('other', 'Other')),

        for (final doc in otherDocs)
          _addressCard(
            docId: doc.id,
            label: doc.label.isNotEmpty ? doc.label : 'Saved',
            icon: Icons.bookmark_border,
            address: doc.address,
            landmark: doc.landmark,
            isDefault: seenOtherCategories.add(doc.category),
            category: doc.category,
          ),
      ],
                      const SizedBox(height: 20),
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
