import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<void> addReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(String id);
  Future<List<Reminder>> getReminders();
}
