import '../models/reminder_model.dart';

abstract class ReminderRemoteDataSource {
  Future<void> addReminder(ReminderModel reminder);
  Stream<List<ReminderModel>> getReminders();
}
