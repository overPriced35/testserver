FoundationCharacters = {}

local lastStateSave = {}
local lastAppearanceSave = {}

local function trim(value)
    return (value:gsub('^%s*(.-)%s*$', '%1'))
end

local function validName(value)
    if type(value) ~= 'string' then return nil end
    value = trim(value)
    if #value < 2 or #value > 24 then return nil end
    if not value:match("^[%aÀ-ÿ'%- ]+$") then return nil end
    return value
end

local function validDate(value)
    if type(value) ~= 'string' or not value:match('^%d%d%d%d%-%d%d%-%d%d$') then return false end
    local year, month, day = value:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    if month < 1 or month > 12 or day < 1 or day > 31 then return false end
    local timestamp = os.time({ year = year, month = month, day = day, hour = 12 })
    if not timestamp then return false end
    local parsed = os.date('*t', timestamp)
    return parsed.year == year and parsed.month == month and parsed.day == day
end

local function getLoadedPlayer(source)
    local player = FoundationPlayers.Get(source)
    if not player then return nil, 'Player session is not loaded.' end
    return player
end

local function normalizePosition(position)
    if type(position) ~= 'table' then return nil end
    local normalized = {
        x = tonumber(position.x), y = tonumber(position.y),
        z = tonumber(position.z), heading = tonumber(position.heading)
    }
    for _, value in pairs(normalized) do
        if not value or value ~= value or value == math.huge or value == -math.huge then return nil end
    end
    if math.abs(normalized.x) > 10000 or math.abs(normalized.y) > 10000
        or normalized.z < -500 or normalized.z > 3000
        or normalized.heading < 0 or normalized.heading > 360 then return nil end
    return normalized
end

local function validAppearance(appearance)
    if type(appearance) ~= 'table' then return false end
    if appearance.model ~= 'mp_m_freemode_01' and appearance.model ~= 'mp_f_freemode_01' then return false end
    if type(appearance.components) ~= 'table' or #appearance.components > 12 then return false end
    if type(appearance.props) ~= 'table' or #appearance.props > 8 then return false end
    for _, item in ipairs(appearance.components) do
        if type(item) ~= 'table' or type(item.component) ~= 'number'
            or item.component < 0 or item.component > 11 or item.component % 1 ~= 0
            or type(item.drawable) ~= 'number' or item.drawable < 0 or item.drawable > 500
            or type(item.texture) ~= 'number' or item.texture < 0 or item.texture > 100
            or type(item.palette) ~= 'number' or item.palette < 0 or item.palette > 3 then return false end
    end
    for _, item in ipairs(appearance.props) do
        if type(item) ~= 'table' or type(item.prop) ~= 'number'
            or item.prop < 0 or item.prop > 7 or item.prop % 1 ~= 0
            or type(item.drawable) ~= 'number' or item.drawable < -1 or item.drawable > 500
            or type(item.texture) ~= 'number' or item.texture < 0 or item.texture > 100 then return false end
    end
    if appearance.faceFeatures ~= nil then
        if type(appearance.faceFeatures) ~= 'table' or #appearance.faceFeatures > 20 then return false end
        for _, item in ipairs(appearance.faceFeatures) do
            if type(item) ~= 'table' or type(item.feature) ~= 'number'
                or item.feature < 0 or item.feature > 19 or item.feature % 1 ~= 0
                or type(item.value) ~= 'number' or item.value < -1 or item.value > 1 then return false end
        end
    end
    if appearance.hair ~= nil then
        if type(appearance.hair) ~= 'table' or type(appearance.hair.color) ~= 'number'
            or type(appearance.hair.highlight) ~= 'number' or appearance.hair.color < 0
            or appearance.hair.color > 63 or appearance.hair.highlight < 0 or appearance.hair.highlight > 63 then return false end
    end
    if appearance.eyeColor ~= nil and (type(appearance.eyeColor) ~= 'number'
        or appearance.eyeColor < 0 or appearance.eyeColor > 31) then return false end
    if appearance.headBlend ~= nil then
        local blend = appearance.headBlend
        if type(blend) ~= 'table' then return false end
        for _, key in ipairs({ 'shapeFirst', 'shapeSecond', 'skinFirst', 'skinSecond' }) do
            if type(blend[key]) ~= 'number' or blend[key] < 0 or blend[key] > 45 or blend[key] % 1 ~= 0 then return false end
        end
        for _, key in ipairs({ 'shapeMix', 'skinMix' }) do
            if type(blend[key]) ~= 'number' or blend[key] < 0 or blend[key] > 1 then return false end
        end
    end
    return true
