import 'package:isar/isar.dart';

part 'ignored_sleep_draft.g.dart';

@Collection()
class IgnoredSleepDraft {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late DateTime ignoredAt;
}
