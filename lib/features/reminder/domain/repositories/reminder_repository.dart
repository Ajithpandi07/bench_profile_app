import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<void> addReminder(Reminder reminder);
  Stream<List<Reminder>> getReminders();
}
