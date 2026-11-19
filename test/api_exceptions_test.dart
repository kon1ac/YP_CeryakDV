import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/core/api_exceptions.dart';

void main() {
  test('mapHttpError maps PocketBase 400 field errors to ValidationException', () {
    final error = mapHttpError(400, {
      'message': 'Failed to create record.',
      'data': {
        'jerseyNumber': {'code': 'validation_not_unique', 'message': 'Value must be unique'},
      },
    });
    expect(error, isA<ConflictException>());
  });

  test('mapHttpError maps plain 400 to ValidationException', () {
    final error = mapHttpError(400, {
      'message': 'Something wrong',
      'data': {
        'email': {'message': 'Invalid email'},
      },
    });
    expect(error, isA<ValidationException>());
    final ve = error as ValidationException;
    expect(ve.errors['email'], 'Invalid email');
  });

  test('mapHttpError 401/403/409', () {
    expect(mapHttpError(401, null), isA<UnauthorizedException>());
    expect(mapHttpError(403, null), isA<ForbiddenException>());
    expect(mapHttpError(409, {'message': 'conflict'}), isA<ConflictException>());
  });
}
