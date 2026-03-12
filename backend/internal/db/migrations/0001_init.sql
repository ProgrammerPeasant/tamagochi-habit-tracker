CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS habits (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  frequency TEXT NOT NULL CHECK (frequency IN ("daily", "weekly", "custom")),
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS habits_user_id_idx ON habits(user_id);
CREATE INDEX IF NOT EXISTS habits_updated_at_idx ON habits(updated_at);

CREATE TABLE IF NOT EXISTS habit_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  habit_id TEXT NOT NULL REFERENCES habits(id),
  date DATE NOT NULL,
  completed BOOLEAN NOT NULL,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS habit_logs_habit_id_idx ON habit_logs(habit_id);
CREATE INDEX IF NOT EXISTS habit_logs_user_date_idx ON habit_logs(user_id, date);

CREATE TABLE IF NOT EXISTS streaks (
  user_id TEXT NOT NULL REFERENCES users(id),
  habit_id TEXT NOT NULL REFERENCES habits(id),
  current_streak INT NOT NULL,
  best_streak INT NOT NULL,
  last_completed TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (user_id, habit_id)
);

CREATE TABLE IF NOT EXISTS pet_state (
  user_id TEXT PRIMARY KEY REFERENCES users(id),
  level INT NOT NULL,
  structure_complexity INT NOT NULL,
  damage INT NOT NULL,
  energy INT NOT NULL,
  mood INT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS user_stats (
  user_id TEXT PRIMARY KEY REFERENCES users(id),
  total_completed INT NOT NULL,
  completion_rate DOUBLE PRECISION NOT NULL,
  active_days INT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS sync_changes (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  device_id TEXT NOT NULL,
  entity TEXT NOT NULL,
  op TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  payload JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS sync_changes_user_device_idx ON sync_changes(user_id, device_id);
CREATE INDEX IF NOT EXISTS sync_changes_updated_at_idx ON sync_changes(updated_at);
