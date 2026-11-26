CREATE TABLE IF NOT EXISTS players (
    identifier VARCHAR(80) NOT NULL,
    name VARCHAR(64) NOT NULL,
    metadata LONGTEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS characters (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    owner_identifier VARCHAR(80) NOT NULL,
    firstname VARCHAR(24) NOT NULL,
    lastname VARCHAR(24) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('male', 'female', 'other') NOT NULL,
    appearance LONGTEXT NULL,
    last_x DOUBLE NULL,
    last_y DOUBLE NULL,
    last_z DOUBLE NULL,
    last_heading FLOAT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_characters_owner (owner_identifier),
    CONSTRAINT fk_characters_owner
        FOREIGN KEY (owner_identifier) REFERENCES players(identifier)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Safe upgrades for databases created with the earlier character schema.
ALTER TABLE characters ADD COLUMN IF NOT EXISTS appearance LONGTEXT NULL;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS last_x DOUBLE NULL;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS last_y DOUBLE NULL;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS last_z DOUBLE NULL;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS last_heading FLOAT NULL;

CREATE TABLE IF NOT EXISTS character_inventory (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    character_id INT UNSIGNED NOT NULL,
    slot SMALLINT UNSIGNED NOT NULL,
    item VARCHAR(48) NOT NULL,
    count INT UNSIGNED NOT NULL,
    metadata LONGTEXT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_character_inventory_slot (character_id, slot),
    KEY idx_character_inventory_item (character_id, item),
    CONSTRAINT fk_character_inventory_character
        FOREIGN KEY (character_id) REFERENCES characters(id)
        ON DELETE CASCADE,
    CHECK (count > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS character_status (
    character_id INT UNSIGNED NOT NULL,
    hunger TINYINT UNSIGNED NOT NULL DEFAULT 100,
    thirst TINYINT UNSIGNED NOT NULL DEFAULT 100,
    stress TINYINT UNSIGNED NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (character_id),
    CONSTRAINT fk_character_status_character
        FOREIGN KEY (character_id) REFERENCES characters(id)
        ON DELETE CASCADE,
    CHECK (hunger <= 100),
    CHECK (thirst <= 100),
    CHECK (stress <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS character_jobs (
    character_id INT UNSIGNED NOT NULL,
    job VARCHAR(48) NOT NULL DEFAULT 'unemployed',
    grade SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (character_id),
    INDEX idx_character_jobs_job (job),
    CONSTRAINT fk_character_jobs_character
        FOREIGN KEY (character_id) REFERENCES characters(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
