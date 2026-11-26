local uiOpen = false
local activeCharacter = nil
local appearanceEditorOpen = false
local appearanceOverrides = {}
local previewCamera = nil

local DEFAULT_MODELS = { male = 'mp_m_freemode_01', female = 'mp_f_freemode_01', other = 'mp_m_freemode_01' }

local function setUi(state)
    uiOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and 'open' or 'close' })
end

local function captureAppearance()
    local ped = PlayerPedId()
    local appearance = {
        model = GetEntityModel(ped) == joaat('mp_f_freemode_01') and 'mp_f_freemode_01' or 'mp_m_freemode_01',
        components = {}, props = {}, faceFeatures = {},
        hair = { color = GetPedHairColor(ped), highlight = GetPedHairHighlightColor(ped) },
        eyeColor = GetPedEyeColor(ped),
        headBlend = appearanceOverrides.headBlend or {
            shapeFirst = 0, shapeSecond = 0, shapeThird = 0, skinFirst = 0, skinSecond = 0, skinThird = 0,
            shapeMix = 0.5, skinMix = 0.5, thirdMix = 0.0
        }
    }
    for component = 0, 11 do
        appearance.components[#appearance.components + 1] = {
            component = component, drawable = GetPedDrawableVariation(ped, component),
            texture = GetPedTextureVariation(ped, component), palette = GetPedPaletteVariation(ped, component)
        }
    end
    for prop = 0, 7 do
        appearance.props[#appearance.props + 1] = {
            prop = prop, drawable = GetPedPropIndex(ped, prop), texture = GetPedPropTextureIndex(ped, prop)
        }
    end
    for feature = 0, 19 do
        appearance.faceFeatures[#appearance.faceFeatures + 1] = { feature = feature, value = GetPedFaceFeature(ped, feature) }
    end
    return appearance
end

local function applyHeadBlend(ped, blend)
    if type(blend) ~= 'table' then return end
    SetPedHeadBlendData(ped,
        tonumber(blend.shapeFirst) or 0, tonumber(blend.shapeSecond) or 0, tonumber(blend.shapeThird) or 0,
        tonumber(blend.skinFirst) or 0, tonumber(blend.skinSecond) or 0, tonumber(blend.skinThird) or 0,
        tonumber(blend.shapeMix) or 0.5, tonumber(blend.skinMix) or 0.5, tonumber(blend.thirdMix) or 0.0, false)
    appearanceOverrides.headBlend = blend
end

local function applyAppearance(appearance, gender)
    local modelName = DEFAULT_MODELS[gender] or DEFAULT_MODELS.male
    if type(appearance) == 'table' and (appearance.model == 'mp_m_freemode_01' or appearance.model == 'mp_f_freemode_01') then
        modelName = appearance.model
    end
    local model = joaat(modelName)
    RequestModel(model)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(0) end
    if not HasModelLoaded(model) then print('[foundation] Could not load freemode ped model.'); return false end

    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    appearanceOverrides = {}

    if type(appearance) == 'table' then
        applyHeadBlend(ped, appearance.headBlend)
        for _, item in ipairs(appearance.components or {}) do
            if type(item) == 'table' and type(item.component) == 'number' and item.component >= 0 and item.component <= 11 then
                SetPedComponentVariation(ped, item.component, math.max(0, tonumber(item.drawable) or 0),
                    math.max(0, tonumber(item.texture) or 0), math.max(0, tonumber(item.palette) or 0))
            end
        end
        for _, item in ipairs(appearance.props or {}) do
            if type(item) == 'table' and type(item.prop) == 'number' and item.prop >= 0 and item.prop <= 7 then
                local drawable = tonumber(item.drawable) or -1
                if drawable < 0 then ClearPedProp(ped, item.prop)
                else SetPedPropIndex(ped, item.prop, drawable, math.max(0, tonumber(item.texture) or 0), true) end
            end
        end
        for _, item in ipairs(appearance.faceFeatures or {}) do
            if type(item) == 'table' and type(item.feature) == 'number' and item.feature >= 0 and item.feature <= 19 then
                SetPedFaceFeature(ped, item.feature, math.max(-1.0, math.min(1.0, tonumber(item.value) or 0.0)))
            end
        end
        if type(appearance.hair) == 'table' then
            SetPedHairColor(ped, tonumber(appearance.hair.color) or 0, tonumber(appearance.hair.highlight) or 0)
        end
        if appearance.eyeColor ~= nil then SetPedEyeColor(ped, tonumber(appearance.eyeColor) or 0) end
    end
    return true
end

local function currentPosition()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return { x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(ped) }
end

local function startPreviewCamera()
    if previewCamera and DoesCamExist(previewCamera) then return end
    local ped = PlayerPedId()
    local cameraPosition = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.1, 0.65)
    local head = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
    previewCamera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(previewCamera, cameraPosition.x, cameraPosition.y, cameraPosition.z)
    PointCamAtCoord(previewCamera, head.x, head.y, head.z)
    SetCamFov(previewCamera, 38.0)
    SetCamActive(previewCamera, true)
    RenderScriptCams(true, true, 450, true, true)
end

local function stopPreviewCamera()
    if not previewCamera then return end
    RenderScriptCams(false, true, 350, true, true)
    if DoesCamExist(previewCamera) then DestroyCam(previewCamera, false) end
    previewCamera = nil
