import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:acepool/features/profile/domain/entities/profile_summary.dart';
import 'package:acepool/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({FirebaseFirestore? db})
      : _db = db ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'acepool',
            );

  final FirebaseFirestore _db;

  @override
  Stream<ProfileSummary> watchProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      final travelPreference =
          (data?['travelPreference'] as String?) ?? (data?['travel_preference'] as String?);
      return ProfileSummary(
        fullName: data?['fullName'] as String? ?? '',
        employeeId: data?['employeeId'] as String? ?? '',
        phone: data?['phone'] as String?,
        licenceVerified: data?['licenceVerified'] as bool?,
        licenceNumber: data?['licenceNumber'] as String?,
        travelPreference: travelPreference,
        hasVehicles: data?['hasVehicles'] as bool? ?? false,
      );
    });
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
    required String email,
    bool? licenceVerified,
    String? licenceNumber,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;

    final data = <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
      'email': email,
    };
    if (licenceVerified == true) {
      data['licenceVerified'] = true;
      if (licenceNumber != null) data['licenceNumber'] = licenceNumber;
    }

    await _db.collection('users').doc(user.uid).update(data);

    // Home reads FirebaseAuth's displayName, not Firestore's fullName -
    // keep them in sync so the change shows up there too.
    if (fullName != user.displayName) {
      await user.updateDisplayName(fullName);
      await user.reload();
    }
  }

  @override
  Future<double> getRouteMatchingRadius() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return 0.0;
    return (doc.data()?['routeMatchingRadius'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<void> saveRouteMatchingRadius(double radius) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _db.collection('users').doc(uid).set(
      {'routeMatchingRadius': radius},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Future<void> savePaymentDetails({
    required String method,
    required String upiId,
    required String upiPhone,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).update({
      'paymentMethod': method,
      'upiId': upiId,
      'upiPhone': upiPhone,
    });
  }

  @override
  Future<({String method, String upiId, String upiPhone})> getPaymentDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return (method: 'UPI', upiId: '', upiPhone: '');

    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    return (
      method: data?['paymentMethod'] as String? ?? 'UPI',
      upiId: data?['upiId'] as String? ?? '',
      upiPhone: data?['upiPhone'] as String? ?? '',
    );
  }
}
