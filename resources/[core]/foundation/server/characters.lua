FoundationCharacters = {}

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

function FoundationCharacters.List(source)
    local player, err = getLoadedPlayer(source)
    if not player then return nil, err end
    return FoundationDB.ListCharacters(player.identifier)
end

function FoundationCharacters.Create(source, input)
    local player, err = getLoadedPlayer(source)
    if not player then return false, err end
    if type(input) ~= 'table' then return false, 'Invalid character data.' end

    local firstname = validName(input.firstname)
    local lastname = validName(input.lastname)
    local dob = input.date_of_birth
    local gender = input.gender

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

    FoundationDB.TouchCharacter(player.identifier, characterId)
    player.character = character
    TriggerEvent('foundation:server:characterSelected', source, character)
    TriggerClientEvent('foundation:client:characters:selected', source, true, character)
    return true, character
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

exports('GetCharacter', function(source)
    local player = FoundationPlayers.Get(source)
    return player and player.character or nil
end)
