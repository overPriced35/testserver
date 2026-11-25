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
