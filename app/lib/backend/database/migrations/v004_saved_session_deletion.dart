import '../migration_runner.dart';

const savedSessionDeletionSchema = SchemaMigration(
  version: 4,
  statements: [
    r'''
ALTER TABLE practice_sessions ADD COLUMN deleted_at INTEGER CHECK (
  deleted_at IS NULL OR (state = 'saved' AND typeof(deleted_at) = 'integer'
    AND deleted_at >= created_at AND updated_at >= deleted_at)
)
''',
    'DROP VIEW saved_practice_sessions',
    r'''
CREATE VIEW saved_practice_sessions AS
SELECT * FROM practice_sessions WHERE state = 'saved' AND deleted_at IS NULL
''',
    r'''
CREATE TRIGGER session_deletion_immutable
BEFORE UPDATE OF deleted_at ON practice_sessions
WHEN OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NOT OLD.deleted_at
BEGIN SELECT RAISE(ABORT, 'session_deletion_immutable'); END
''',
  ],
);
