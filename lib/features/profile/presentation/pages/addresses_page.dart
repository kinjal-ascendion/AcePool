import 'package:acepool/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:acepool/features/home/presentation/pages/location_search_page.dart';

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
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSearchPage(title: 'Search $label Location'),
      ),
    );

    if (result == null || result.isEmpty) return;

    final ref = _addressesRef();
    final existing = await ref.where('category', isEqualTo: category).get();

    await ref.add({
      'category': category,
      'address': result,
      'isDefault': existing.docs.isEmpty,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) setState(() {});
  }

  Future<void> _editAddress(
      String docId, String label, String currentAddress) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSearchPage(
          title: 'Search $label Location',
          initialValue: currentAddress,
        ),
      ),
    );

    if (result == null || result.isEmpty) return;

    await _addressesRef().doc(docId).update({'address': result});
    if (mounted) setState(() {});
  }

  Future<void> _deleteAddress(
      String docId, String category, bool wasDefault) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove address?'),
        content: const Text('This address will be removed from your account.'),
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

    if (confirmed != true) return;

    final ref = _addressesRef();
    await ref.doc(docId).delete();

    if (wasDefault) {
      final remaining =
          await ref.where('category', isEqualTo: category).limit(1).get();
      if (remaining.docs.isNotEmpty) {
        await remaining.docs.first.reference.update({'isDefault': true});
      }
    }

    if (mounted) setState(() {});
  }

  Widget _sectionHeader(String label, VoidCallback onAdd) {
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
              color: AppColors.grey500,
              letterSpacing: 0.5,
            ),
          ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
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
                    borderRadius: BorderRadius.circular(10),
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
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
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
                                  fontSize: 11,
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
                        style: TextStyle(color: AppColors.grey600, fontSize: 13),
                      ),
                      if (line2.isNotEmpty)
                        Text(
                          line2,
                          style:
                              TextStyle(color: AppColors.grey600, fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.grey200),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _editAddress(docId, label, address),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Edit'),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.grey200),
              Expanded(
                child: InkWell(
                  onTap: () => _deleteAddress(docId, category, isDefault),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: AppColors.red),
                        SizedBox(width: 6),
                        Text('Delete', style: TextStyle(color: AppColors.red)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        foregroundColor: AppColors.black,
        title: const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: _fetchAddresses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            final homeDocs =
                docs.where((d) => d.data()['category'] == 'home').toList();
            final officeDocs =
                docs.where((d) => d.data()['category'] == 'office').toList();

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _sectionHeader('Home', () => _addAddress('home', 'Home')),
                for (final doc in homeDocs)
                  _addressCard(
                    docId: doc.id,
                    label: 'Home',
                    icon: Icons.home_outlined,
                    address: doc.data()['address'] as String? ?? '',
                    isDefault: doc.data()['isDefault'] as bool? ?? false,
                    category: 'home',
                  ),
                _sectionHeader('Office', () => _addAddress('office', 'Office')),
                for (final doc in officeDocs)
                  _addressCard(
                    docId: doc.id,
                    label: 'Office',
                    icon: Icons.apartment_outlined,
                    address: doc.data()['address'] as String? ?? '',
                    isDefault: doc.data()['isDefault'] as bool? ?? false,
                    category: 'office',
                  ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
