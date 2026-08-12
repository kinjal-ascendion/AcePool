import 'package:acepool/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkFailure', () {
    test('exposes the message it was constructed with', () {
      const failure = NetworkFailure('no connection');
      expect(failure.message, 'no connection');
    });

    test('is a Failure', () {
      const failure = NetworkFailure('no connection');
      expect(failure, isA<Failure>());
    });
  });

  group('CacheFailure', () {
    test('exposes the message it was constructed with', () {
      const failure = CacheFailure('cache miss');
      expect(failure.message, 'cache miss');
    });

    test('is a Failure', () {
      const failure = CacheFailure('cache miss');
      expect(failure, isA<Failure>());
    });
  });

  group('UnexpectedFailure', () {
    test('exposes the message it was constructed with', () {
      const failure = UnexpectedFailure('something broke');
      expect(failure.message, 'something broke');
    });

    test('is a Failure', () {
      const failure = UnexpectedFailure('something broke');
      expect(failure, isA<Failure>());
    });
  });

  test('different subtypes with the same message are distinguishable by type', () {
    const network = NetworkFailure('x');
    const cache = CacheFailure('x');
    const unexpected = UnexpectedFailure('x');

    expect(network, isNot(isA<CacheFailure>()));
    expect(network, isNot(isA<UnexpectedFailure>()));
    expect(cache, isNot(isA<NetworkFailure>()));
    expect(cache, isNot(isA<UnexpectedFailure>()));
    expect(unexpected, isNot(isA<NetworkFailure>()));
    expect(unexpected, isNot(isA<CacheFailure>()));
  });
}
