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
            TriggerEvent('vorp:TipBottom', ('Missão iniciada: %s'):format(questInfo.name), 5000)
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
        if rewards.xp and rewards.xp > 0 then
            rewardText = rewardText .. ('\n• %d XP'):format(rewards.xp)
        end
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
    
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, blipData.x, blipData.y, blipData.z)
    SetBlipSprite(blip, blipData.sprite or -2128054417, true)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, blipData.name or 'Missão')
    
    if blipData.color then
        SetBlipColor(blip, blipData.color)
    end
    
    table.insert(questBlips[questId], blip)
    
    if Config.DevMode then
        print(('[Quest Client] Blip criado para quest %d'):format(questId))
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
    end
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