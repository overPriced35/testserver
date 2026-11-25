FoundationPlayers = {}
local players = {}

local function getIdentifier(src)
    local prefix = Config.IdentifierType .. ':'
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, #prefix) == prefix then
            return identifier
        end
    end
end

function FoundationPlayers.Get(source)
    return players[tonumber(source)]
end

function FoundationPlayers.GetAll()
    local result = {}
    for source, player in pairs(players) do
        result[#result + 1] = {
            source = source,
            identifier = player.identifier,
            name = player.name
        }
    end
    return result
end

function FoundationPlayers.Load(source)
    source = tonumber(source)
    local identifier = getIdentifier(source)
    if not identifier then
        DropPlayer(source, 'A valid player identifier could not be found.')
        return
    end

    local name = GetPlayerName(source) or ('Player %s'):format(source)
    local record = FoundationDB.FetchPlayer(identifier)

    if not record then
        FoundationDB.CreatePlayer(identifier, name)
        record = FoundationDB.FetchPlayer(identifier)
    else
        FoundationDB.UpdateLastSeen(identifier, name)
        record.name = name
    end

    players[source] = {
        source = source,
        identifier = identifier,
        name = name,
        metadata = json.decode(record.metadata or '{}') or {}
    }

    TriggerEvent('foundation:server:playerLoaded', source, players[source])
end

function FoundationPlayers.Unload(source)
    source = tonumber(source)
    local player = players[source]
    if not player then return end

    TriggerEvent('foundation:server:playerUnloading', source, player)
    players[source] = nil
end
