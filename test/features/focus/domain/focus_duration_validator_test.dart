import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/features/focus/domain/focus_duration_validator.dart';

void main() {
  test('accepts custom focus duration inside the valid range', () {
    expect(FocusDurationValidator.validate('100'), isNull);

    expect(FocusDurationValidator.parse('100'), 100);
  });

  test('rejects custom focus duration above the maximum', () {
    expect(FocusDurationValidator.validate('721'), FocusDurationError.tooLong);

    expect(FocusDurationValidator.parse('721'), isNull);
  });

  test('rejects zero and negative custom focus duration', () {
    expect(FocusDurationValidator.validate('0'), FocusDurationError.tooShort);

    expect(FocusDurationValidator.validate('-5'), FocusDurationError.tooShort);
  });

  test('rejects non-numeric custom focus duration', () {
    expect(FocusDurationValidator.validate('abc'), FocusDurationError.invalid);
  });
}
