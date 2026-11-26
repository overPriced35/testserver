FoundationMetadata = {}

local function validKey(key)
    return type(key) == 'string' and #key >= 1 and #key <= 48 and key:match('^[%w_%-%.]+$') ~= nil
end

function FoundationMetadata.Get(source, key)
    local player = FoundationPlayers.Get(source)
    if not player then return nil end
    if key == nil then
        local ok, copy = pcall(json.decode, json.encode(player.metadata))
        return ok and copy or {}
    end
    return player.metadata[key]
end

function FoundationMetadata.Set(source, key, value)
    local player = FoundationPlayers.Get(source)
    if not player or not validKey(key) then return false end
    local previous = player.metadata[key]
    player.metadata[key] = value
    local encodedOk, encoded = pcall(json.encode, player.metadata)
    if not encodedOk or type(encoded) ~= 'string' or #encoded > Config.MaxPlayerMetadataBytes then
        player.metadata[key] = previous
        return false
    end
    local saved, ok = pcall(FoundationDB.SavePlayerMetadata, player.identifier, player.metadata)
    if not saved then
        player.metadata[key] = previous
        return false
    end
    TriggerEvent('foundation:server:metadataChanged', source, key, value, previous)
    return true
end

function FoundationMetadata.Remove(source, key)
    local player = FoundationPlayers.Get(source)
    if not player or not validKey(key) or player.metadata[key] == nil then return false end
    local previous = player.metadata[key]
    player.metadata[key] = nil
    local saved, ok = pcall(FoundationDB.SavePlayerMetadata, player.identifier, player.metadata)
    if not saved or not ok then player.metadata[key] = previous; return false end
    TriggerEvent('foundation:server:metadataChanged', source, key, nil, previous)
    return true
end

exports('GetMetadata', FoundationMetadata.Get)
exports('SetMetadata', FoundationMetadata.Set)
exports('RemoveMetadata', FoundationMetadata.Remove)
