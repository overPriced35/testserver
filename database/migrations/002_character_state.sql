-- Character appearance and reconnect position support.
ALTER TABLE characters ADD COLUMN IF NOT EXISTS appearance LONGTEXT NULL;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS last_x DOUBLE NULL;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS last_y DOUBLE NULL;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS last_z DOUBLE NULL;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS last_heading FLOAT NULL;
