import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:acepool/features/address/domain/entities/address_record.dart';
import 'package:acepool/features/address/domain/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  AddressRepositoryImpl({FirebaseFirestore? db})
      : _db = db ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'acepool',
            );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _addressesRef() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('addresses');
  }

  @override
  Future<List<AddressRecord>> getAddresses() async {
    final snapshot = await _addressesRef().get();
    final docs = [...snapshot.docs]..sort((a, b) {
      final ta = a.data()['createdAt'] as Timestamp?;
      final tb = b.data()['createdAt'] as Timestamp?;
      if (ta == null || tb == null) return 0;
      return ta.compareTo(tb);
    });

    return docs.map((doc) {
      final data = doc.data();
      return AddressRecord(
        id: doc.id,
        category: data['category'] as String? ?? '',
        label: data['label'] as String? ?? '',
        address: data['address'] as String? ?? '',
        landmark: data['landmark'] as String? ?? '',
        lat: (data['lat'] as num?)?.toDouble(),
        lng: (data['lng'] as num?)?.toDouble(),
        isDefault: data['isDefault'] as bool? ?? false,
      );
    }).toList();
  }

  @override
  Future<void> saveAddress({
    required bool isEdit,
    String? docId,
    required String category,
    required String label,
    required String address,
    required String landmark,
    double? lat,
    double? lng,
  }) async {
    final ref = _addressesRef();
    final categoryKey = category.toLowerCase();

    bool isFirstInCategory = false;
    if (!isEdit) {
      final existing = await ref.where('category', isEqualTo: categoryKey).limit(1).get();
      isFirstInCategory = existing.docs.isEmpty;
    }

    final data = {
      'category': categoryKey,
      'label': label,
      'address': address,
      'landmark': landmark,
      'lat': lat,
      'lng': lng,
      if (!isEdit) 'isDefault': isFirstInCategory,
    };

    if (isEdit) {
      await ref.doc(docId).update(data);
    } else {
      await ref.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> deleteAddress({
    required String docId,
    required String category,
    required bool wasDefault,
  }) async {
    final ref = _addressesRef();
    await ref.doc(docId).delete();

    if (wasDefault) {
      final remaining = await ref.where('category', isEqualTo: category).limit(1).get();
      if (remaining.docs.isNotEmpty) {
        await remaining.docs.first.reference.update({'isDefault': true});
      }
    }
  }
}
