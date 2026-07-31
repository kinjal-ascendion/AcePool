import 'package:equatable/equatable.dart';

class VehicleOption extends Equatable {
  final String id;
  final String label;
  final String type;

  const VehicleOption({
    required this.id,
    required this.label,
    required this.type,
  });

  @override
  List<Object?> get props => [id, label, type];
}
