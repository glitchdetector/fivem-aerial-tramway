RegisterServerEvent("omni:sync")
AddEventHandler("omni:sync", function(index, state)
    if source == tonumber(GetPlayers()[1]) then
        TriggerClientEvent("omni:forceState", -1, index, state)
    end
end)
