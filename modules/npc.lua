
-- =============================================================================
-- MÓDULO: NPC
-- Gerencia spawn/despawn do NPC com base na distância do jogador,
-- configuração de invencibilidade e integração com prompt/menu.
-- Também escuta evento opcional do servidor para forçar spawn.
-- Dependências: `Config`, `DebugPrint`, `DebugError`, `menu.lua` e `blips.lua`.
-- =============================================================================
---------------- NPC ---------------------
-- Fallback de debug (caso globais não estejam definidos ainda)
if type(DebugPrint) ~= 'function' then
    function DebugPrint(msg)
        if Config and Config.DevMode then
            print(tostring(msg))
        end
    end
end
if type(DebugError) ~= 'function' then
    function DebugError(err)
        if Config and Config.DevMode then
            print('[Quest NPC] ' .. tostring(err))
        end
    end
end
local function LoadModel(model)
    local ok, err = pcall(function()
        if not HasModelLoaded(model) then
            RequestModel(model, false)
            repeat Wait(0) until HasModelLoaded(model)
            DebugPrint("Modelo carregado: " .. tostring(model))
        end
    end)
    if not ok then DebugError(err) end
end

-- Removido suporte single-NPC; usar SpawnNPCForIndex com Config.NPCs

-- Multi-NPC: spawn por índice
local function SpawnNPCForIndex(idx, npcConf, networked)
    local ok, err = pcall(function()
        LoadModel(npcConf.model)
        local isNetwork = networked == true
        local attachToScript = isNetwork
        local p = npcConf.position
        local npc = CreatePed(joaat(npcConf.model), p.x, p.y, p.z, p.h, isNetwork, attachToScript, false, false)
        repeat Wait(100) until DoesEntityExist(npc)
        SetRandomOutfitVariation(npc, false)
        PlaceEntityOnGroundProperly(npc, true)
        Citizen.InvokeNative(0x283978A15512B2FE, npc, true)
        SetEntityCanBeDamaged(npc, false)
        SetEntityInvincible(npc, true)
        FreezeEntityPosition(npc, true)
        Wait(1000)
        TaskStandStill(npc, -1)
        SetBlockingOfNonTemporaryEvents(npc, true)
        SetModelAsNoLongerNeeded(npcConf.model)
        Config.NPC_ENTS = Config.NPC_ENTS or {}
        Config.NPC_ENTS[idx] = npc
        DebugPrint(("NPC '%s' spawnado (networked=%s) em: %.3f, %.3f, %.3f"):format(npcConf.name or ('NPC #'..idx), tostring(isNetwork), p.x, p.y, p.z))
    end)
    if not ok then DebugError(err) end
end

---------------- DISTÂNCIA ---------------------
local function getDistance(config)
    local coords = GetEntityCoords(PlayerPedId())
    local coords2 = vector3(config.x, config.y, config.z)
    local dist = #(coords - coords2)
    return dist
end

---------------- SPAWN/DESPWN NPC ---------------------
-- Removido fallback single-NPC; use CreateNpcByDistanceForIndex

-- Multi-NPC
local function CreateNpcByDistanceForIndex(idx, npcConf, distance)
    local ok, err = pcall(function()
        Config.NPC_ENTS = Config.NPC_ENTS or {}
        if distance <= 40 then
            if not Config.NPC_ENTS[idx] then
                DebugPrint(("Distância <= 40, spawnando NPC '%s' (#%d)"):format(npcConf.name or 'NPC', idx))
                SpawnNPCForIndex(idx, npcConf, true)
            end
        else
            if Config.NPC_ENTS[idx] then
                DebugPrint(("Distância > 40, despawnando NPC '%s' (#%d)"):format(npcConf.name or 'NPC', idx))
                SetEntityAsNoLongerNeeded(Config.NPC_ENTS[idx])
                DeleteEntity(Config.NPC_ENTS[idx])
                Config.NPC_ENTS[idx] = nil
            end
        end
    end)
    if not ok then DebugError(err) end
end

---------------- CLEANUP on resource stop ---------------------
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DebugPrint("Recurso parado, limpando NPC/blip")
        -- Removidos limpeza de single NPC/blip; apenas múltiplos são usados agora
        if Config.NPC_ENTS then
            for i, ped in pairs(Config.NPC_ENTS) do
                if DoesEntityExist(ped) then
                    SetEntityAsNoLongerNeeded(ped)
                    DeleteEntity(ped)
                end
                Config.NPC_ENTS[i] = nil
            end
            Config.NPC_ENTS = nil
        end
        if Config.BlipHandles then
            for i, blip in pairs(Config.BlipHandles) do
                if blip then RemoveBlip(blip) end
                Config.BlipHandles[i] = nil
            end
            Config.BlipHandles = nil
        end
    end
end)

---------------- THREAD PRINCIPAL ---------------------
-- Inicializa quando o player spawnar no client
-- Guard para evitar múltiplos loops simultâneos
local npcLoopStarted = false

local function StartNpcLoop()
    if npcLoopStarted then return end
    npcLoopStarted = true
    CreateThread(function()
        repeat Wait(2000) until LocalPlayer and LocalPlayer.state and LocalPlayer.state.IsInSession
        DebugPrint("Inicializando prompt/NPC/blip (loop)")
        PromptSetUp()

        while true do
            local sleep = 1000
            local player = PlayerPedId()
            local dead = IsEntityDead(player)
            if not dead then
                local npcs = Config.NPCs or {}
                if #npcs > 0 then
                    -- Multi-NPC
                    local nearestIdx, nearestDist = nil, nil
                    for i, npcConf in ipairs(npcs) do
                        local dist = getDistance(npcConf.position)

                        -- blip por NPC
                        if Config.blipAllowed then
                            Config.BlipHandles = Config.BlipHandles or {}
                            if not Config.BlipHandles[i] then
                                AddBlipForNpc(i, npcConf)
                            end
                        end

                        -- spawn/despawn
                        CreateNpcByDistanceForIndex(i, npcConf, dist)

                        -- selecionar mais próximo dentro do raio de abertura
                        if dist <= Config.distOpen and (not nearestDist or dist < nearestDist) then
                            nearestIdx = i
                            nearestDist = dist
                        end
                    end

                    if nearestIdx then
                        sleep = 0
                        local npcConf = npcs[nearestIdx]
                        local label = CreateVarString(10, 'LITERAL_STRING', "Falar com " .. (npcConf.name or "NPC"))
                        PromptSetActiveGroupThisFrame(prompts, label)
                        PromptSetText(openmenu, label)
                        if PromptHasStandardModeCompleted(openmenu) then
                            TaskStandStill(PlayerPedId(), -1)
                            DisplayRadar(false)
                            Config.CurrentNPC = npcConf
                            Config.CurrentNPCIdx = nearestIdx
                            inmenu = OpenStore()
                        end
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

AddEventHandler('playerSpawned', function()
    StartNpcLoop()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        StartNpcLoop()
    end
end)

-- Também ouça evento server (opcional) caso o server queira forçar spawn para um client
RegisterNetEvent("firegames_ilegalstore:spawnNPCClient")
AddEventHandler("firegames_ilegalstore:spawnNPCClient", function()
    DebugPrint("Evento spawnNPCClient recebido do server")
    StartNpcLoop()
end)
