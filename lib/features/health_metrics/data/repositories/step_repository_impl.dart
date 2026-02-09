import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/repositories/step_repository.dart';

class StepRepositoryImpl implements StepRepository {
  Stream<StepCount>? _stepCountStream;
  Stream<PedestrianStatus>? _pedestrianStatusStream;

  // We want to expose a stream of "Steps Today".
  // Pedometer returns "steps since boot".
  // Strategy:
  // 1. We need a baseline "steps since boot" at the start of the day (00:00).
  //    But we can't easily get that retroactively if the app wasn't running.
  // 2. Alternative Strategy (Hybrid):
  //    On App Start, fetch "Steps Today" from Health Connect (Source of Truth).
  //    Let this be `initialSteps`.
  //    Listen to Pedometer.
  //    On first Pedometer event `p1` (steps since boot), store `offset = p1`.
  //    On subsequent event `pn`, `delta = pn - offset`.
  //    `currentSteps = initialSteps + delta`.
  //
  //    Wait, "steps since boot" resets on reboot.
  //    If user reboots, `pn` will be small.
  //    We need to handle that.

  // Revised Strategy for "Live Updates":
  // We rely on Health Connect for the absolute number.
  // We use Pedometer purely for *visual liveliness* if possible, OR
  // just acknowledge that Pedometer "daily steps" might be different from Health Connect.
  //
  // Let's try to pass the raw Pedometer stream and let the Bloc combine it?
  // No, Repository should abstract.
  //
  // Simple approach for this task:
  // Return the raw stream from Pedometer. The Bloc will handle the logic of
  // "how to display this alongside Health Connect data".
  // Actually, Pedometer package says: "StepCount: The number of steps taken since the last system boot."
  //
  // If we want "Realtime steps count like google fit", Google Fit reads from the sensor service which aggregates.
  //
  // Let's implement a stream that emits the "Step Count" event.
  // The Bloc is already fetching "Steps Today" from Health Connect.
  // The Bloc can subscribe to this stream.
  // When a new event comes, calculate delta from previous event and add to total?
  //
  // Robust approach:
  // 1. Get `baseSteps` from Health Connect (e.g. 5000).
  // 2. Start listening to Pedometer. First event is `bootSteps1` (e.g. 100,000).
  // 3. User walks 10 steps. New event `bootSteps2` (100,010).
  // 4. Delta = 10.
  // 5. Display = 5000 + 10 = 5010.

  final _stepController = StreamController<int>.broadcast();
  int? _bootStepsOffset;

  @override
  Stream<int> get stepCountStream => _stepController.stream;

  @override
  Future<void> init() async {
    bool granted = await Permission.activityRecognition.request().isGranted;
    if (!granted) {
      // Try asking?
      // For now assume granted or fail silently for stream
      return;
    }

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream?.listen(_onStepCount).onError(_onError);
  }

  void _onStepCount(StepCount event) {
    if (_bootStepsOffset == null) {
      _bootStepsOffset = event.steps;
      // First event doesn't trigger a visual update since delta is 0
      // But we can emit 0 to signal "ready"
      _stepController.add(0);
    } else {
      final delta = event.steps - _bootStepsOffset!;
      // Handle reboot case: if event.steps < _bootStepsOffset, device rebooted?
      // If rebooted, event.steps starts from 0.
      // Then delta would be negative.
      // If negative, reset offset.
      if (delta < 0) {
        _bootStepsOffset = event.steps;
        // Delta is 0 relative to new boot
        _stepController.add(0);
      } else {
        _stepController.add(delta);
      }
    }
  }

  void _onError(error) {
    print('Pedometer Error: $error');
  }
}
