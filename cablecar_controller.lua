RegisterServerEvent("omni:cablecar:host:sync")
AddEventHandler("omni:cablecar:host:sync", function(index, state)
    if tostring(source) == tostring(GetHostId()) then
        TriggerClientEvent("omni:cablecar:forceState", -1, index, state)
    end
end)
