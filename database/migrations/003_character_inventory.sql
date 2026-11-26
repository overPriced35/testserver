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
