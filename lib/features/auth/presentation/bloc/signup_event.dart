part of 'signup_bloc.dart';

abstract class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object?> get props => [];
}

class SignupSubmitted extends SignupEvent {
  const SignupSubmitted({
    required this.fullName,
    required this.employeeId,
    required this.phone,
    required this.emailUsername,
    required this.password,
    required this.confirmPassword,
    required this.showLicenseSection,
    this.onboardingSelection,
  });

  final String fullName;
  final String employeeId;
  final String phone;
  final String emailUsername;
  final String password;
  final String confirmPassword;
  final bool showLicenseSection;
  final OnboardingSelection? onboardingSelection;

  @override
  List<Object?> get props => [
    fullName,
    employeeId,
    phone,
    emailUsername,
    password,
    confirmPassword,
    showLicenseSection,
    onboardingSelection,
  ];
}

class SignupFieldChanged extends SignupEvent {
  const SignupFieldChanged();
}

class SignupLicenseImagePicked extends SignupEvent {
  const SignupLicenseImagePicked({
    required this.isFront,
    required this.imageFile,
  });

  final bool isFront;
  final File imageFile;

  @override
  List<Object?> get props => [isFront, imageFile.path];
}
