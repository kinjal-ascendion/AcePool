import 'package:acepool/core/usecases/scan_license_usecase.dart';
import 'package:acepool/features/address/data/repositories/address_repository_impl.dart';
import 'package:acepool/features/address/domain/repositories/address_repository.dart';
import 'package:acepool/features/address/presentation/bloc/add_address_bloc.dart';
import 'package:acepool/features/address/presentation/bloc/addresses_bloc.dart';
import 'package:acepool/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:acepool/features/auth/domain/repositories/auth_repository.dart';
import 'package:acepool/features/auth/domain/usecases/cancel_signup_usecase.dart';
import 'package:acepool/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:acepool/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:acepool/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:acepool/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:acepool/features/auth/presentation/bloc/login_bloc.dart';
import 'package:acepool/features/auth/presentation/bloc/otp_bloc.dart';
import 'package:acepool/features/auth/presentation/bloc/signup_bloc.dart';
import 'package:acepool/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/chat/domain/usecases/get_chat_rooms_usecase.dart';
import 'package:acepool/features/chat/domain/usecases/get_messages_usecase.dart';
import 'package:acepool/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:acepool/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:acepool/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:acepool/features/home/data/repositories/home_repository_impl.dart';
import 'package:acepool/features/home/domain/repositories/home_repository.dart';
import 'package:acepool/features/home/domain/usecases/estimate_route_usecase.dart';
import 'package:acepool/features/home/domain/usecases/get_travel_preference_usecase.dart';
import 'package:acepool/features/home/domain/usecases/get_upcoming_trips_usecase.dart';
import 'package:acepool/features/home/domain/usecases/get_vehicle_options_usecase.dart';
import 'package:acepool/features/home/domain/usecases/schedule_ride_usecase.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/home/presentation/bloc/pricing_bloc.dart';
import 'package:acepool/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:acepool/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:acepool/features/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:acepool/features/onboarding/domain/usecases/get_onboarding_status_usecase.dart';
import 'package:acepool/features/onboarding/presentation/bloc/travel_preference_bloc.dart';
import 'package:acepool/features/onboarding/presentation/bloc/vehicle_preference_bloc.dart';
import 'package:acepool/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:acepool/features/profile/domain/repositories/profile_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/account_settings_bloc.dart';
import 'package:acepool/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:acepool/features/profile/presentation/bloc/profile_payment_bloc.dart';
import 'package:acepool/features/profile/presentation/bloc/ride_history_bloc.dart';
import 'package:acepool/features/profile/data/repositories/ride_history_repository_impl.dart';
import 'package:acepool/features/profile/domain/repositories/ride_history_repository.dart';
import 'package:acepool/features/profile/data/repositories/ratings_repository_impl.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/ratings_summary_bloc.dart';
import 'package:acepool/features/profile/presentation/bloc/ratings_by_you_bloc.dart';
import 'package:acepool/features/profile/presentation/bloc/review_riders_bloc.dart';
import 'package:acepool/features/profile/presentation/bloc/review_your_riders_bloc.dart';
import 'package:acepool/features/profile/presentation/bloc/route_matching_bloc.dart';
import 'package:acepool/features/profile/presentation/bloc/vehicle_bloc.dart';
import 'package:acepool/features/profile/data/repositories/vehicle_repository_impl.dart';
import 'package:acepool/features/profile/domain/repositories/vehicle_repository.dart';
import 'package:acepool/features/rides/data/repositories/rides_repository_impl.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';
import 'package:acepool/features/rides/domain/usecases/find_matching_rides_usecase.dart';
import 'package:acepool/features/rides/presentation/bloc/drives_detail_bloc.dart';
import 'package:acepool/features/rides/presentation/bloc/find_ride_results_bloc.dart';
import 'package:acepool/features/rides/presentation/bloc/ride_details_bloc.dart';
import 'package:acepool/features/rides/presentation/bloc/ride_map_bloc.dart';
import 'package:acepool/features/rides/presentation/bloc/ride_payment_bloc.dart';
import 'package:acepool/features/rides/presentation/bloc/track_route_bloc.dart';
import 'package:acepool/features/splash/domain/usecases/initialize_app_usecase.dart';
import 'package:acepool/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:acepool/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:acepool/features/trips/domain/repositories/trips_repository.dart';
import 'package:acepool/features/trips/presentation/bloc/trips_bloc.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

