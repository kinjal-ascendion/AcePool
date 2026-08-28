import 'package:acepool/core/constants/app_constants.dart';
import 'package:acepool/features/splash/domain/usecases/initialize_app_usecase.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InitializeAppUseCase', () {
    test('call() completes only after AppConstants.splashDuration elapses',
        () {
      final useCase = InitializeAppUseCase();

      fakeAsync((async) {
        var completed = false;
        useCase().then((_) => completed = true);

        // Not yet elapsed the full splash duration.
        async.elapse(AppConstants.splashDuration - const Duration(milliseconds: 1));
        expect(completed, isFalse);

        // Elapse the remainder so the delayed future fires.
        async.elapse(const Duration(milliseconds: 1));
        expect(completed, isTrue);
      });
    });

    test('call() future completes without throwing', () {
      final useCase = InitializeAppUseCase();

      fakeAsync((async) {
        expect(useCase(), completes);
        async.elapse(AppConstants.splashDuration);
      });
    });

    test('call() can be invoked multiple times independently', () {
      final useCase = InitializeAppUseCase();

      fakeAsync((async) {
        var firstDone = false;
        var secondDone = false;
        useCase().then((_) => firstDone = true);
        async.elapse(AppConstants.splashDuration);
        expect(firstDone, isTrue);

        useCase().then((_) => secondDone = true);
        async.elapse(AppConstants.splashDuration);
        expect(secondDone, isTrue);
      });
    });
  });
}
