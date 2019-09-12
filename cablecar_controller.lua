RegisterServerEvent("omni:cablecar:host:sync")
AddEventHandler("omni:cablecar:host:sync", function(index, state)
    if source == GetPlayers()[1] then
        TriggerClientEvent("omni:cablecar:forceState", -1, index, state)
    end
end)
