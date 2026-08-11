import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:acepool/features/profile/domain/entities/vehicle.dart';
import 'package:acepool/features/profile/domain/repositories/vehicle_repository.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl({FirebaseFirestore? db})
      : _db = db ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'acepool',
            );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _vehiclesRef() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('vehicles');
  }

  @override
  Stream<List<Vehicle>> watchVehicles() {
    return _vehiclesRef().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Vehicle(
          id: doc.id,
          type: data['type'] as String? ?? 'four_wheeler',
          number: data['number'] as String? ?? '',
          brand: data['brand'] as String? ?? '',
          model: data['model'] as String? ?? '',
          seats: (data['seats'] as num?)?.toInt() ?? 0,
          isDefault: data['isDefault'] as bool? ?? false,
        );
      }).toList();
    });
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    await _vehiclesRef().doc(vehicleId).delete();
  }

  @override
  Future<void> addVehicle({
    required String type,
    required String number,
    required String brand,
    required String model,
    required int seats,
    required bool isDefault,
  }) async {
    final ref = _vehiclesRef();

    if (isDefault) {
      final existing = await ref.get();
      final batch = _db.batch();
      for (final doc in existing.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      await batch.commit();
    }

    await ref.add({
      'type': type,
      'number': number,
      'brand': brand,
      'model': model,
      'seats': seats,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
