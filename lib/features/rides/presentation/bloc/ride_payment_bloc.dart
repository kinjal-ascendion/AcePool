import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';

part 'ride_payment_event.dart';
part 'ride_payment_state.dart';

class RidePaymentBloc extends Bloc<RidePaymentEvent, RidePaymentState> {
  RidePaymentBloc({required RidesRepository ridesRepository})
      : _ridesRepository = ridesRepository,
        super(const RidePaymentState()) {
    on<RidePaymentMethodSelected>(_onMethodSelected);
    on<RidePaymentCompleteRequested>(_onCompleteRequested);
  }

  final RidesRepository _ridesRepository;

  void _onMethodSelected(RidePaymentMethodSelected event, Emitter<RidePaymentState> emit) {
    emit(state.copyWith(selectedMethod: event.method));
  }

  Future<void> _onCompleteRequested(
    RidePaymentCompleteRequested event,
    Emitter<RidePaymentState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await _ridesRepository.completeRide(
        rideId: event.rideId,
        paymentMethod: state.selectedMethod,
      );
      emit(state.copyWith(isSubmitting: false, status: RidePaymentStatus.success));
    } catch (e) {
      // Matches original: even on error, the page proceeds to the success
      // screen (the user already tapped "Done") — only the spinner stops
      // first before it does.
      emit(state.copyWith(isSubmitting: false, status: RidePaymentStatus.success));
    }
  }
}
