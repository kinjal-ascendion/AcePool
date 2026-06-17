import 'package:get_it/get_it.dart';
import 'package:acepool/features/splash/domain/usecases/initialize_app_usecase.dart';
import 'package:acepool/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:acepool/features/home/domain/usecases/get_upcoming_trips_usecase.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';

final sl = GetIt.instance;

void initDependencies() {
  // Use cases
  sl.registerLazySingleton<InitializeAppUseCase>(() => InitializeAppUseCase());
  sl.registerLazySingleton<GetUpcomingTripsUseCase>(() => GetUpcomingTripsUseCase());

  // Blocs (registerFactory = new instance per call)
  sl.registerFactory<SplashBloc>(
    () => SplashBloc(initializeApp: sl()),
  );
  sl.registerFactory<HomeBloc>(
    () => HomeBloc(getUpcomingTrips: sl()),
  );
}
