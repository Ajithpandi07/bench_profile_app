import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_remote_data_source.dart';
import '../models/reminder_model.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderRemoteDataSource remoteDataSource;

  ReminderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addReminder(Reminder reminder) async {
    final reminderModel = ReminderModel(
      id: reminder.id,
      name: reminder.name,
      category: reminder.category,
      quantity: reminder.quantity,
      unit: reminder.unit,
      scheduleType: reminder.scheduleType,
      startDate: reminder.startDate,
      endDate: reminder.endDate,
      smartReminder: reminder.smartReminder,
      isCompleted: reminder.isCompleted,
    );
    await remoteDataSource.addReminder(reminderModel);
  }

  @override
  Stream<List<Reminder>> getReminders() {
    return remoteDataSource.getReminders();
  }
}
