local uiOpen = false
local activeCharacter = nil
local appearanceEditorOpen = false

local DEFAULT_MODELS = {
    male = 'mp_m_freemode_01',
    female = 'mp_f_freemode_01',
    other = 'mp_m_freemode_01'
}

local function setUi(state)
    uiOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and 'open' or 'close' })
end

local function currentPosition()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return { x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(ped) }
end

local function captureAppearance()
    local ped = PlayerPedId()
    local appearance = {
        model = GetEntityModel(ped) == joaat('mp_f_freemode_01') and 'mp_f_freemode_01' or 'mp_m_freemode_01',
        components = {},
        props = {}
    }
    for component = 0, 11 do
        appearance.components[#appearance.components + 1] = {
            component = component,
            drawable = GetPedDrawableVariation(ped, component),
            texture = GetPedTextureVariation(ped, component),
            palette = GetPedPaletteVariation(ped, component)
        }
    end
    for prop = 0, 7 do
        appearance.props[#appearance.props + 1] = {
            prop = prop,
            drawable = GetPedPropIndex(ped, prop),
            texture = GetPedPropTextureIndex(ped, prop)
        }
    end
    return appearance
end

local function applyAppearance(appearance, gender)
    local modelName = DEFAULT_MODELS[gender] or DEFAULT_MODELS.male
    if type(appearance) == 'table'
        and (appearance.model == 'mp_m_freemode_01' or appearance.model == 'mp_f_freemode_01') then
        modelName = appearance.model
    end

    local model = joaat(modelName)
    RequestModel(model)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(0) end
    if not HasModelLoaded(model) then
        print('[foundation] Could not load freemode ped model.')
        return false
    end

    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)

    if type(appearance) == 'table' and type(appearance.components) == 'table' then
        for _, item in ipairs(appearance.components) do
            if type(item) == 'table' and type(item.component) == 'number'
                and item.component >= 0 and item.component <= 11 then
                SetPedComponentVariation(
                    ped, item.component,
                    math.max(0, tonumber(item.drawable) or 0),
                    math.max(0, tonumber(item.texture) or 0),
                    math.max(0, tonumber(item.palette) or 0)
                )
            end
        end
    end

    if type(appearance) == 'table' and type(appearance.props) == 'table' then
        for _, item in ipairs(appearance.props) do
            if type(item) == 'table' and type(item.prop) == 'number' and item.prop >= 0 and item.prop <= 7 then
                local drawable = tonumber(item.drawable) or -1
                if drawable < 0 then
                    ClearPedProp(ped, item.prop)
                else
                    SetPedPropIndex(ped, item.prop, drawable, math.max(0, tonumber(item.texture) or 0), true)
                end
            end
        end
    end
    return true
end

local function savePosition()
    if activeCharacter then
        TriggerServerEvent('foundation:server:characters:savePosition', currentPosition())
    end
end

local function saveAppearance()
    if activeCharacter then
        TriggerServerEvent('foundation:server:characters:saveAppearance', captureAppearance())
    end
end

RegisterNetEvent('foundation:client:characters:open', function()
    setUi(true)
    TriggerServerEvent('foundation:server:characters:request')
end)

RegisterNetEvent('foundation:client:characters:list', function(characters, err)
    SendNUIMessage({ action = 'characters', characters = characters or {}, error = err })
end)

RegisterNetEvent('foundation:client:characters:created', function(success, result)
    SendNUIMessage({ action = 'createResult', success = success, result = result })
    if success then TriggerServerEvent('foundation:server:characters:request') end
end)