end

local function savePosition()
    if activeCharacter then TriggerServerEvent('foundation:server:characters:savePosition', currentPosition()) end
end

local function saveAppearance()
    if activeCharacter then TriggerServerEvent('foundation:server:characters:saveAppearance', captureAppearance()) end
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
    if not success then SendNUIMessage({ action = 'error', message = result or 'Unable to select character.' }); return end
    activeCharacter = result
    setUi(false)
    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end
    applyAppearance(result.appearance, result.gender)

    local spawn = Config.Spawn
    if result.last_x ~= nil and result.last_y ~= nil and result.last_z ~= nil then
        spawn = { x = tonumber(result.last_x), y = tonumber(result.last_y), z = tonumber(result.last_z),
            heading = tonumber(result.last_heading) or Config.Spawn.heading }
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
    startPreviewCamera()
    setUi(true)
    SendNUIMessage({ action = 'appearanceEditor', appearance = captureAppearance() })
end, false)

RegisterNUICallback('previewComponent', function(data, cb)
    local component, drawable = tonumber(data.component), tonumber(data.drawable)
    local texture, ped = tonumber(data.texture) or 0, PlayerPedId()
    if not component or component < 0 or component > 11 or component % 1 ~= 0 or not drawable or drawable < 0 or drawable % 1 ~= 0 then
        cb({ ok = false, error = 'Invalid clothing selection.' }); return
    end
    local count = GetNumberOfPedDrawableVariations(ped, component)
    if drawable >= count then cb({ ok = false, error = 'Drawable is outside the available range.' }); return end
    local textures = GetNumberOfPedTextureVariations(ped, component, drawable)
    if texture < 0 or texture >= textures then cb({ ok = false, error = 'Texture is outside the available range.' }); return end
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
    if drawable >= count then cb({ ok = false, error = 'Accessory is outside the available range.' }); return end
    local textures = GetNumberOfPedPropTextureVariations(ped, prop, drawable)
    if texture < 0 or texture >= textures then cb({ ok = false, error = 'Accessory texture is outside the available range.' }); return end
    SetPedPropIndex(ped, prop, drawable, texture, true)
    cb({ ok = true })
end)

RegisterNUICallback('previewFaceFeature', function(data, cb)
    local feature, value = tonumber(data.feature), tonumber(data.value)
    if not feature or feature < 0 or feature > 19 or feature % 1 ~= 0 or not value or value < -1 or value > 1 then
        cb({ ok = false, error = 'Invalid facial feature value.' }); return
    end
    SetPedFaceFeature(PlayerPedId(), feature, value)
    cb({ ok = true })
end)

RegisterNUICallback('previewHair', function(data, cb)
    local color, highlight = tonumber(data.color), tonumber(data.highlight)
    if not color or not highlight or color < 0 or color > 63 or highlight < 0 or highlight > 63 then
        cb({ ok = false, error = 'Hair colors must be between 0 and 63.' }); return
    end
    SetPedHairColor(PlayerPedId(), color, highlight)
    cb({ ok = true })
end)

RegisterNUICallback('previewEyeColor', function(data, cb)
    local color = tonumber(data.color)
    if not color or color < 0 or color > 31 then cb({ ok = false, error = 'Eye color must be between 0 and 31.' }); return end
    SetPedEyeColor(PlayerPedId(), color)
    cb({ ok = true })
end)

RegisterNUICallback('previewHeadBlend', function(data, cb)
    local blend = {
        shapeFirst = tonumber(data.shapeFirst), shapeSecond = tonumber(data.shapeSecond), shapeThird = 0,
        skinFirst = tonumber(data.skinFirst), skinSecond = tonumber(data.skinSecond), skinThird = 0,
        shapeMix = tonumber(data.shapeMix), skinMix = tonumber(data.skinMix), thirdMix = 0.0
    }
    for _, key in ipairs({ 'shapeFirst', 'shapeSecond', 'skinFirst', 'skinSecond' }) do
        if not blend[key] or blend[key] < 0 or blend[key] > 45 or blend[key] % 1 ~= 0 then
            cb({ ok = false, error = 'Heritage IDs must be between 0 and 45.' }); return
        end
    end
    if not blend.shapeMix or blend.shapeMix < 0 or blend.shapeMix > 1 or not blend.skinMix or blend.skinMix < 0 or blend.skinMix > 1 then
        cb({ ok = false, error = 'Heritage blend values must be between 0 and 1.' }); return
    end
    appearanceOverrides.headBlend = blend
    applyHeadBlend(PlayerPedId(), blend)
    cb({ ok = true })
end)

RegisterNUICallback('saveAppearance', function(_, cb)
    saveAppearance()
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    if appearanceEditorOpen then appearanceEditorOpen = false; stopPreviewCamera(); setUi(false); cb({ ok = true })
    else cb({ ok = false }) end
end)

CreateThread(function()
    while true do
        if uiOpen then
            DisableControlAction(0, 1, true); DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true); DisableControlAction(0, 25, true)
            DisableControlAction(0, 200, true); Wait(0)
        else Wait(500) end
    end
end)

CreateThread(function()
    while true do Wait(Config.PositionSaveInterval); savePosition() end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then savePosition(); stopPreviewCamera() end
end)

exports('GetActiveCharacter', function() return activeCharacter end)
exports('CaptureAppearance', captureAppearance)
