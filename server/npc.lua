-- Evento para notificar todos os players que devem spawnar o NPC
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local src = source
    -- envia para o client que acabou de conectar para inicializar blip/npc localmente
    TriggerClientEvent("firegames_ilegalstore:spawnNPCClient", src)
    if Config and Config.DevMode then
        print("[FTx Server] spawnNPCClient enviado para player id: " .. tostring(src))
    end
end)