void initDependencies() {
  // Repositories
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<AddressRepository>(() => AddressRepositoryImpl());
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl());
  sl.registerLazySingleton<RidesRepository>(
    () => RidesRepositoryImpl(chatRepository: sl()),
  );
  sl.registerLazySingleton<TripsRepository>(() => TripsRepositoryImpl());
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl());
  sl.registerLazySingleton<VehicleRepository>(() => VehicleRepositoryImpl());
  sl.registerLazySingleton<RideHistoryRepository>(() => RideHistoryRepositoryImpl());
  sl.registerLazySingleton<RatingsRepository>(() => RatingsRepositoryImpl());

  // Use cases
  sl.registerLazySingleton<GetOnboardingStatusUseCase>(
    () => GetOnboardingStatusUseCase(sl()),
  );
  sl.registerLazySingleton<CompleteOnboardingUseCase>(
    () => CompleteOnboardingUseCase(sl()),
  );
  sl.registerLazySingleton<InitializeAppUseCase>(() => InitializeAppUseCase());
  sl.registerLazySingleton<GetUpcomingTripsUseCase>(
    () => GetUpcomingTripsUseCase(sl()),
  );
  sl.registerLazySingleton<ScheduleRideUseCase>(() => ScheduleRideUseCase(sl()));
  sl.registerLazySingleton<GetTravelPreferenceUseCase>(
    () => GetTravelPreferenceUseCase(sl()),
  );
  sl.registerLazySingleton<GetVehicleOptionsUseCase>(
    () => GetVehicleOptionsUseCase(sl()),
  );
  sl.registerLazySingleton<FindMatchingRidesUseCase>(
    () => FindMatchingRidesUseCase(sl()),
  );
  sl.registerLazySingleton<EstimateRouteUseCase>(() => EstimateRouteUseCase(sl()));

  // Shared (core) use cases
  sl.registerLazySingleton<ScanLicenseUseCase>(() => ScanLicenseUseCase());

  // Auth use cases
  sl.registerLazySingleton<SignInUseCase>(() => SignInUseCase(sl()));
  sl.registerLazySingleton<SignUpUseCase>(() => SignUpUseCase(sl()));
  sl.registerLazySingleton<SendOtpUseCase>(() => SendOtpUseCase(sl()));
  sl.registerLazySingleton<VerifyOtpUseCase>(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton<CancelSignupUseCase>(
    () => CancelSignupUseCase(sl()),
  );

  // Chat Use cases
  sl.registerLazySingleton<GetMessagesUseCase>(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton<SendMessageUseCase>(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton<GetChatRoomsUseCase>(
    () => GetChatRoomsUseCase(sl()),
  );

  // Repositories
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl());

  // Blocs (registerFactory = new instance per call)
  sl.registerFactory<SplashBloc>(() => SplashBloc(initializeApp: sl()));
  sl.registerFactory<HomeBloc>(
    () => HomeBloc(
      getUpcomingTrips: sl(),
      getTravelPreference: sl(),
      findMatchingRides: sl(),
    ),
  );
  sl.registerFactory<PricingBloc>(
    () => PricingBloc(
      estimateRoute: sl(),
      scheduleRide: sl(),
      getVehicleOptions: sl(),
    ),
  );
  sl.registerFactory<ChatBloc>(
    () => ChatBloc(getMessages: sl(), sendMessage: sl()),
  );
  sl.registerFactory<ChatListBloc>(() => ChatListBloc(getChatRooms: sl()));
  sl.registerFactory<TravelPreferenceBloc>(() => TravelPreferenceBloc());
  sl.registerFactory<VehiclePreferenceBloc>(() => VehiclePreferenceBloc());
  sl.registerFactory<LoginBloc>(() => LoginBloc(signIn: sl()));
  sl.registerFactory<SignupBloc>(
    () => SignupBloc(signUp: sl(), scanLicense: sl()),
  );
  sl.registerFactory<OtpBloc>(
    () => OtpBloc(sendOtp: sl(), verifyOtp: sl(), cancelSignup: sl()),
  );

  // Rides blocs
  sl.registerFactory<FindRideResultsBloc>(
    () => FindRideResultsBloc(findMatchingRides: sl()),
  );
  sl.registerFactory<RideDetailsBloc>(
    () => RideDetailsBloc(ridesRepository: sl()),
  );
  sl.registerFactory<DrivesDetailBloc>(
    () => DrivesDetailBloc(ridesRepository: sl()),
  );
  sl.registerFactory<RideMapBloc>(() => RideMapBloc(ridesRepository: sl()));
  sl.registerFactory<TrackRouteBloc>(() => TrackRouteBloc(ridesRepository: sl()));
  sl.registerFactory<RidePaymentBloc>(() => RidePaymentBloc(ridesRepository: sl()));
  sl.registerFactory<TripsBloc>(() => TripsBloc(tripsRepository: sl()));
  sl.registerFactory<ProfileBloc>(() => ProfileBloc(profileRepository: sl()));
  sl.registerFactory<RouteMatchingBloc>(() => RouteMatchingBloc(profileRepository: sl()));
  sl.registerFactory<AccountSettingsBloc>(
    () => AccountSettingsBloc(profileRepository: sl()),
  );
  sl.registerFactory<VehicleBloc>(() => VehicleBloc(vehicleRepository: sl()));
  sl.registerFactory<ProfilePaymentBloc>(
    () => ProfilePaymentBloc(profileRepository: sl()),
  );
  sl.registerFactory<RideHistoryBloc>(
    () => RideHistoryBloc(rideHistoryRepository: sl()),
  );
  sl.registerFactory<RatingsSummaryBloc>(
    () => RatingsSummaryBloc(ratingsRepository: sl()),
  );
  sl.registerFactory<RatingsByYouBloc>(
    () => RatingsByYouBloc(ratingsRepository: sl()),
  );
  sl.registerFactory<ReviewRidersBloc>(
    () => ReviewRidersBloc(ratingsRepository: sl()),
  );
  sl.registerFactory<ReviewYourRidersBloc>(
    () => ReviewYourRidersBloc(ratingsRepository: sl()),
  );
  sl.registerFactory<AddressesBloc>(() => AddressesBloc(addressRepository: sl()));
  sl.registerFactory<AddAddressBloc>(() => AddAddressBloc(addressRepository: sl()));
}
