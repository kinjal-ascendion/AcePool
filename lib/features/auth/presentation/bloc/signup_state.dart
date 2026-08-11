part of 'signup_bloc.dart';

enum SignupStatus { initial, submitting, success, failure }

class SignupState extends Equatable {
  const SignupState({
    this.status = SignupStatus.initial,
    this.fullNameError,
    this.employeeIdError,
    this.phoneError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.errorMessage,
    this.user,
    this.frontLicenseImage,
    this.backLicenseImage,
    this.isVerifyingFrontLicense = false,
    this.isVerifyingBackLicense = false,
    this.frontLicenseValid,
    this.backLicenseValid,
    this.licenseNumber,
  });

  final SignupStatus status;
  final String? fullNameError;
  final String? employeeIdError;
  final String? phoneError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? errorMessage;
  final AuthUser? user;
  final File? frontLicenseImage;
  final File? backLicenseImage;
  final bool isVerifyingFrontLicense;
  final bool isVerifyingBackLicense;
  final bool? frontLicenseValid;
  final bool? backLicenseValid;
  final String? licenseNumber;

  @override
  List<Object?> get props => [
    status,
    fullNameError,
    employeeIdError,
    phoneError,
    emailError,
    passwordError,
    confirmPasswordError,
    errorMessage,
    user,
    frontLicenseImage,
    backLicenseImage,
    isVerifyingFrontLicense,
    isVerifyingBackLicense,
    frontLicenseValid,
    backLicenseValid,
    licenseNumber,
  ];
}
