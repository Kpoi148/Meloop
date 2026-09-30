import '../migration_runner.dart';

const initialSchema = SchemaMigration(
  version: 1,
  statements: [
    r'''
CREATE TABLE instrument_profiles (
  id TEXT PRIMARY KEY NOT NULL CHECK (
    length(id) = 36 AND id GLOB '????????-????-4???-[89ab]???-????????????'
    AND length(replace(id, '-', '')) = 32
    AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*'
  ),
  name TEXT NOT NULL CHECK (
    length(name) BETWEEN 1 AND 50 AND length(trim(name)) > 0
    AND instr(name, char(0)) = 0 AND instr(name, char(10)) = 0
    AND instr(name, char(13)) = 0
  ),
  name_key TEXT NOT NULL UNIQUE CHECK (length(name_key) > 0),
  instrument_type TEXT NOT NULL CHECK (
    instrument_type IN ('guitar', 'piano', 'ukulele', 'violin', 'flute', 'drums', 'other')
  ),
  custom_type TEXT NOT NULL DEFAULT '' CHECK (
    (instrument_type = 'other' AND length(custom_type) BETWEEN 1 AND 40
      AND length(trim(custom_type)) > 0)
    OR (instrument_type <> 'other' AND custom_type = '')
  ),
  created_at INTEGER NOT NULL CHECK (typeof(created_at) = 'integer' AND created_at >= 0),
  updated_at INTEGER NOT NULL CHECK (typeof(updated_at) = 'integer' AND updated_at >= created_at)
)
''',
    r'''
CREATE TABLE practice_sessions (
  id TEXT PRIMARY KEY NOT NULL CHECK (
    length(id) = 36 AND id GLOB '????????-????-4???-[89ab]???-????????????'
    AND length(replace(id, '-', '')) = 32
    AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*'
  ),
  profile_id TEXT NOT NULL REFERENCES instrument_profiles(id) ON DELETE CASCADE,
  state TEXT NOT NULL CHECK (state IN ('running', 'paused', 'review', 'saved')),
  title TEXT NOT NULL CHECK (
    length(title) BETWEEN 1 AND 100 AND length(trim(title)) > 0
    AND instr(title, char(0)) = 0 AND instr(title, char(10)) = 0
    AND instr(title, char(13)) = 0
  ),
  practice_date TEXT NOT NULL CHECK (
    practice_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
    AND practice_date >= '2000-01-01'
    AND CAST(substr(practice_date, 6, 2) AS INTEGER) BETWEEN 1 AND 12
    AND CAST(substr(practice_date, 9, 2) AS INTEGER) BETWEEN 1 AND
      CASE CAST(substr(practice_date, 6, 2) AS INTEGER)
        WHEN 2 THEN CASE
          WHEN CAST(substr(practice_date, 1, 4) AS INTEGER) % 4 = 0
          AND (CAST(substr(practice_date, 1, 4) AS INTEGER) % 100 <> 0
            OR CAST(substr(practice_date, 1, 4) AS INTEGER) % 400 = 0)
          THEN 29 ELSE 28 END
        WHEN 4 THEN 30 WHEN 6 THEN 30 WHEN 9 THEN 30 WHEN 11 THEN 30
        ELSE 31 END
  ),
  duration_seconds INTEGER CHECK (
    duration_seconds IS NULL OR (typeof(duration_seconds) = 'integer' AND duration_seconds BETWEEN 1 AND 86400)
  ),
  measured_duration_seconds INTEGER CHECK (
    measured_duration_seconds IS NULL OR (typeof(measured_duration_seconds) = 'integer' AND measured_duration_seconds BETWEEN 0 AND 86400)
  ),
  start_offset_minutes INTEGER NOT NULL CHECK (
    typeof(start_offset_minutes) = 'integer' AND start_offset_minutes BETWEEN -840 AND 840
  ),
  practiced TEXT NOT NULL DEFAULT '' CHECK (length(practiced) <= 2000 AND instr(practiced, char(0)) = 0),
  difficulty TEXT NOT NULL DEFAULT '' CHECK (length(difficulty) <= 2000 AND instr(difficulty, char(0)) = 0),
  next_note TEXT NOT NULL DEFAULT '' CHECK (length(next_note) <= 2000 AND instr(next_note, char(0)) = 0),
  mood INTEGER CHECK (mood IS NULL OR (typeof(mood) = 'integer' AND mood BETWEEN 1 AND 5)),
  focus INTEGER CHECK (focus IS NULL OR (typeof(focus) = 'integer' AND focus BETWEEN 1 AND 5)),
  title_search TEXT NOT NULL DEFAULT '',
  practiced_search TEXT NOT NULL DEFAULT '',
  difficulty_search TEXT NOT NULL DEFAULT '',
  next_search TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL CHECK (typeof(created_at) = 'integer' AND created_at >= 0),
  updated_at INTEGER NOT NULL CHECK (typeof(updated_at) = 'integer' AND updated_at >= created_at),
  CHECK (state <> 'saved' OR (duration_seconds IS NOT NULL AND measured_duration_seconds IS NOT NULL))
)
''',
    r'''
CREATE TABLE session_drafts (
  session_id TEXT PRIMARY KEY NOT NULL REFERENCES practice_sessions(id) ON DELETE CASCADE,
  accumulated_ms INTEGER NOT NULL DEFAULT 0 CHECK (typeof(accumulated_ms) = 'integer' AND accumulated_ms BETWEEN 0 AND 86400000),
  checkpoint_at INTEGER NOT NULL CHECK (typeof(checkpoint_at) = 'integer' AND checkpoint_at >= 0),
  review_input_json TEXT CHECK (review_input_json IS NULL OR length(review_input_json) <= 65536),
  updated_at INTEGER NOT NULL CHECK (typeof(updated_at) = 'integer' AND updated_at >= checkpoint_at)
)
''',
    r'''
CREATE TABLE recordings (
  id TEXT PRIMARY KEY NOT NULL CHECK (
    length(id) = 36 AND id GLOB '????????-????-4???-[89ab]???-????????????'
    AND length(replace(id, '-', '')) = 32
    AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*'
  ),
  session_id TEXT NOT NULL REFERENCES practice_sessions(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('pending', 'ready', 'unavailable')),
  temp_relative_path TEXT UNIQUE CHECK (
    temp_relative_path IS NULL OR (
      length(temp_relative_path) > 0 AND substr(temp_relative_path, 1, 1) <> '/'
      AND instr(temp_relative_path, '\') = 0 AND instr(temp_relative_path, ':') = 0
      AND instr('/' || temp_relative_path || '/', '/../') = 0
      AND instr('/' || temp_relative_path || '/', '/./') = 0
      AND instr(temp_relative_path, '//') = 0 AND instr(temp_relative_path, char(0)) = 0
    )
  ),
  local_relative_path TEXT UNIQUE CHECK (
    local_relative_path IS NULL OR (
      length(local_relative_path) > 0 AND substr(local_relative_path, 1, 1) <> '/'
      AND instr(local_relative_path, '\') = 0 AND instr(local_relative_path, ':') = 0
      AND instr('/' || local_relative_path || '/', '/../') = 0
      AND instr('/' || local_relative_path || '/', '/./') = 0
      AND instr(local_relative_path, '//') = 0 AND instr(local_relative_path, char(0)) = 0
      AND substr(local_relative_path, -4) = '.m4a'
    )
  ),
  filename TEXT CHECK (filename IS NULL OR (
    length(filename) BETWEEN 5 AND 104 AND substr(filename, -4) = '.m4a'
    AND instr(filename, '/') = 0 AND instr(filename, '\') = 0 AND instr(filename, char(0)) = 0
  )),
  duration_ms INTEGER CHECK (duration_ms IS NULL OR (typeof(duration_ms) = 'integer' AND duration_ms >= 1000)),
  size_bytes INTEGER CHECK (size_bytes IS NULL OR (typeof(size_bytes) = 'integer' AND size_bytes > 0)),
  sample_rate_hz INTEGER CHECK (sample_rate_hz IS NULL OR sample_rate_hz IN (44100, 48000)),
  channel_count INTEGER CHECK (channel_count IS NULL OR channel_count = 1),
  codec TEXT NOT NULL DEFAULT 'aac' CHECK (codec = 'aac'),
  container TEXT NOT NULL DEFAULT 'm4a' CHECK (container = 'm4a'),
  created_at INTEGER NOT NULL CHECK (typeof(created_at) = 'integer' AND created_at >= 0),
  updated_at INTEGER NOT NULL CHECK (typeof(updated_at) = 'integer' AND updated_at >= created_at),
  CHECK ((status = 'pending' AND temp_relative_path IS NOT NULL)
    OR (status IN ('ready', 'unavailable') AND temp_relative_path IS NULL
      AND local_relative_path IS NOT NULL AND filename IS NOT NULL
      AND duration_ms IS NOT NULL AND size_bytes IS NOT NULL
      AND sample_rate_hz IS NOT NULL AND channel_count IS NOT NULL))
)
''',
    r'''
CREATE TABLE weekly_goals (
  profile_id TEXT PRIMARY KEY NOT NULL REFERENCES instrument_profiles(id) ON DELETE CASCADE,
  enabled INTEGER NOT NULL DEFAULT 0 CHECK (enabled IN (0, 1)),
  target_days INTEGER NOT NULL DEFAULT 4 CHECK (typeof(target_days) = 'integer' AND target_days BETWEEN 1 AND 7),
  updated_at INTEGER NOT NULL CHECK (typeof(updated_at) = 'integer' AND updated_at >= 0)
)
''',
    r'''
CREATE TABLE app_preferences (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  language TEXT NOT NULL CHECK (language IN ('vi', 'en')),
  selected_profile_id TEXT REFERENCES instrument_profiles(id) ON DELETE SET NULL,
  updated_at INTEGER NOT NULL CHECK (typeof(updated_at) = 'integer' AND updated_at >= 0)
)
''',
    r'''
CREATE TABLE reminder_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  enabled INTEGER NOT NULL DEFAULT 0 CHECK (enabled IN (0, 1)),
  weekdays_mask INTEGER NOT NULL DEFAULT 0 CHECK (typeof(weekdays_mask) = 'integer' AND weekdays_mask BETWEEN 0 AND 127),
  local_time_minutes INTEGER NOT NULL DEFAULT 1170 CHECK (typeof(local_time_minutes) = 'integer' AND local_time_minutes BETWEEN 0 AND 1439),
  schedule_revision INTEGER NOT NULL DEFAULT 1 CHECK (typeof(schedule_revision) = 'integer' AND schedule_revision >= 1),
  applied_revision INTEGER CHECK (applied_revision IS NULL OR (typeof(applied_revision) = 'integer' AND applied_revision BETWEEN 1 AND schedule_revision)),
  last_delivered_local_date TEXT,
  updated_at INTEGER NOT NULL CHECK (typeof(updated_at) = 'integer' AND updated_at >= 0),
  CHECK (enabled = 0 OR weekdays_mask > 0)
)
''',
    r'''
CREATE TABLE metronome_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  bpm INTEGER NOT NULL DEFAULT 80 CHECK (typeof(bpm) = 'integer' AND bpm BETWEEN 40 AND 240),
  beats_per_bar INTEGER NOT NULL DEFAULT 4 CHECK (typeof(beats_per_bar) = 'integer' AND beats_per_bar BETWEEN 1 AND 12),
  updated_at INTEGER NOT NULL CHECK (typeof(updated_at) = 'integer' AND updated_at >= 0)
)
''',
    r'''
CREATE TABLE file_cleanup_queue (
  id INTEGER PRIMARY KEY,
  storage_namespace TEXT NOT NULL CHECK (storage_namespace IN ('audio', 'audio_temp', 'export_temp')),
  relative_path TEXT NOT NULL CHECK (
    length(relative_path) > 0 AND substr(relative_path, 1, 1) <> '/'
    AND instr(relative_path, '\') = 0 AND instr(relative_path, ':') = 0
    AND instr('/' || relative_path || '/', '/../') = 0
    AND instr('/' || relative_path || '/', '/./') = 0
    AND instr(relative_path, '//') = 0 AND instr(relative_path, char(0)) = 0
  ),
  reason TEXT NOT NULL CHECK (reason IN ('recording_deleted', 'capture_finalized', 'restore', 'reset', 'orphan_temp')),
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (typeof(attempt_count) = 'integer' AND attempt_count >= 0),
  next_attempt_at INTEGER CHECK (next_attempt_at IS NULL OR (typeof(next_attempt_at) = 'integer' AND next_attempt_at >= 0)),
  last_error_code TEXT,
  created_at INTEGER NOT NULL CHECK (typeof(created_at) = 'integer' AND created_at >= 0),
  UNIQUE (storage_namespace, relative_path)
)
''',
    r'''
CREATE UNIQUE INDEX one_unfinished_session ON practice_sessions ((1))
WHERE state <> 'saved'
''',
    r'''
CREATE INDEX sessions_profile_state_date ON practice_sessions
(profile_id, state, practice_date DESC, created_at DESC, id DESC)
''',
    r'''
CREATE INDEX recordings_session ON recordings (session_id, created_at, id)
''',
    r'''
CREATE INDEX cleanup_retry ON file_cleanup_queue (next_attempt_at, id)
''',
    r'''
CREATE VIEW saved_practice_sessions AS
SELECT * FROM practice_sessions WHERE state = 'saved'
''',
    r'''
CREATE TRIGGER profile_identity_immutable
BEFORE UPDATE OF id, instrument_type, custom_type ON instrument_profiles
WHEN NEW.id <> OLD.id OR NEW.instrument_type <> OLD.instrument_type OR NEW.custom_type <> OLD.custom_type
BEGIN SELECT RAISE(ABORT, 'profile_identity_immutable'); END
''',
    r'''
CREATE TRIGGER profile_with_draft_cannot_delete
BEFORE DELETE ON instrument_profiles
WHEN EXISTS (SELECT 1 FROM practice_sessions WHERE profile_id = OLD.id AND state <> 'saved')
BEGIN SELECT RAISE(ABORT, 'profile_has_unfinished_session'); END
''',
    r'''
CREATE TRIGGER session_identity_immutable
BEFORE UPDATE OF id, profile_id, start_offset_minutes ON practice_sessions
WHEN NEW.id <> OLD.id OR NEW.profile_id <> OLD.profile_id OR NEW.start_offset_minutes <> OLD.start_offset_minutes
BEGIN SELECT RAISE(ABORT, 'session_identity_immutable'); END
''',
    r'''
CREATE TRIGGER session_state_transition
BEFORE UPDATE OF state ON practice_sessions
WHEN NOT (
  NEW.state = OLD.state
  OR (OLD.state = 'running' AND NEW.state IN ('paused', 'review'))
  OR (OLD.state = 'paused' AND NEW.state IN ('running', 'review'))
  OR (OLD.state = 'review' AND NEW.state IN ('paused', 'saved'))
)
BEGIN SELECT RAISE(ABORT, 'invalid_session_state_transition'); END
''',
    r'''
CREATE TRIGGER saved_measurement_immutable
BEFORE UPDATE OF measured_duration_seconds ON practice_sessions
WHEN OLD.state = 'saved' AND NEW.measured_duration_seconds IS NOT OLD.measured_duration_seconds
BEGIN SELECT RAISE(ABORT, 'saved_measurement_immutable'); END
''',
    r'''
CREATE TRIGGER create_session_draft AFTER INSERT ON practice_sessions
WHEN NEW.state <> 'saved'
BEGIN
  INSERT INTO session_drafts (session_id, accumulated_ms, checkpoint_at, updated_at)
  VALUES (NEW.id, 0, NEW.created_at, NEW.updated_at);
END
''',
    r'''
CREATE TRIGGER draft_requires_unfinished_session BEFORE INSERT ON session_drafts
WHEN NOT EXISTS (SELECT 1 FROM practice_sessions WHERE id = NEW.session_id AND state <> 'saved')
BEGIN SELECT RAISE(ABORT, 'draft_requires_unfinished_session'); END
''',
    r'''
CREATE TRIGGER draft_checkpoint_guard BEFORE UPDATE ON session_drafts
WHEN NEW.session_id <> OLD.session_id OR NEW.accumulated_ms < OLD.accumulated_ms
  OR NOT EXISTS (SELECT 1 FROM practice_sessions WHERE id = NEW.session_id AND state <> 'saved')
BEGIN SELECT RAISE(ABORT, 'invalid_draft_checkpoint'); END
''',
    r'''
CREATE TRIGGER save_requires_checkpoint BEFORE UPDATE OF state ON practice_sessions
WHEN OLD.state <> 'saved' AND NEW.state = 'saved' AND (
  NOT EXISTS (
    SELECT 1 FROM session_drafts WHERE session_id = OLD.id
    AND CAST(accumulated_ms / 1000 AS INTEGER) = NEW.measured_duration_seconds
  ) OR EXISTS (SELECT 1 FROM recordings WHERE session_id = OLD.id AND status = 'pending')
)
BEGIN SELECT RAISE(ABORT, 'save_requires_checkpoint'); END
''',
    r'''
CREATE TRIGGER remove_saved_draft AFTER UPDATE OF state ON practice_sessions
WHEN OLD.state <> 'saved' AND NEW.state = 'saved'
BEGIN DELETE FROM session_drafts WHERE session_id = NEW.id; END
''',
    r'''
CREATE TRIGGER recording_requires_unfinished_session BEFORE INSERT ON recordings
WHEN NOT EXISTS (
  SELECT 1 FROM practice_sessions WHERE id = NEW.session_id AND state <> 'saved'
    AND (NEW.status <> 'pending' OR state IN ('running', 'paused'))
)
BEGIN SELECT RAISE(ABORT, 'recording_requires_unfinished_session'); END
''',
    r'''
CREATE TRIGGER recording_identity_immutable BEFORE UPDATE OF id, session_id ON recordings
WHEN NEW.id <> OLD.id OR NEW.session_id <> OLD.session_id
BEGIN SELECT RAISE(ABORT, 'recording_identity_immutable'); END
''',
    r'''
CREATE TRIGGER saved_session_no_capture BEFORE UPDATE ON recordings
WHEN NEW.status = 'pending' AND EXISTS (
  SELECT 1 FROM practice_sessions WHERE id = NEW.session_id AND state = 'saved'
)
BEGIN SELECT RAISE(ABORT, 'saved_session_no_capture'); END
''',
    r'''
CREATE TRIGGER queue_recording_cleanup BEFORE DELETE ON recordings
BEGIN
  INSERT OR IGNORE INTO file_cleanup_queue (storage_namespace, relative_path, reason, created_at)
    SELECT 'audio', OLD.local_relative_path, 'recording_deleted',
      CAST(strftime('%s', 'now') AS INTEGER) * 1000 WHERE OLD.local_relative_path IS NOT NULL;
  INSERT OR IGNORE INTO file_cleanup_queue (storage_namespace, relative_path, reason, created_at)
    SELECT 'audio_temp', OLD.temp_relative_path, 'recording_deleted',
      CAST(strftime('%s', 'now') AS INTEGER) * 1000 WHERE OLD.temp_relative_path IS NOT NULL;
END
''',
    r'''
CREATE TRIGGER queue_finalized_temp AFTER UPDATE OF temp_relative_path ON recordings
WHEN OLD.temp_relative_path IS NOT NULL AND NEW.temp_relative_path IS NULL
BEGIN
  INSERT OR IGNORE INTO file_cleanup_queue (storage_namespace, relative_path, reason, created_at)
    VALUES ('audio_temp', OLD.temp_relative_path, 'capture_finalized',
      CAST(strftime('%s', 'now') AS INTEGER) * 1000);
END
''',
  ],
);
