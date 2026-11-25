local uiOpen = false
local activeCharacter = nil

local function setUi(state)
    uiOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and 'open' or 'close' })
end

local function getCurrentPosition()
    local coords = GetEntityCoords(PlayerPedId())
    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = GetEntityHeading(PlayerPedId())
    }
end

local function savePosition()
    if not activeCharacter then return end
    TriggerServerEvent('foundation:server:characters:savePosition', getCurrentPosition())
end

RegisterNetEvent('foundation:client:characters:open', function()
    setUi(true)
    TriggerServerEvent('foundation:server:characters:request')
end)

RegisterNetEvent('foundation:client:characters:list', function(characters, err)
    SendNUIMessage({
        action = 'characters',
        characters = characters or {},
        error = err
    })
end)

RegisterNetEvent('foundation:client:characters:created', function(success, result)
    SendNUIMessage({
        action = 'createResult',
        success = success,
        result = result
    })
    if success then
        TriggerServerEvent('foundation:server:characters:request')
    end
end)

RegisterNetEvent('foundation:client:characters:selected', function(success, result)
    if not success then
        SendNUIMessage({ action = 'error', message = result or 'Unable to select character.' })
        return
    end

    activeCharacter = result
    setUi(false)

    local spawn = Config.Spawn
    if result.last_x ~= nil and result.last_y ~= nil and result.last_z ~= nil then
        spawn = {
            x = tonumber(result.last_x),
            y = tonumber(result.last_y),
            z = tonumber(result.last_z),
            heading = tonumber(result.last_heading) or Config.Spawn.heading
        }
    end

    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end

    NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.heading, true, false)
    SetEntityCoordsNoOffset(PlayerPedId(), spawn.x, spawn.y, spawn.z, false, false, false)
    SetEntityHeading(PlayerPedId(), spawn.heading)
    ClearPedTasksImmediately(PlayerPedId())
    TriggerEvent('playerSpawned', spawn)
    DoScreenFadeIn(800)

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

RegisterNUICallback('close', function(_, cb)
    cb({ ok = false })
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
    if resourceName == GetCurrentResourceName() then
        savePosition()
    end
end)

RegisterNetEvent('foundation:client:saveAppearance', function(appearance)
    TriggerServerEvent('foundation:server:characters:saveAppearance', appearance)
end)

exports('GetActiveCharacter', function()
    return activeCharacter
end)
