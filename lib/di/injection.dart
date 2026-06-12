import 'package:get_it/get_it.dart';
import 'package:acepool/features/splash/domain/usecases/initialize_app_usecase.dart';
import 'package:acepool/features/splash/presentation/bloc/splash_bloc.dart';

final sl = GetIt.instance;

void initDependencies() {
  // Use cases
  sl.registerLazySingleton<InitializeAppUseCase>(() => InitializeAppUseCase());

  // Blocs (registerFactory = new instance per call)
  sl.registerFactory<SplashBloc>(
    () => SplashBloc(initializeApp: sl()),
  );
}
