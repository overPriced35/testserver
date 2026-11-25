AddEventHandler('playerJoining', function()
    local source = source
    local ok, err = pcall(FoundationPlayers.Load, source)
    if not ok then
        print(('[foundation] Failed to load player %s: %s'):format(source, err))
        DropPlayer(source, 'Your player data could not be loaded. Please reconnect.')
    end
end)

AddEventHandler('playerDropped', function()
    FoundationPlayers.Unload(source)
end)

exports('GetPlayer', FoundationPlayers.Get)
exports('GetPlayers', FoundationPlayers.GetAll)

print('[foundation] Server foundation started.')
