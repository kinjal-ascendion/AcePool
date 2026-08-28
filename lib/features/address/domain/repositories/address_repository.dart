import 'package:acepool/features/address/domain/entities/address_record.dart';

abstract class AddressRepository {
  /// The current user's saved addresses, sorted by creation order.
  Future<List<AddressRecord>> getAddresses();

  /// Creates or updates an address doc. When creating (not [isEdit]),
  /// automatically marks it `isDefault` if it's the first address in
  /// [category].
  Future<void> saveAddress({
    required bool isEdit,
    String? docId,
    required String category,
    required String label,
    required String address,
    required String landmark,
    double? lat,
    double? lng,
  });

  /// Deletes [docId]. If [wasDefault], promotes another address in
  /// [category] (if any) to default.
  Future<void> deleteAddress({
    required String docId,
    required String category,
    required bool wasDefault,
  });
}
