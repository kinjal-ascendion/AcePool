import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/features/home/domain/entities/picked_location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:acepool/features/home/presentation/pages/location_search_page.dart';
import 'add_address_page.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  static CollectionReference<Map<String, dynamic>> _addressesRef() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('addresses');
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchAddresses() {
    return _addressesRef().get();
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
    setState(() {});
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
    setState(() {});
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
              final ref = _addressesRef();
              await ref.doc(docId).delete();

              if (wasDefault) {
                final remaining = await ref
                    .where('category', isEqualTo: category)
                    .limit(1)
                    .get();
                if (remaining.docs.isNotEmpty) {
                  await remaining.docs.first.reference
                      .update({'isDefault': true});
                }
              }

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

    if (confirmed == true && mounted) setState(() {});
  }

  Widget _sectionHeader(String label, VoidCallback? onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
              letterSpacing: 0.5,
            ),
          ),
          if (onAdd != null)
            InkWell(
              onTap: onAdd,
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: AppColors.grey700),
                  const SizedBox(width: 2),
                  Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey700,
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
    final parts = address.split(',');
    final line1 = parts.first.trim();
    final line2 = parts.skip(1).join(',').trim();

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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
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
                                style: TextStyle(
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
                        line1,
                        style: TextStyle(color: AppColors.grey600, fontSize: 15),
                      ),
                      if (line2.isNotEmpty)
                        Text(
                          line2,
                          style:
                              TextStyle(color: AppColors.grey600, fontSize: 15),
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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: AppColors.black87),
                          SizedBox(width: 6),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: AppColors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                          SizedBox(width: 6),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.red, fontSize: 14),
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
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.black,
        centerTitle: true,
        title: const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: _fetchAddresses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = [...snapshot.data?.docs ?? []]..sort((a, b) {
              final ta = a.data()['createdAt'] as Timestamp?;
              final tb = b.data()['createdAt'] as Timestamp?;
              if (ta == null || tb == null) return 0;
              return ta.compareTo(tb);
            });
            final homeDocs =
                docs.where((d) => d.data()['category'] == 'home').toList();
            final officeDocs =
                docs.where((d) => d.data()['category'] == 'office').toList();
                final otherDocs = docs.where((d) {
  final category =
      (d.data()['category'] as String?)?.toLowerCase() ?? "";
  return category != "home" && category != "office";
}).toList();
            final seenOtherCategories = <String>{};
            String? firstHomeOrOfficeId;
            for (final d in docs) {
              final cat = d.data()['category'] as String?;
              if (cat == 'home' || cat == 'office') {
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
                    address: homeDocs[i].data()['address'] as String? ?? '',
                    landmark: homeDocs[i].data()['landmark'] as String? ?? '',
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
                    address: officeDocs[i].data()['address'] as String? ?? '',
                    landmark: officeDocs[i].data()['landmark'] as String? ?? '',
                    isDefault: officeDocs[i].id == firstHomeOrOfficeId,
                    category: 'office',
                  ),

if (otherDocs.isNotEmpty) ...[
  _sectionHeader('Saved', () => _addAddress('other', 'Other')),

  for (final doc in otherDocs)
    _addressCard(
      docId: doc.id,
      label: doc.data()['label'] as String? ?? 'Saved',
      icon: Icons.bookmark_border,
      address: doc.data()['address'] as String? ?? '',
      landmark: doc.data()['landmark'] as String? ?? '',
      isDefault: seenOtherCategories.add(doc.data()['category'] as String? ?? ''),
      category: doc.data()['category'] as String? ?? '',
    ),
],
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
