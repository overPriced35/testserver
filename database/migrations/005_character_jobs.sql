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
