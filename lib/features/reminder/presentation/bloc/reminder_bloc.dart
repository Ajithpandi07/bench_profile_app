import 'package:flutter_bloc/flutter_bloc.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/entities/reminder.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final ReminderRepository _repository;

  ReminderBloc({required ReminderRepository repository})
      : _repository = repository,
        super(ReminderInitial()) {
    on<LoadReminders>(_onLoadReminders);
    on<AddReminder>(_onAddReminder);
  }

  Future<void> _onLoadReminders(
      LoadReminders event, Emitter<ReminderState> emit) async {
    emit(ReminderLoading());
    try {
      await emit.forEach<List<Reminder>>(
        _repository.getReminders(),
        onData: (reminders) => ReminderLoaded(reminders),
        onError: (e, __) => ReminderError('Failed stream: $e'),
      );
    } catch (e) {
      emit(ReminderError('Failed: $e'));
    }
  }

  Future<void> _onAddReminder(
      AddReminder event, Emitter<ReminderState> emit) async {
    try {
      final reminder = Reminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: event.name,
        category: event.category,
        quantity: event.quantity,
        unit: event.unit,
        scheduleType: event.scheduleType,
        startDate: event.startDate,
        endDate: event.endDate,
        smartReminder: event.smartReminder,
      );
      await _repository.addReminder(reminder);
      // Stream subscription handles state update
    } catch (e) {
      // Handle error
    }
  }
}
