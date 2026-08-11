part of 'account_settings_bloc.dart';

abstract class AccountSettingsEvent extends Equatable {
  const AccountSettingsEvent();

  @override
  List<Object?> get props => [];
}

class AccountSettingsSaveRequested extends AccountSettingsEvent {
  const AccountSettingsSaveRequested({
    required this.fullName,
    required this.phone,
    required this.email,
    this.licenceVerified,
    this.licenceNumber,
  });

  final String fullName;
  final String phone;
  final String email;
  final bool? licenceVerified;
  final String? licenceNumber;

  @override
  List<Object?> get props => [fullName, phone, email, licenceVerified, licenceNumber];
}
