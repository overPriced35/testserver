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
