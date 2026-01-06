import 'package:bloc/bloc.dart';
import '../../domain/domain.dart';
import 'hydration_event.dart';
import 'hydration_state.dart';

class HydrationBloc extends Bloc<HydrationEvent, HydrationState> {
  final HydrationRepository repository;

  HydrationBloc({required this.repository}) : super(HydrationInitial()) {
    on<LogHydration>(_onLogHydration);
  }

  Future<void> _onLogHydration(
    LogHydration event,
    Emitter<HydrationState> emit,
  ) async {
    emit(HydrationSaving());
    final result = await repository.logWaterIntake(event.log);
    result.fold(
      (failure) => emit(HydrationFailure(failure.message)),
      (_) => emit(HydrationSuccess()),
    );
  }
}
