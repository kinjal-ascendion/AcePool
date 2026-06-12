import 'package:acepool/core/constants/app_constants.dart';

class InitializeAppUseCase {
  Future<void> call() async {
    await Future.wait([
      Future.delayed(AppConstants.splashDuration),
      _initializeServices(),
    ]);
  }

  Future<void> _initializeServices() async {
    // TODO: init
  }
}
