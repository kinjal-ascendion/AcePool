import 'package:acepool/features/splash/domain/usecases/initialize_app_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final InitializeAppUseCase _initializeApp;

  SplashBloc({required InitializeAppUseCase initializeApp})
    : _initializeApp = initializeApp,
      super(const SplashInitial()) {
    on<SplashStarted>(_onSplashStarted);
  }

  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());
    try {
      await _initializeApp();
      emit(const SplashComplete());
    } catch (e) {
      emit(SplashError(e.toString()));
    }
  }
}
