local uiOpen = false
local spawnPending = false

local function setUi(state)
    uiOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and 'open' or 'close' })
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

    setUi(false)
    spawnPending = true
    local spawn = Config.Spawn
    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end

    if IsScreenFadedOut() then
        NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.heading, true, false)
        SetEntityCoordsNoOffset(PlayerPedId(), spawn.x, spawn.y, spawn.z, false, false, false)
        SetEntityHeading(PlayerPedId(), spawn.heading)
        ClearPedTasksImmediately(PlayerPedId())
        RemoveAllPedWeapons(PlayerPedId(), true)
        TriggerEvent('playerSpawned', spawn)
        DoScreenFadeIn(800)
    end

    spawnPending = false
    TriggerEvent('foundation:client:characterReady', result)
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
