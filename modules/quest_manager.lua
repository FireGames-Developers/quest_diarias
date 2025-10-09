-- Quest Manager - Sistema de Gerenciamento de Missões
-- Desenvolvido por FTx3g

QuestManager = {}
QuestManager.LoadedQuests = {}

-- Função para carregar uma quest específica
function QuestManager.LoadQuest(questId)
    local questFile = ('quests/quest%d.lua'):format(questId)
    
    -- Ler o conteúdo do arquivo de recurso com segurança
    local content = LoadResourceFile(GetCurrentResourceName(), questFile)
    if not content or content == '' then
        if Config.DevMode then
            print(('[Quest Manager] Arquivo de missão não encontrado: %s'):format(questFile))
        end
        return nil
    end

    -- Compilar e executar o conteúdo para obter a tabela da missão
    local chunk, cerr = load(content, questFile)
    if not chunk then
        if Config.DevMode then
            print(('[Quest Manager] Erro ao compilar missão %d: %s'):format(questId, tostring(cerr)))
        end
        return nil
    end

    local ok, quest = pcall(chunk)
    if ok and quest then
        QuestManager.LoadedQuests[questId] = quest
        if Config.DevMode then
            print(('[Quest Manager] Missão %d carregada com sucesso'):format(questId))
        end
        return quest
    else
        if Config.DevMode then
            print(('[Quest Manager] Erro ao carregar missão %d: %s'):format(questId, tostring(quest)))
        end
        return nil
    end
end

-- Função para obter uma quest carregada
function QuestManager.GetQuest(questId)
    if not QuestManager.LoadedQuests[questId] then
        return QuestManager.LoadQuest(questId)
    end
    return QuestManager.LoadedQuests[questId]
end

-- Função para iniciar uma quest
function QuestManager.StartQuest(source, questId)
    local quest = QuestManager.GetQuest(questId)
    if not quest then
        if Config.DevMode then
            print(('[Quest Manager] Missão %d não encontrada'):format(questId))
        end
        return false
    end
    
    -- Verificar se o jogador pode fazer a quest
    quest.CanDoQuest(source, function(canDo)
        if canDo then
            quest.StartQuest(source)
            TriggerClientEvent('quest_diarias:questStarted', source, questId)
        else
            TriggerClientEvent('vorp:TipBottom', source, quest.Config.texts.alreadyCompleted, 3000)
        end
    end)
    
    return true
end

-- Função para completar uma quest
function QuestManager.CompleteQuest(source, questId)
    local quest = QuestManager.GetQuest(questId)
    if not quest then
        if Config.DevMode then
            print(('[Quest Manager] Missão %d não encontrada'):format(questId))
        end
        return false
    end
    
    return quest.CompleteQuest(source)
end

-- Função para obter informações de uma quest
function QuestManager.GetQuestInfo(questId)
    local quest = QuestManager.GetQuest(questId)
    if not quest then
        return nil
    end
    
    return {
        id = quest.Config.id,
        name = quest.Config.name,
        description = quest.Config.description,
        rewards = quest.Config.rewards
    }
end

-- Função para listar todas as quests disponíveis
function QuestManager.GetAvailableQuests()
    local quests = {}
    
    -- Tentar carregar quests de 1 a 10 (ou quantas existirem)
    for i = 1, 10 do
        local quest = QuestManager.GetQuest(i)
        if quest then
            table.insert(quests, QuestManager.GetQuestInfo(i))
        end
    end
    
    return quests
end

-- Inicializar o sistema
if Config.DevMode then
    print('[Quest Manager] Sistema de missões inicializado')
end

return QuestManager