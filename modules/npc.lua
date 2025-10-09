
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

local function SpawnNPC(networked)
    local ok, err = pcall(function()
        LoadModel(Config.NpcModel)
        
        local isNetwork = networked == true
        local attachToScript = isNetwork
        local npc = CreatePed(joaat(Config.NpcModel), Config.NpcPosition.x, Config.NpcPosition.y, Config.NpcPosition.z,
            Config.NpcPosition.h, isNetwork, attachToScript, false, false)
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
        SetModelAsNoLongerNeeded(Config.NpcModel)
        Config.NPC = npc
        DebugPrint("NPC spawnado (networked=" ..
            tostring(isNetwork) ..
            ") em: " .. Config.NpcPosition.x .. ", " .. Config.NpcPosition.y .. ", " .. Config.NpcPosition.z)
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
local function CreateNpcByDistance(distance)
    local ok, err = pcall(function()
        if distance <= 40 then
            if not Config.NPC then
                DebugPrint("Distância menor que 40, spawnando NPC")
                -- se quiser networked para todos, passe true
                SpawnNPC(true)
            end
        else
            if Config.NPC then
                DebugPrint("Distância maior que 40, despawnando NPC")
                SetEntityAsNoLongerNeeded(Config.NPC)
                DeleteEntity(Config.NPC)
                Config.NPC = nil
            end
        end
    end)
    if not ok then DebugError(err) end
end

---------------- CLEANUP on resource stop ---------------------
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DebugPrint("Recurso parado, limpando NPC/blip")
        if Config.NPC and DoesEntityExist(Config.NPC) then
            SetEntityAsNoLongerNeeded(Config.NPC)
            DeleteEntity(Config.NPC)
            Config.NPC = nil
        end
        if Config.BlipHandle then
            RemoveBlip(Config.BlipHandle)
            Config.BlipHandle = nil
        end
    end
end)

---------------- THREAD PRINCIPAL ---------------------
-- Inicializa quando o player spawnar no client
AddEventHandler('playerSpawned', function()
    CreateThread(function()
        repeat Wait(2000) until LocalPlayer and LocalPlayer.state and LocalPlayer.state.IsInSession
        DebugPrint("playerSpawned recebido no client, inicializando prompt e loop")
        PromptSetUp()

        while true do
            local sleep = 1000
            local player = PlayerPedId()
            local dead = IsEntityDead(player)
            if not dead then
                local distance = getDistance(Config.NpcPosition)

                if not Config.BlipHandle and Config.blipAllowed then
                    AddBlip()
                end

                CreateNpcByDistance(distance)

                if distance <= Config.distOpen then
                    sleep = 0
                    local label = CreateVarString(10, 'LITERAL_STRING', Config.text.store .. " " .. (Config.Name or "Loja"))
                    PromptSetActiveGroupThisFrame(prompts, label)
                    if PromptHasStandardModeCompleted(openmenu) then
                        -- interagiu
                        DebugPrint("Player ativou prompt - abrir loja")
                        TaskStandStill(PlayerPedId(), -1)
                        DisplayRadar(false)
                        inmenu = OpenStore()
                    end
                end
            end
            Wait(sleep)
        end
    end)
end)

-- Também ouça evento server (opcional) caso o server queira forçar spawn para um client
RegisterNetEvent("firegames_ilegalstore:spawnNPCClient")
AddEventHandler("firegames_ilegalstore:spawnNPCClient", function()
    DebugPrint("Evento spawnNPCClient recebido do server")
    -- Força execução do playerSpawned handler (se quiser executar imediatamente)
    TriggerEvent('playerSpawned')
end)
