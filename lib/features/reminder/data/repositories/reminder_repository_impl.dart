import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_remote_data_source.dart';
import '../models/reminder_model.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderRemoteDataSource remoteDataSource;

  ReminderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> addReminder(Reminder reminder) async {
    try {
      final now = DateTime.now();
      final reminderModel = ReminderModel.fromEntity(
        reminder,
      ).copyWith(createdAt: now, updatedAt: now);
      return await remoteDataSource.addReminder(reminderModel);
    } catch (e) {
      throw Exception('Failed to add reminder: $e');
    }
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    try {
      final reminderModel = ReminderModel.fromEntity(
        reminder,
      ).copyWith(updatedAt: DateTime.now());
      await remoteDataSource.updateReminder(reminderModel);
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }

  @override
  Future<void> deleteReminder(String id) async {
    print('DEBUG REPO: deleteReminder called with ID: $id');
    try {
      print('DEBUG REPO: Calling remoteDataSource.deleteReminder');
      await remoteDataSource.deleteReminder(id);
      print(
        'DEBUG REPO: remoteDataSource.deleteReminder completed successfully',
      );
    } catch (e) {
      print('DEBUG REPO: deleteReminder failed with error: $e');
      throw Exception('Failed to delete reminder: $e');
    }
  }

  @override
  Future<List<Reminder>> getReminders() async {
    try {
      final reminderModels = await remoteDataSource.fetchReminders();
      // Sort by createdAt descending (newest first)
      reminderModels.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return reminderModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Failed to fetch reminders: $e');
      return []; // Return empty list on failure or rethrow based on requirement
    }
  }
}
