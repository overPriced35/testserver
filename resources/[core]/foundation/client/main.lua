RegisterNetEvent('foundation:client:characters:open', function()
    TriggerServerEvent('foundation:server:characters:request')
end)

RegisterNetEvent('foundation:client:characters:list', function(characters, err)
    TriggerEvent('foundation:client:characters:available', characters, err)
end)

RegisterNetEvent('foundation:client:characters:created', function(success, result)
    TriggerEvent('foundation:client:characters:createResult', success, result)
    if success then
        TriggerServerEvent('foundation:server:characters:request')
    end
end)

RegisterNetEvent('foundation:client:characters:selected', function(success, result)
    TriggerEvent('foundation:client:characters:selectResult', success, result)
end)
