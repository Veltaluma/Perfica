enum FocusDurationError { invalid, tooShort, tooLong }

abstract final class FocusDurationValidator {
  static const int minMinutes = 1;
  static const int maxMinutes = 720;

  const FocusDurationValidator._();

  static FocusDurationError? validate(String rawValue) {
    final value = int.tryParse(rawValue.trim());

    if (value == null) {
      return FocusDurationError.invalid;
    }

    if (value < minMinutes) {
      return FocusDurationError.tooShort;
    }

    if (value > maxMinutes) {
      return FocusDurationError.tooLong;
    }

    return null;
  }

  static int? parse(String rawValue) {
    if (validate(rawValue) != null) {
      return null;
    }

    return int.parse(rawValue.trim());
  }
}
