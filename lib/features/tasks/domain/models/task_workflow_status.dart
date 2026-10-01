enum TaskWorkflowStatus {
  todo(0),
  inProgress(1),
  done(2);

  const TaskWorkflowStatus(this.storageValue);

  final int storageValue;

  static TaskWorkflowStatus fromStorageValue(int value) {
    return switch (value) {
      0 => TaskWorkflowStatus.todo,
      1 => TaskWorkflowStatus.inProgress,
      2 => TaskWorkflowStatus.done,
      _ => TaskWorkflowStatus.todo,
    };
  }
}
