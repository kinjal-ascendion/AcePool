part of 'add_address_bloc.dart';

abstract class AddAddressEvent extends Equatable {
  const AddAddressEvent();

  @override
  List<Object?> get props => [];
}

class AddAddressSaveRequested extends AddAddressEvent {
  const AddAddressSaveRequested({
    required this.isEdit,
    this.docId,
    required this.category,
    required this.label,
    required this.address,
    required this.landmark,
    this.lat,
    this.lng,
  });

  final bool isEdit;
  final String? docId;
  final String category;
  final String label;
  final String address;
  final String landmark;
  final double? lat;
  final double? lng;

  @override
  List<Object?> get props =>
      [isEdit, docId, category, label, address, landmark, lat, lng];
}
