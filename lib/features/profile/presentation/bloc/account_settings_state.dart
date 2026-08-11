part of 'account_settings_bloc.dart';

enum AccountSettingsStatus { initial, saving, success, failure }

class AccountSettingsState extends Equatable {
  const AccountSettingsState({
    this.status = AccountSettingsStatus.initial,
    this.message,
  });

  final AccountSettingsStatus status;
  final String? message;

  AccountSettingsState copyWith({
    AccountSettingsStatus? status,
    String? message,
  }) {
    return AccountSettingsState(
      status: status ?? this.status,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, message];
}
