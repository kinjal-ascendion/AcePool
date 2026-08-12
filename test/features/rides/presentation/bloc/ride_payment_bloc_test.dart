import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';
import 'package:acepool/features/rides/presentation/bloc/ride_payment_bloc.dart';

class MockRidesRepository extends Mock implements RidesRepository {}

void main() {
  late MockRidesRepository repository;

  setUp(() {
    repository = MockRidesRepository();
  });

  group('RidePaymentEvent equality', () {
    test('RidePaymentMethodSelected supports value equality based on props', () {
      expect(
        const RidePaymentMethodSelected('cash'),
        const RidePaymentMethodSelected('cash'),
      );
      expect(const RidePaymentMethodSelected('cash').props, ['cash']);
      expect(
        const RidePaymentMethodSelected('cash'),
        isNot(const RidePaymentMethodSelected('upi')),
      );
    });

    test('RidePaymentCompleteRequested supports value equality based on props', () {
      expect(
        const RidePaymentCompleteRequested('ride-1'),
        const RidePaymentCompleteRequested('ride-1'),
      );
      expect(const RidePaymentCompleteRequested('ride-1').props, ['ride-1']);
      expect(
        const RidePaymentCompleteRequested('ride-1'),
        isNot(const RidePaymentCompleteRequested('ride-2')),
      );
    });
  });

  group('RidePaymentBloc', () {
    test('initial state defaults to upi, not submitting, initial status', () {
      expect(
        RidePaymentBloc(ridesRepository: repository).state,
        const RidePaymentState(),
      );
    });

    blocTest<RidePaymentBloc, RidePaymentState>(
      'RidePaymentMethodSelected updates selectedMethod only',
      build: () => RidePaymentBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(const RidePaymentMethodSelected('cash')),
      expect: () => [
        const RidePaymentState(selectedMethod: 'cash'),
      ],
    );

    blocTest<RidePaymentBloc, RidePaymentState>(
      'RidePaymentCompleteRequested completes the ride with the currently '
      'selected method and emits success',
      setUp: () {
        when(() => repository.completeRide(rideId: 'ride-1', paymentMethod: 'card'))
            .thenAnswer((_) async {});
      },
      build: () => RidePaymentBloc(ridesRepository: repository),
      seed: () => const RidePaymentState(selectedMethod: 'card'),
      act: (bloc) => bloc.add(const RidePaymentCompleteRequested('ride-1')),
      expect: () => [
        const RidePaymentState(selectedMethod: 'card', isSubmitting: true),
        const RidePaymentState(
          selectedMethod: 'card',
          isSubmitting: false,
          status: RidePaymentStatus.success,
        ),
      ],
      verify: (_) {
        verify(() => repository.completeRide(rideId: 'ride-1', paymentMethod: 'card'))
            .called(1);
      },
    );

    blocTest<RidePaymentBloc, RidePaymentState>(
      'RidePaymentCompleteRequested still transitions to success even when '
      'completeRide throws (spinner stops, page proceeds)',
      setUp: () {
        when(() => repository.completeRide(rideId: 'ride-2', paymentMethod: 'upi'))
            .thenThrow(Exception('payment service down'));
      },
      build: () => RidePaymentBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(const RidePaymentCompleteRequested('ride-2')),
      expect: () => [
        const RidePaymentState(isSubmitting: true),
        const RidePaymentState(isSubmitting: false, status: RidePaymentStatus.success),
      ],
    );
  });
}
