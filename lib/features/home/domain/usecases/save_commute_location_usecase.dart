import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Persists the address the rider most recently picked as their "home"
/// (start location) or "office" (destination) on the ride-schedule form,
/// so the Rides tab can rank available rides by real distance to this
/// commute route instead of falling back to a fixed default.
class SaveCommuteLocationUseCase {
  final FirebaseFirestore _db;

  SaveCommuteLocationUseCase({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'acepool');

  Future<void> call({
    required bool isHome,
    required String address,
    double? lat,
    double? lng,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefix = isHome ? 'home' : 'office';
    try {
      await _db.collection('users').doc(uid).set({
        '${prefix}Address': address,
        '${prefix}Lat': lat,
        '${prefix}Lng': lng,
      }, SetOptions(merge: true));
    } catch (_) {
      // Best-effort: a failed save shouldn't block address selection.
    }
  }
}
