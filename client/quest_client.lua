-- Quest Client - Sistema de Missões do Cliente
-- Desenvolvido por FTx3g

local VorpCore = exports.vorp_core:GetCore()
local activeQuest = nil
local questBlips = {}

-- Event para quando uma quest é iniciada
RegisterNetEvent('quest_diarias:questStarted')
AddEventHandler('quest_diarias:questStarted', function(questId)
    if Config.DevMode then
        print(('[Quest Client] Quest %d iniciada'):format(questId))
    end
    
    activeQuest = questId
    
    -- Notificar o jogador
    VorpCore.Callback.TriggerAsync('quest_diarias:getQuestInfo', function(questInfo)
        if questInfo then
            local npcName = (Config.CurrentNPC and Config.CurrentNPC.name) or 'NPC'
            local details = questInfo.description or 'Verifique o mapa e os objetivos.'
            local msg = ('Você aceitou a missão de %s. Detalhes: %s'):format(npcName, details)
            TriggerEvent('vorp:TipBottom', msg, 7000)
        end
    end, questId)
end)

-- Event para quando uma quest é completada
RegisterNetEvent('quest_diarias:questCompleted')
AddEventHandler('quest_diarias:questCompleted', function(questId, rewards)
    if Config.DevMode then
        print(('[Quest Client] Quest %d completada'):format(questId))
    end
    
    activeQuest = nil
    
    -- Remover blips da quest
    if questBlips[questId] then
        for _, blip in pairs(questBlips[questId]) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        questBlips[questId] = nil
    end
    
    -- Notificar o jogador sobre as recompensas
    if rewards then
        local rewardText = 'Missão completada! Recompensas:'
        if rewards.money and rewards.money > 0 then
            rewardText = rewardText .. ('\n• $%.2f'):format(rewards.money)
        end
        -- XP removido; sem exibição de Gold, apenas Money
        if rewards.items then
            for _, item in pairs(rewards.items) do
                rewardText = rewardText .. ('\n• %dx %s'):format(item.amount, item.name)
            end
        end
        
        TriggerEvent('vorp:TipBottom', rewardText, 8000)
    end
end)

-- Event para criar blip de quest
RegisterNetEvent('quest_diarias:createQuestBlip')
AddEventHandler('quest_diarias:createQuestBlip', function(questId, blipData)
    if not questBlips[questId] then
        questBlips[questId] = {}
    end

    -- Blip pontual (ícone no centro da área)
    local pointBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, blipData.x, blipData.y, blipData.z)
    SetBlipSprite(pointBlip, blipData.sprite or Config.blipsprite, true)
    Citizen.InvokeNative(0x9CB1A1623062F402, pointBlip, blipData.name or 'Missão')
    if blipData.color then
        SetBlipColor(pointBlip, blipData.color)
    end
    table.insert(questBlips[questId], pointBlip)

    -- Mancha de área (círculo visível no mapa) quando radius for informado
    if blipData.radius and type(blipData.radius) == 'number' and blipData.radius > 0 then
        local areaStyle = blipData.areaStyle or blipData.sprite or -1282792512
        local radiusBlip = Citizen.InvokeNative(0x45f13b7e0a15c880, areaStyle, blipData.x, blipData.y, blipData.z, blipData.radius)
        -- Nome e cor (alguns estilos permitem cor; manteremos tentativa amigável)
        Citizen.InvokeNative(0x9CB1A1623062F402, radiusBlip, blipData.name or 'Área da Missão')
        if blipData.areaColor or blipData.color then
            SetBlipColor(radiusBlip, blipData.areaColor or blipData.color)
        end
        table.insert(questBlips[questId], radiusBlip)
    end

    if Config.DevMode then
        print(('[Quest Client] Blips criados para quest %d (ponto%s)'):format(
            questId,
            blipData.radius and ' + área' or ''
        ))
    end
end)

