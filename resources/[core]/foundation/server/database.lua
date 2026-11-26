FoundationDB = FoundationDB or {}

function FoundationDB.FetchPlayer(identifier)
    return MySQL.single.await(
        ('SELECT identifier, name, metadata, created_at, last_seen FROM %s WHERE identifier = ?'):format(Config.PlayerTable),
        { identifier }
    )
end

function FoundationDB.CreatePlayer(identifier, name)
    MySQL.insert.await(
        ('INSERT INTO %s (identifier, name, metadata, created_at, last_seen) VALUES (?, ?, ?, NOW(), NOW())'):format(Config.PlayerTable),
        { identifier, name, '{}' }
    )
end

function FoundationDB.UpdateLastSeen(identifier, name)
    MySQL.update.await(
        ('UPDATE %s SET name = ?, last_seen = NOW() WHERE identifier = ?'):format(Config.PlayerTable),
        { name, identifier }
    )
end

function FoundationDB.SavePlayerMetadata(identifier, metadata)
    return MySQL.update.await(
        ('UPDATE %s SET metadata = ? WHERE identifier = ?'):format(Config.PlayerTable),
        { json.encode(metadata), identifier }
    )
end

function FoundationDB.ListCharacters(identifier)
    return MySQL.query.await(
        ('SELECT id, firstname, lastname, date_of_birth, gender, created_at, last_seen FROM %s WHERE owner_identifier = ? ORDER BY id ASC'):format(Config.CharacterTable),
        { identifier }
    ) or {}
end

function FoundationDB.CountCharacters(identifier)
    local result = MySQL.scalar.await(
        ('SELECT COUNT(*) FROM %s WHERE owner_identifier = ?'):format(Config.CharacterTable),
        { identifier }
    )
    return tonumber(result) or 0
end

function FoundationDB.CreateCharacter(identifier, data)
    return MySQL.insert.await(
        ('INSERT INTO %s (owner_identifier, firstname, lastname, date_of_birth, gender, created_at, last_seen) VALUES (?, ?, ?, ?, ?, NOW(), NOW())'):format(Config.CharacterTable),
        { identifier, data.firstname, data.lastname, data.date_of_birth, data.gender }
    )
end

function FoundationDB.FetchCharacter(identifier, characterId)
    return MySQL.single.await(
        ('SELECT id, owner_identifier, firstname, lastname, date_of_birth, gender, appearance, last_x, last_y, last_z, last_heading, created_at, last_seen FROM %s WHERE owner_identifier = ? AND id = ?'):format(Config.CharacterTable),
        { identifier, characterId }
    )
end

function FoundationDB.TouchCharacter(identifier, characterId)
    MySQL.update.await(
        ('UPDATE %s SET last_seen = NOW() WHERE owner_identifier = ? AND id = ?'):format(Config.CharacterTable),
        { identifier, characterId }
    )
end

function FoundationDB.SaveCharacterState(identifier, characterId, state)
    return MySQL.update.await(
        ('UPDATE %s SET last_x = ?, last_y = ?, last_z = ?, last_heading = ?, last_seen = NOW() WHERE owner_identifier = ? AND id = ?'):format(Config.CharacterTable),
        { state.x, state.y, state.z, state.heading, identifier, characterId }
    )
end

function FoundationDB.SaveCharacterAppearance(identifier, characterId, appearance)
    return MySQL.update.await(
        ('UPDATE %s SET appearance = ? WHERE owner_identifier = ? AND id = ?'):format(Config.CharacterTable),
        { json.encode(appearance), identifier, characterId }
    )
end

function FoundationDB.FetchInventory(characterId)
    return MySQL.query.await(
        'SELECT slot, item, count, metadata FROM character_inventory WHERE character_id = ? ORDER BY slot ASC',
        { characterId }
    ) or {}
end

function FoundationDB.ReplaceInventory(characterId, items)
    local queries = {
        { query = 'DELETE FROM character_inventory WHERE character_id = ?', values = { characterId } }
    }
    for _, item in ipairs(items) do
        queries[#queries + 1] = {
            query = 'INSERT INTO character_inventory (character_id, slot, item, count, metadata) VALUES (?, ?, ?, ?, ?)',
            values = { characterId, item.slot, item.name, item.count, json.encode(item.metadata or {}) }
        }
    end
    return MySQL.transaction.await(queries)
end

function FoundationDB.EnsureCharacterStatus(characterId)
    MySQL.insert.await(
        'INSERT IGNORE INTO character_status (character_id, hunger, thirst, stress) VALUES (?, 100, 100, 0)',
        { characterId }
    )
end

function FoundationDB.FetchCharacterStatus(characterId)
    return MySQL.single.await(
        'SELECT hunger, thirst, stress FROM character_status WHERE character_id = ?',
        { characterId }
    )
end

function FoundationDB.SaveCharacterStatus(characterId, status)
    return MySQL.update.await(
        'UPDATE character_status SET hunger = ?, thirst = ?, stress = ? WHERE character_id = ?',
        { status.hunger, status.thirst, status.stress, characterId }
    )
end


function FoundationDB.EnsureCharacterJob(characterId)
    MySQL.insert.await(
        "INSERT IGNORE INTO character_jobs (character_id, job, grade) VALUES (?, 'unemployed', 0)",
        { characterId }
    )
end

function FoundationDB.FetchCharacterJob(characterId)
    return MySQL.single.await(
        'SELECT job, grade FROM character_jobs WHERE character_id = ?',
        { characterId }
    )
end

function FoundationDB.SaveCharacterJob(characterId, job, grade)
    return MySQL.update.await(
        'INSERT INTO character_jobs (character_id, job, grade) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE job = VALUES(job), grade = VALUES(grade)',
        { characterId, job, grade }
    )
end