end

function FoundationCharacters.List(source)
    local player, err = getLoadedPlayer(source)
    if not player then return nil, err end
    return FoundationDB.ListCharacters(player.identifier)
end

function FoundationCharacters.Create(source, input)
    local player, err = getLoadedPlayer(source)
    if not player then return false, err end
    if type(input) ~= 'table' then return false, 'Invalid character data.' end

    local firstname, lastname = validName(input.firstname), validName(input.lastname)
    local dob, gender = input.date_of_birth, input.gender
    if not firstname or not lastname then return false, 'First and last names must be 2–24 valid characters.' end
    if not validDate(dob) then return false, 'Date of birth must be a valid date in YYYY-MM-DD format.' end
    if gender ~= 'male' and gender ~= 'female' and gender ~= 'other' then return false, 'Select a valid gender.' end
    if FoundationDB.CountCharacters(player.identifier) >= Config.MaxCharacters then
        return false, ('You have reached the character limit (%s).'):format(Config.MaxCharacters)
    end

    local id = FoundationDB.CreateCharacter(player.identifier, {
        firstname = firstname, lastname = lastname, date_of_birth = dob, gender = gender
    })
    if not id then return false, 'Character could not be created.' end
    return true, FoundationDB.ListCharacters(player.identifier)
end

function FoundationCharacters.Select(source, characterId)
    local player, err = getLoadedPlayer(source)
    if not player then return false, err end
    characterId = tonumber(characterId)
    if not characterId or characterId < 1 or characterId % 1 ~= 0 then return false, 'Invalid character selection.' end

    local character = FoundationDB.FetchCharacter(player.identifier, characterId)
    if not character then return false, 'That character does not belong to your account.' end
    character.appearance = character.appearance and json.decode(character.appearance) or nil
    player.character = character
    FoundationDB.TouchCharacter(player.identifier, characterId)
    TriggerEvent('foundation:server:characterSelected', source, character)
    TriggerClientEvent('foundation:client:characters:selected', source, true, character)
    return true, character
end

function FoundationCharacters.SavePosition(source, position)
    local player = FoundationPlayers.Get(source)
    if not player or not player.character then return false end
    local normalized = normalizePosition(position)
    if not normalized then return false end
    local now, previous = GetGameTimer(), lastStateSave[source]
    if previous and now - previous < Config.PositionSaveThrottle then return false end
    lastStateSave[source] = now
    return FoundationDB.SaveCharacterState(player.identifier, player.character.id, normalized)
end

function FoundationCharacters.SaveAppearance(source, appearance)
    local player = FoundationPlayers.Get(source)
    if not player or not player.character or not validAppearance(appearance) then return false end
    local now, previous = GetGameTimer(), lastAppearanceSave[source]
    if previous and now - previous < Config.AppearanceSaveThrottle then return false end
    local encoded = json.encode(appearance)
    if type(encoded) ~= 'string' or #encoded > Config.MaxAppearanceBytes then return false end
    lastAppearanceSave[source] = now
    return FoundationDB.SaveCharacterAppearance(player.identifier, player.character.id, appearance)
end

RegisterNetEvent('foundation:server:characters:request', function()
    local source = source
    local characters, err = FoundationCharacters.List(source)
    TriggerClientEvent('foundation:client:characters:list', source, characters or {}, err)
end)

RegisterNetEvent('foundation:server:characters:create', function(input)
    local source = source
    local ok, result = FoundationCharacters.Create(source, input)
    TriggerClientEvent('foundation:client:characters:created', source, ok, result)
end)

RegisterNetEvent('foundation:server:characters:select', function(characterId)
    local source = source
    local ok, result = FoundationCharacters.Select(source, characterId)
    if not ok then TriggerClientEvent('foundation:client:characters:selected', source, false, result) end
end)

RegisterNetEvent('foundation:server:characters:savePosition', function(position)
    FoundationCharacters.SavePosition(source, position)
end)

RegisterNetEvent('foundation:server:characters:saveAppearance', function(appearance)
    FoundationCharacters.SaveAppearance(source, appearance)
end)

AddEventHandler('playerDropped', function()
    lastStateSave[source] = nil
    lastAppearanceSave[source] = nil
end)

exports('GetCharacter', function(source)
    local player = FoundationPlayers.Get(source)
    return player and player.character or nil
end)

exports('SaveCharacterAppearance', FoundationCharacters.SaveAppearance)
