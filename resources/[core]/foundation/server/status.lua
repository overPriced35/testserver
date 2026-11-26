FoundationStatus = {}

local function clamp(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return nil end
    return math.max(0, math.min(100, math.floor(value + 0.5)))
end

local function getCharacter(source)
    local player = FoundationPlayers.Get(source)
    if not player or not player.character then return nil, 'No active character.' end
    return player.character
end

function FoundationStatus.Get(source)
    local character, err = getCharacter(source)
    if not character then return nil, err end
    FoundationDB.EnsureCharacterStatus(character.id)
    local status = FoundationDB.FetchCharacterStatus(character.id)
    if not status then return nil, 'Character status could not be loaded.' end
    return {
        hunger = clamp(status.hunger) or 100,
        thirst = clamp(status.thirst) or 100,
        stress = clamp(status.stress) or 0
    }
end

function FoundationStatus.Set(source, changes)
    local character, err = getCharacter(source)
    if not character then return false, err end
    if type(changes) ~= 'table' then return false, 'Invalid status update.' end
    local current, loadError = FoundationStatus.Get(source)
    if not current then return false, loadError end
    local updated = { hunger = current.hunger, thirst = current.thirst, stress = current.stress }
    for key, value in pairs(changes) do
        if updated[key] == nil then return false, 'Unknown status field.' end
        local normalized = clamp(value)
        if normalized == nil then return false, 'Status values must be numbers.' end
        updated[key] = normalized
    end
    local ok = FoundationDB.SaveCharacterStatus(character.id, updated)
    if not ok then return false, 'Status could not be saved.' end
    TriggerEvent('foundation:server:statusChanged', source, updated, current)
    TriggerClientEvent('foundation:client:statusUpdated', source, updated)
    return true, updated
end

function FoundationStatus.Modify(source, changes)
    if type(changes) ~= 'table' then return false, 'Invalid status update.' end
    local current, err = FoundationStatus.Get(source)
    if not current then return false, err end
    local updated = {}
    for key, delta in pairs(changes) do
        if current[key] == nil then return false, 'Unknown status field.' end
        delta = tonumber(delta)
        if not delta or delta ~= delta or delta == math.huge or delta == -math.huge then
            return false, 'Status changes must be numbers.'
        end
        updated[key] = clamp(current[key] + delta)
    end
    return FoundationStatus.Set(source, updated)
end

exports('GetStatus', FoundationStatus.Get)
exports('SetStatus', FoundationStatus.Set)
exports('ModifyStatus', FoundationStatus.Modify)

RegisterNetEvent('foundation:server:status:request', function()
    local source = source
    local status, err = FoundationStatus.Get(source)
    TriggerClientEvent('foundation:client:statusUpdated', source, status, err)
end)
