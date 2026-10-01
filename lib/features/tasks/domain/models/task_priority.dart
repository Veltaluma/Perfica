enum TaskPriority {
  none(0),
  low(1),
  medium(2),
  high(3);

  const TaskPriority(this.storageValue);

  final int storageValue;

  static TaskPriority fromStorageValue(int value) {
    return switch (value) {
      0 => TaskPriority.none,
      1 => TaskPriority.low,
      2 => TaskPriority.medium,
      3 => TaskPriority.high,
      _ => throw ArgumentError.value(
        value,
        'value',
        'Unsupported task priority.',
      ),
    };
  }
}
