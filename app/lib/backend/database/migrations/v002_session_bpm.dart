import '../migration_runner.dart';

const sessionBpmSchema = SchemaMigration(
  version: 2,
  statements: [
    'ALTER TABLE practice_sessions ADD COLUMN bpm INTEGER CHECK (bpm IS NULL OR (typeof(bpm) = \'integer\' AND bpm BETWEEN 20 AND 400))',
    'DROP VIEW saved_practice_sessions',
    "CREATE VIEW saved_practice_sessions AS SELECT * FROM practice_sessions WHERE state = 'saved'",
  ],
);
