-- Quest Handler - Servidor
-- Desenvolvido por FTx3g

local VorpCore = exports.vorp_core:GetCore()

-- Carregar o gerenciador de quests
local QuestManager = require('modules.quest_manager')

-- Event para iniciar uma quest
RegisterServerEvent('quest_diarias:startQuest')
AddEventHandler('quest_diarias:startQuest', function(questId)
    local source = source
    local User = VorpCore.getUser(source)
    
    if not User then
        if Config.DevMode then
            print(('[Quest Handler] Usuário não encontrado para source: %d'):format(source))
        end
        return
    end
    
    local Character = User.getUsedCharacter
    if not Character then
        if Config.DevMode then
            print(('[Quest Handler] Personagem não encontrado para source: %d'):format(source))
        end
        return
    end
    
    if Config.DevMode then
        print(('[Quest Handler] Iniciando quest %d para jogador %s'):format(questId, Character.identifier))
    end
    
    QuestManager.StartQuest(source, questId)
end)

-- Event para completar uma quest
RegisterServerEvent('quest_diarias:completeQuest')
AddEventHandler('quest_diarias:completeQuest', function(questId)
    local source = source
    local User = VorpCore.getUser(source)
    
    if not User then
        if Config.DevMode then
            print(('[Quest Handler] Usuário não encontrado para source: %d'):format(source))
        end
        return
    end
    
    local Character = User.getUsedCharacter
    if not Character then
        if Config.DevMode then
            print(('[Quest Handler] Personagem não encontrado para source: %d'):format(source))
        end
        return
    end
    
    if Config.DevMode then
        print(('[Quest Handler] Completando quest %d para jogador %s'):format(questId, Character.identifier))
    end
    
    QuestManager.CompleteQuest(source, questId)
end)

-- Event para verificar se pode fazer uma quest
RegisterServerEvent('quest_diarias:canDoQuest')
AddEventHandler('quest_diarias:canDoQuest', function(questId)
    local source = source
    local User = VorpCore.getUser(source)
    
    if not User then
        return
    end
    
    local Character = User.getUsedCharacter
    if not Character then
        return
    end
    
    local quest = QuestManager.GetQuest(questId)
    if quest then
        quest.CanDoQuest(source, function(canDo)
            TriggerClientEvent('quest_diarias:canDoQuestResponse', source, questId, canDo)
        end)
    end
end)

-- Callback para obter informações de uma quest
VorpCore.Callback.Register('quest_diarias:getQuestInfo', function(source, cb, questId)
    local questInfo = QuestManager.GetQuestInfo(questId)
    cb(questInfo)
end)

-- Callback para obter todas as quests disponíveis
VorpCore.Callback.Register('quest_diarias:getAvailableQuests', function(source, cb)
    local quests = QuestManager.GetAvailableQuests()
    cb(quests)
end)

if Config.DevMode then
    print('[Quest Handler] Sistema de handler de quests inicializado')
end