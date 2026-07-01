import 'package:acepool/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/chat/domain/usecases/get_chat_rooms_usecase.dart';
import 'package:acepool/features/chat/domain/usecases/get_messages_usecase.dart';
import 'package:acepool/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:acepool/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:acepool/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:acepool/features/splash/domain/usecases/initialize_app_usecase.dart';
import 'package:acepool/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:acepool/features/home/domain/usecases/get_upcoming_trips_usecase.dart';
import 'package:acepool/features/home/domain/usecases/schedule_ride_usecase.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';

final sl = GetIt.instance;

void initDependencies() {
  // Use cases
  sl.registerLazySingleton<InitializeAppUseCase>(() => InitializeAppUseCase());
  sl.registerLazySingleton<GetUpcomingTripsUseCase>(() => GetUpcomingTripsUseCase());
  sl.registerLazySingleton<ScheduleRideUseCase>(() => ScheduleRideUseCase());

  // Chat Use cases
  sl.registerLazySingleton<GetMessagesUseCase>(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton<SendMessageUseCase>(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton<GetChatRoomsUseCase>(() => GetChatRoomsUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl());

  // Blocs (registerFactory = new instance per call)
  sl.registerFactory<SplashBloc>(
    () => SplashBloc(initializeApp: sl()),
  );
  sl.registerFactory<HomeBloc>(
    () => HomeBloc(getUpcomingTrips: sl(), scheduleRide: sl()),
  );
  sl.registerFactory<ChatBloc>(
    () => ChatBloc(getMessages: sl(), sendMessage: sl()),
  );
  sl.registerFactory<ChatListBloc>(
    () => ChatListBloc(getChatRooms: sl()),
  );
}
