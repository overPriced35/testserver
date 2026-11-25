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
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_characters_owner (owner_identifier),
    CONSTRAINT fk_characters_owner
        FOREIGN KEY (owner_identifier) REFERENCES players(identifier)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
