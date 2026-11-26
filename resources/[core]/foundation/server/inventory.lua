FoundationInventory = {}
local definitions = {}
local locks = {}

local function validItemName(name)
    return type(name) == 'string' and #name >= 2 and #name <= 48 and name:match('^[a-z0-9_%-]+$') ~= nil
end

local function validCount(count)
    count = tonumber(count)
    return count and count > 0 and count % 1 == 0 and count <= 100000 and count or nil
end

local function getCharacter(source)
    local player = FoundationPlayers.Get(source)
    if not player or not player.character then return nil, 'No active character.' end
    return player.character
end

local function acquire(source)
    while locks[source] do Wait(0) end
    locks[source] = true
end

local function release(source)
    locks[source] = nil
end

local function withLock(source, callback)
    acquire(source)
    local ok, result, detail = pcall(callback)
    release(source)
    if not ok then
        print(('[foundation] Inventory operation failed for %s: %s'):format(source, result))
        return false, 'Inventory operation failed.'
    end
    return result, detail
end

local function normalizeRows(rows)
    local normalized, used = {}, {}
    for _, row in ipairs(rows or {}) do
        local slot, count = tonumber(row.slot), tonumber(row.count)
        local definition = definitions[row.item]
        if slot and slot >= 1 and slot <= Config.InventorySlots and slot % 1 == 0
            and count and count > 0 and count % 1 == 0 and definition and not used[slot] then
            local metadata = row.metadata
            if type(metadata) == 'string' then
                local ok, decoded = pcall(json.decode, metadata)
                metadata = ok and type(decoded) == 'table' and decoded or {}
            end
            normalized[#normalized + 1] = {
                slot = slot, name = row.item, count = count,
                metadata = type(metadata) == 'table' and metadata or {}
            }
            used[slot] = true
        end
    end
    return normalized, used
end

local function getWeight(items)
    local weight = 0
    for _, item in ipairs(items) do
        local definition = definitions[item.name]
        weight = weight + (definition.weight * item.count)
    end
    return weight
end

function FoundationInventory.RegisterItem(name, definition)
    name = type(name) == 'string' and name:lower() or nil
    if not validItemName(name) or type(definition) ~= 'table' then return false end
    local weight = tonumber(definition.weight)
    local maxStack = tonumber(definition.maxStack) or 100
    if not weight or weight < 0 or weight > 100000 or maxStack < 1 or maxStack > 100000 or maxStack % 1 ~= 0 then
        return false
    end
    definitions[name] = {
        name = name,
        label = type(definition.label) == 'string' and definition.label:sub(1, 64) or name,
        weight = weight,
        maxStack = maxStack,
        stack = definition.stack ~= false,
        description = type(definition.description) == 'string' and definition.description:sub(1, 180) or ''
    }
    return true
end

function FoundationInventory.GetItemDefinition(name)
    return definitions[name]
end

function FoundationInventory.GetInventory(source)
    local character, err = getCharacter(source)
    if not character then return nil, err end
    local rows = FoundationDB.FetchInventory(character.id)
    local items, used = normalizeRows(rows)
    return { items = items, weight = getWeight(items), maxWeight = Config.InventoryMaxWeight, slots = Config.InventorySlots }
end

function FoundationInventory.AddItem(source, name, count, metadata)
    name = type(name) == 'string' and name:lower() or nil
    count = validCount(count)
    local definition = definitions[name]
    if not definition or not count then return false, 'Invalid item or quantity.' end
    if metadata ~= nil and type(metadata) ~= 'table' then return false, 'Item metadata must be a table.' end
    local encoded = json.encode(metadata or {})
    if not encoded or #encoded > Config.MaxItemMetadataBytes then return false, 'Item metadata is too large.' end

    return withLock(source, function()
        local character, err = getCharacter(source)
        if not character then return false, err end
        local items, used = normalizeRows(FoundationDB.FetchInventory(character.id))
        local remaining = count
        if definition.stack then
            for _, item in ipairs(items) do
                if item.name == name and json.encode(item.metadata) == encoded and item.count < definition.maxStack then
                    local moved = math.min(remaining, definition.maxStack - item.count)
                    item.count = item.count + moved
                    remaining = remaining - moved
                    if remaining == 0 then break end
                end
            end
        end
        while remaining > 0 do
            local slot
            for candidate = 1, Config.InventorySlots do
                if not used[candidate] then slot = candidate; break end
            end
            if not slot then return false, 'Not enough inventory space.' end
            local moved = definition.stack and math.min(remaining, definition.maxStack) or 1
            items[#items + 1] = { slot = slot, name = name, count = moved, metadata = metadata or {} }
            used[slot] = true
            remaining = remaining - moved
        end
        if getWeight(items) > Config.InventoryMaxWeight then return false, 'Inventory weight limit exceeded.' end
        local saved = FoundationDB.ReplaceInventory(character.id, items)
        if not saved then return false, 'Inventory could not be saved.' end
        return true
    end)
end

function FoundationInventory.RemoveItem(source, name, count, metadata)
    name = type(name) == 'string' and name:lower() or nil
    count = validCount(count)
    if not definitions[name] or not count then return false, 'Invalid item or quantity.' end
    return withLock(source, function()
        local character, err = getCharacter(source)
        if not character then return false, err end
        local items = normalizeRows(FoundationDB.FetchInventory(character.id))
        local remaining = count
        for index = #items, 1, -1 do
            local item = items[index]
            local matchesMetadata = metadata == nil or json.encode(item.metadata) == json.encode(metadata)
            if item.name == name and matchesMetadata then
                local moved = math.min(remaining, item.count)
                item.count = item.count - moved
                remaining = remaining - moved
                if item.count == 0 then table.remove(items, index) end
                if remaining == 0 then break end
            end
        end
        if remaining > 0 then return false, 'Not enough items.' end
        local saved = FoundationDB.ReplaceInventory(character.id, items)
        if not saved then return false, 'Inventory could not be saved.' end
        return true
    end)
end

function FoundationInventory.HasItem(source, name, count)
    local inventory, err = FoundationInventory.GetInventory(source)
    if not inventory then return false, err end
    local total = 0
    for _, item in ipairs(inventory.items) do
        if item.name == name then total = total + item.count end
    end
    return total >= (validCount(count) or 1)
end

exports('RegisterItem', FoundationInventory.RegisterItem)
exports('GetItemDefinition', FoundationInventory.GetItemDefinition)
exports('GetInventory', FoundationInventory.GetInventory)
exports('AddItem', FoundationInventory.AddItem)
exports('RemoveItem', FoundationInventory.RemoveItem)
exports('HasItem', FoundationInventory.HasItem)

AddEventHandler('playerDropped', function()
    locks[source] = nil
end)

FoundationInventory.RegisterItem('water', { label = 'Water', weight = 500, maxStack = 10, description = 'A bottle of drinking water.' })
FoundationInventory.RegisterItem('sandwich', { label = 'Sandwich', weight = 350, maxStack = 10, description = 'A simple prepared meal.' })
FoundationInventory.RegisterItem('phone', { label = 'Mobile Phone', weight = 250, maxStack = 1, stack = false, description = 'A personal mobile phone.' })
