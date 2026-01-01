import '../models/reminder_model.dart';

abstract class ReminderRemoteDataSource {
  Future<void> addReminder(ReminderModel reminder);
  Future<void> updateReminder(ReminderModel reminder);
  Future<void> deleteReminder(String id);
  Future<List<ReminderModel>> fetchReminders();
}