RegisterNetEvent('foundation:client:characters:selected', function(success, result)
    if not success then
        SendNUIMessage({ action = 'error', message = result or 'Unable to select character.' })
        return
    end

    activeCharacter = result
    setUi(false)
    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end

    applyAppearance(result.appearance, result.gender)

    local spawn = Config.Spawn
    if result.last_x ~= nil and result.last_y ~= nil and result.last_z ~= nil then
        spawn = {
            x = tonumber(result.last_x),
            y = tonumber(result.last_y),
            z = tonumber(result.last_z),
            heading = tonumber(result.last_heading) or Config.Spawn.heading
        }
    end

    NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.heading, true, false)
    SetEntityCoordsNoOffset(PlayerPedId(), spawn.x, spawn.y, spawn.z, false, false, false)
    SetEntityHeading(PlayerPedId(), spawn.heading)
    ClearPedTasksImmediately(PlayerPedId())
    TriggerEvent('playerSpawned', spawn)
    DoScreenFadeIn(800)

    Wait(1200)
    saveAppearance()
    TriggerEvent('foundation:client:characterReady', result, result.appearance)
end)

RegisterNUICallback('createCharacter', function(data, cb)
    TriggerServerEvent('foundation:server:characters:create', data)
    cb({ ok = true })
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    TriggerServerEvent('foundation:server:characters:select', data.id)
    cb({ ok = true })
end)



RegisterCommand('saveappearance', saveAppearance, false)
RegisterCommand('appearance', function()
    if not activeCharacter then return end
    appearanceEditorOpen = true
    setUi(true)
    SendNUIMessage({ action = 'appearanceEditor', appearance = captureAppearance() })
end, false)
RegisterNetEvent('foundation:client:saveAppearance', saveAppearance)

RegisterNUICallback('previewComponent', function(data, cb)
    local component, drawable = tonumber(data.component), tonumber(data.drawable)
    local texture, ped = tonumber(data.texture) or 0, PlayerPedId()
    if not component or component < 0 or component > 11 or component % 1 ~= 0 or not drawable or drawable < 0 or drawable % 1 ~= 0 then
        cb({ ok = false, error = 'Invalid clothing selection.' }); return
    end
    local count = GetNumberOfPedDrawableVariations(ped, component)
    if drawable >= count then cb({ ok = false, error = ('Drawable must be between 0 and %s.'):format(math.max(0, count - 1)) }); return end
    local textures = GetNumberOfPedTextureVariations(ped, component, drawable)
    if texture < 0 or texture >= textures then cb({ ok = false, error = ('Texture must be between 0 and %s.'):format(math.max(0, textures - 1)) }); return end
    SetPedComponentVariation(ped, component, drawable, texture, 0)
    cb({ ok = true })
end)

RegisterNUICallback('previewProp', function(data, cb)
    local prop, drawable = tonumber(data.prop), tonumber(data.drawable)
    local texture, ped = tonumber(data.texture) or 0, PlayerPedId()
    if not prop or prop < 0 or prop > 7 or prop % 1 ~= 0 or not drawable or drawable < -1 then
        cb({ ok = false, error = 'Invalid accessory selection.' }); return
    end
    if drawable == -1 then ClearPedProp(ped, prop); cb({ ok = true }); return end
    local count = GetNumberOfPedPropDrawableVariations(ped, prop)
    if drawable >= count then cb({ ok = false, error = ('Drawable must be between 0 and %s.'):format(math.max(0, count - 1)) }); return end
    local textures = GetNumberOfPedPropTextureVariations(ped, prop, drawable)
    if texture < 0 or texture >= textures then cb({ ok = false, error = ('Texture must be between 0 and %s.'):format(math.max(0, textures - 1)) }); return end
    SetPedPropIndex(ped, prop, drawable, texture, true)
    cb({ ok = true })
end)

RegisterNUICallback('saveAppearance', function(_, cb)
    saveAppearance()
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    if appearanceEditorOpen then
        appearanceEditorOpen = false
        setUi(false)
        cb({ ok = true })
    else
        cb({ ok = false })
    end
end)

CreateThread(function()
    while true do
        if uiOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 200, true)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.PositionSaveInterval)
        savePosition()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then savePosition() end
end)

exports('GetActiveCharacter', function() return activeCharacter end)
exports('CaptureAppearance', captureAppearance)