-- Event para remover blip de quest
RegisterNetEvent('quest_diarias:removeQuestBlip')
AddEventHandler('quest_diarias:removeQuestBlip', function(questId)
    if questBlips[questId] then
        for _, blip in pairs(questBlips[questId]) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        questBlips[questId] = nil
        
        if Config.DevMode then
            print(('[Quest Client] Blips removidos para quest %d'):format(questId))
        end
    end
end)

-- Event para resposta de verificação de quest
RegisterNetEvent('quest_diarias:canDoQuestResponse')
AddEventHandler('quest_diarias:canDoQuestResponse', function(questId, canDo)
    if not canDo then
        TriggerEvent('vorp:TipBottom', 'Você já completou esta missão hoje!', 3000)
        return
    end
    -- Elegível: iniciar missão automaticamente (com NPC index)
    local function GetCurrentNpcIndex()
        if Config.CurrentNPCIdx then return Config.CurrentNPCIdx end
        local name = Config.CurrentNPC and Config.CurrentNPC.name
        if name and Config.NPCs then
            for i, npc in ipairs(Config.NPCs) do
                if npc.name == name then return i end
            end
        end
        return nil
    end
    local npcIdx = GetCurrentNpcIndex()
    TriggerServerEvent('quest_diarias:startQuest', questId, npcIdx)
end)

-- Função para obter a quest ativa
function GetActiveQuest()
    return activeQuest
end

-- Função para verificar se tem uma quest ativa
function HasActiveQuest()
    return activeQuest ~= nil
end

if Config.DevMode then
    print('[Quest Client] Sistema de quests do cliente inicializado')
end

-- =========================================================================
-- TESTE DE MISSÃO (GENÉRICO)
-- =========================================================================
RegisterNetEvent('quest_diarias:runMissionTest')
AddEventHandler('quest_diarias:runMissionTest', function(questId, payload)
    if questId == 1 and payload and payload.action == 'spawnAnimal' then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local forward = GetEntityForwardVector(ped)
        local spawnDist = (type(payload.distance) == 'number' and payload.distance or 6.0)
        local spawnPos = vector3(
            coords.x + forward.x * spawnDist,
            coords.y + forward.y * spawnDist,
            coords.z + forward.z * spawnDist
        )
        local model = GetHashKey(payload.model or 'A_C_PHEASANT_01')
        if not IsModelInCdimage(model) then
            TriggerEvent('vorp:TipBottom', 'Modelo de animal indisponível', 3000)
            return
        end
        RequestModel(model, false)
        repeat Wait(0) until HasModelLoaded(model)
        local created = CreatePed(model, spawnPos.x, spawnPos.y, spawnPos.z, GetEntityHeading(ped), true, false, false, false)
        if not DoesEntityExist(created) then
            TriggerEvent('vorp:TipBottom', 'Falha ao spawnar animal de teste', 3000)
            SetModelAsNoLongerNeeded(model)
            return
        end
        Citizen.InvokeNative(0x283978A15512B2FE, created, true)
        PlaceEntityOnGroundProperly(created, true)
        SetEntityAsMissionEntity(created, true, true)
        if payload.dead then
            FreezeEntityPosition(created, false)
            SetEntityHealth(created, 0)
            PlaceEntityOnGroundProperly(created, true)
            ClearPedTasksImmediately(created)
            TriggerEvent('vorp:TipBottom', 'Carcaça posicionada no chão', 3000)
        else
            TriggerEvent('vorp:TipBottom', 'Animal spawnado à sua frente', 3000)
        end
        SetModelAsNoLongerNeeded(model)
    else
        if Config.DevMode then
            print('[Quest Client] Nenhuma rotina de teste configurada para esta missão')
        end
    end
end)
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        activeQuest = nil
        for id, blips in pairs(questBlips) do
            for _, blip in pairs(blips) do
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end
            questBlips[id] = nil
        end
        TriggerEvent('vorp:TipBottom', 'Sistema de quests reiniciado.', 3000)
    end
end)
AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        activeQuest = nil
        for id, blips in pairs(questBlips) do
            for _, blip in pairs(blips) do
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end
            questBlips[id] = nil
        end
    end
end)