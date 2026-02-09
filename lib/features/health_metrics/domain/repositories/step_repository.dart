abstract class StepRepository {
  /// Returns a stream of step counts.
  /// The value emitted is the total steps since last boot (from Pedometer package)
  /// OR a processed daily step count depending on implementation.
  Stream<int> get stepCountStream;

  /// Initialize the step counting (permissions, etc.)
  Future<void> init();
}
