FoundationJobs = {}

local jobs = {}
local validName = '^[a-z][a-z0-9_%-]*$'

local function normalizeJob(name, definition)
    if type(name) ~= 'string' or #name < 2 or #name > 48 or not name:match(validName) then
        return nil, 'Job name must be 2–48 lowercase letters, numbers, underscores or hyphens.'
    end
    if type(definition) ~= 'table' or type(definition.label) ~= 'string'
        or #definition.label < 1 or #definition.label > 64
        or type(definition.grades) ~= 'table' then
        return nil, 'Job definition requires a label and grades table.'
    end

    local normalized = { label = definition.label, grades = {} }
    for key, grade in pairs(definition.grades) do
        local level = tonumber(key)
        if not level or level < 0 or level > 100 or level % 1 ~= 0
            or type(grade) ~= 'table' or type(grade.label) ~= 'string'
            or #grade.label < 1 or #grade.label > 64 then
            return nil, 'Each grade requires a valid numeric level and label.'
        end
        local permissions = {}
        if grade.permissions ~= nil then
            if type(grade.permissions) ~= 'table' then return nil, 'Grade permissions must be a list.' end
            for _, permission in ipairs(grade.permissions) do
                if type(permission) ~= 'string' or #permission < 1 or #permission > 64 then
                    return nil, 'Invalid job permission.'
                end
                permissions[#permissions + 1] = permission
            end
        end
        normalized.grades[level] = {
            label = grade.label,
            permissions = permissions,
            canToggleDuty = grade.canToggleDuty == true
        }
    end
    if not normalized.grades[0] then return nil, 'Every job must define grade 0.' end
    return normalized
end

function FoundationJobs.Register(name, definition)
    local normalized, err = normalizeJob(name, definition)
    if not normalized then return false, err end
    jobs[name] = normalized
    return true
end

function FoundationJobs.GetDefinition(name)
    return jobs[name]
end

local function getActive(source)
    local player = FoundationPlayers.Get(source)
    if not player or not player.character then return nil end
    return player
end

function FoundationJobs.Get(source)
    local player = getActive(source)
    if not player then return nil end
    local name = player.character.job or 'unemployed'
    local grade = tonumber(player.character.job_grade) or 0
    local definition = jobs[name]
    local gradeData = definition and definition.grades[grade]
    return {
        name = name,
        label = definition and definition.label or name,
        grade = grade,
        grade_label = gradeData and gradeData.label or 'Unknown',
        on_duty = player.duty == true
    }
end

function FoundationJobs.Set(source, name, grade)
    local player = getActive(source)
    if not player then return false, 'No active character.' end
    local definition = jobs[name]
    grade = tonumber(grade)
    if not definition or not grade or grade % 1 ~= 0 or not definition.grades[grade] then
        return false, 'Unknown job or grade.'
    end

    local ok, result = pcall(FoundationDB.SaveCharacterJob, player.character.id, name, grade)
    if not ok or result == false then return false, 'Job assignment could not be saved.' end

    player.character.job = name
    player.character.job_grade = grade
    player.duty = false
    local data = FoundationJobs.Get(source)
    TriggerEvent('foundation:server:jobChanged', source, data)
    TriggerClientEvent('foundation:client:jobUpdated', source, data)
    return true, data
end

function FoundationJobs.SetDuty(source, enabled)
    local player = getActive(source)
    if not player then return false, 'No active character.' end
    local definition = jobs[player.character.job or 'unemployed']
    local grade = definition and definition.grades[tonumber(player.character.job_grade) or 0]
    if not grade or grade.canToggleDuty ~= true then return false, 'Your job cannot toggle duty.' end
    player.duty = enabled == true
    local data = FoundationJobs.Get(source)
    TriggerEvent('foundation:server:dutyChanged', source, player.duty, data)
    TriggerClientEvent('foundation:client:jobUpdated', source, data)
    return true, data
end

function FoundationJobs.HasPermission(source, permission)
    if type(permission) ~= 'string' then return false end
    local player = getActive(source)
    if not player then return false end
    local definition = jobs[player.character.job or 'unemployed']
    local grade = definition and definition.grades[tonumber(player.character.job_grade) or 0]
    if not grade then return false end
    for _, value in ipairs(grade.permissions) do
        if value == permission or value == '*' then return true end
    end
    return false
end

RegisterNetEvent('foundation:server:jobs:request', function()
    local source = source
    TriggerClientEvent('foundation:client:jobUpdated', source, FoundationJobs.Get(source))
end)

AddEventHandler('playerDropped', function()
    local player = FoundationPlayers.Get(source)
    if player then player.duty = false end
end)

exports('RegisterJob', FoundationJobs.Register)
exports('GetJob', FoundationJobs.Get)
exports('SetJob', FoundationJobs.Set)
exports('SetDuty', FoundationJobs.SetDuty)
exports('HasJobPermission', FoundationJobs.HasPermission)
exports('GetJobDefinition', FoundationJobs.GetDefinition)

FoundationJobs.Register('unemployed', {
    label = 'Unemployed',
    grades = { [0] = { label = 'Unemployed' } }
})
FoundationJobs.Register('police', {
    label = 'Police',
    grades = {
        [0] = { label = 'Cadet', canToggleDuty = true, permissions = { 'police.radio' } },
        [1] = { label = 'Officer', canToggleDuty = true, permissions = { 'police.radio', 'police.armory' } },
        [2] = { label = 'Sergeant', canToggleDuty = true, permissions = { 'police.radio', 'police.armory', 'police.manage' } }
    }
})
FoundationJobs.Register('ambulance', {
    label = 'Emergency Medical Services',
    grades = {
        [0] = { label = 'EMT', canToggleDuty = true, permissions = { 'ems.radio', 'ems.treat' } },
        [1] = { label = 'Paramedic', canToggleDuty = true, permissions = { 'ems.radio', 'ems.treat', 'ems.revive' } },
        [2] = { label = 'Chief', canToggleDuty = true, permissions = { 'ems.radio', 'ems.treat', 'ems.revive', 'ems.manage' } }
    }
})
FoundationJobs.Register('mechanic', {
    label = 'Mechanic',
    grades = {
        [0] = { label = 'Apprentice', canToggleDuty = true, permissions = { 'mechanic.repair' } },
        [1] = { label = 'Technician', canToggleDuty = true, permissions = { 'mechanic.repair', 'mechanic.modify' } },
        [2] = { label = 'Shop Manager', canToggleDuty = true, permissions = { 'mechanic.repair', 'mechanic.modify', 'mechanic.manage' } }
    }
})

print('[foundation] Job framework registered.')
