import '../migration_runner.dart';

const profilePracticeDraftsSchema = SchemaMigration(
  version: 3,
  statements: [
    'DROP INDEX one_unfinished_session',
    "CREATE UNIQUE INDEX one_unfinished_session_per_profile ON practice_sessions (profile_id) WHERE state <> 'saved'",
    "CREATE UNIQUE INDEX one_running_session ON practice_sessions ((1)) WHERE state = 'running'",
  ],
);
