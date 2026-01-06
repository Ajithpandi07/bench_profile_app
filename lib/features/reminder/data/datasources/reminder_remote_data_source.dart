import '../models/reminder_model.dart';

abstract class ReminderRemoteDataSource {
  Future<String> addReminder(ReminderModel reminder);
  Future<void> updateReminder(ReminderModel reminder);
  Future<void> deleteReminder(String id);
  Future<List<ReminderModel>> fetchReminders();
}
