FoundationDB = {}

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
