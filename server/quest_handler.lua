-- ============================================================================
-- QUEST DIÁRIAS - MANIPULADOR DE QUESTS
-- ============================================================================
-- Este arquivo gerencia todas as operações relacionadas às quests diárias,
-- incluindo carregamento, validação e execução de quests.
-- 
-- DEPENDÊNCIA DO VORP CORE: Este módulo utiliza o LoadResourceFile para
-- carregar o quest_manager de forma segura, evitando problemas de dependência
-- circular com o sistema require() do FiveM/RedM.
-- ============================================================================

local VorpCore = exports.vorp_core:GetCore()

-- ============================================================================
-- CARREGAMENTO SEGURO DO QUEST MANAGER
-- ============================================================================
-- IMPORTANTE: Utilizamos LoadResourceFile em vez de require() para evitar
-- problemas de "module not found" que podem ocorrer devido à ordem de
-- carregamento dos recursos no FiveM/RedM.
-- 
-- Esta abordagem garante que o módulo seja carregado corretamente mesmo
-- quando há dependências complexas entre recursos.
-- ============================================================================
local QuestManager = nil

-- Função para carregar o QuestManager de forma segura
local function LoadQuestManager()
    if QuestManager then
        return QuestManager -- Já carregado
    end
    
    -- Usar o ModuleLoader para carregar o QuestManager
    QuestManager = ModuleLoader.LoadModule("modules/quest_manager.lua", "QuestManager")
    
    if QuestManager then
        print("^2[QUEST DIÁRIAS]^0 ✓ Quest Manager carregado com sucesso via ModuleLoader")
        return QuestManager
    else
        print("^1[QUEST DIÁRIAS]^0 ✗ Erro: Falha ao carregar Quest Manager via ModuleLoader")
        return nil
    end
end

-- ============================================================================
-- EVENTOS DE QUEST
-- ============================================================================

-- Evento para iniciar uma quest
RegisterNetEvent('quest_diarias:startQuest')
AddEventHandler('quest_diarias:startQuest', function(questId)
    local _source = source
    local User = VorpCore.getUser(_source)
    
    if not User then
        return
    end
    
    local Character = User.getUsedCharacter
    if not Character then
        return
    end
    
    -- Carrega o QuestManager se necessário
    local questManager = LoadQuestManager()
    if not questManager then
        VorpCore.NotifyRightTip(_source, "Erro interno do sistema de quests", 4000)
        return
    end
    
    -- Verifica se a quest existe
    local quest = questManager.GetQuest(questId)
    if not quest then
        VorpCore.NotifyRightTip(_source, "Missão não encontrada", 4000)
        return
    end
    
    -- Verifica se o jogador já tem uma quest ativa
    local identifier = Character.identifier
    local charid = Character.charIdentifier
    
    MySQL.Async.fetchAll('SELECT * FROM quest_diarias WHERE identifier = @identifier AND charid = @charid AND status = @status', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@status'] = 'active'
    }, function(result)
        if result and #result > 0 then
            local npcName = Config.NpcName or 'NPC'
            VorpCore.NotifyRightTip(_source, ("Você já está ajudando %s no momento."):format(npcName), 5000)
            return
        end
        
        -- Inicia a nova quest
        MySQL.Async.execute('INSERT INTO quest_diarias (identifier, charid, quest_id, status, progress, created_at) VALUES (@identifier, @charid, @quest_id, @status, @progress, @created_at)', {
            ['@identifier'] = identifier,
            ['@charid'] = charid,
            ['@quest_id'] = questId,
            ['@status'] = 'active',
            ['@progress'] = json.encode({}),
            ['@created_at'] = os.time()
        }, function(insertId)
            if insertId then
                local qname = (quest.Config and quest.Config.name) or (quest.name or ('Missão '..tostring(questId)))
                VorpCore.NotifyRightTip(_source, "Missão '" .. qname .. "' iniciada!", 4000)
                TriggerClientEvent('quest_diarias:questStarted', _source, questId)
            else
                VorpCore.NotifyRightTip(_source, "Erro ao iniciar quest", 4000)
            end
        end)
    end)
end)

-- Evento para atualizar progresso da quest
RegisterNetEvent('quest_diarias:updateProgress')
AddEventHandler('quest_diarias:updateProgress', function(questId, progressData)
    local _source = source
    local User = VorpCore.getUser(_source)
    
    if not User then
        return
    end
    
    local Character = User.getUsedCharacter
    if not Character then
        return
    end
    
    local identifier = Character.identifier
    local charid = Character.charIdentifier
    
    -- Atualiza o progresso no banco de dados
    MySQL.Async.execute('UPDATE quest_diarias SET progress = @progress, updated_at = @updated_at WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND status = @status', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId,
        ['@status'] = 'active',
        ['@progress'] = json.encode(progressData),
        ['@updated_at'] = os.time()
    }, function(affectedRows)
        if affectedRows > 0 then
            TriggerClientEvent('quest_diarias:progressUpdated', _source, questId, progressData)
        end
    end)
end)

-- Evento para completar uma quest
RegisterNetEvent('quest_diarias:completeQuest')
AddEventHandler('quest_diarias:completeQuest', function(questId)
    local _source = source
    local User = VorpCore.getUser(_source)
    
    if not User then
        return
    end
    
    local Character = User.getUsedCharacter
    if not Character then
        return
    end
    
    -- Carrega o QuestManager se necessário
    local questManager = LoadQuestManager()
    if not questManager then
        VorpCore.NotifyRightTip(_source, "Erro interno do sistema de quests", 4000)
        return
    end
    
    local identifier = Character.identifier
    local charid = Character.charIdentifier
    
    -- Verifica se a quest está ativa
    MySQL.Async.fetchAll('SELECT * FROM quest_diarias WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND status = @status', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId,
        ['@status'] = 'active'
    }, function(result)
        if not result or #result == 0 then
            VorpCore.NotifyRightTip(_source, "Missão não encontrada ou não está ativa", 4000)
            return
        end
        
    local questData = result[1]
    local quest = questManager.GetQuest(questId)
        
        if not quest then
            VorpCore.NotifyRightTip(_source, "Configuração de missão não encontrada", 4000)
            return
        end
        
        -- Marca a quest como completada
        MySQL.Async.execute('UPDATE quest_diarias SET status = @status, completed_at = @completed_at WHERE id = @id', {
            ['@id'] = questData.id,
            ['@status'] = 'completed',
            ['@completed_at'] = os.time()
        }, function(affectedRows)
            if affectedRows > 0 then
                -- Adiciona recompensas conforme configuração da quest
                local rewards = quest.Config and quest.Config.rewards or nil
                if rewards then
                    if rewards.money and rewards.money > 0 then
                        -- 0 = dinheiro padrão
                        Character.addCurrency(0, rewards.money)
                    end
                    if rewards.gold and rewards.gold > 0 then
                        -- 1 = ouro, se suportado
                        Character.addCurrency(1, rewards.gold)
                    end
                    if rewards.items then
                        for _, item in pairs(rewards.items) do
                            if item.item and item.amount and item.amount > 0 then
                                exports.vorp_inventory:addItem(_source, item.item, item.amount)
                            end
                        end
                    end
                end
                
                -- Registra no histórico
                MySQL.Async.execute('INSERT INTO quest_diarias_history (identifier, charid, quest_id, completed_at) VALUES (@identifier, @charid, @quest_id, @completed_at)', {
                    ['@identifier'] = identifier,
                    ['@charid'] = charid,
                    ['@quest_id'] = questId,
                    ['@completed_at'] = os.time()
                })
                
                local qname = (quest.Config and quest.Config.name) or (quest.name or ('Missão '..tostring(questId)))
                VorpCore.NotifyRightTip(_source, "Missão '" .. qname .. "' completada!", 4000)
                TriggerClientEvent('quest_diarias:questCompleted', _source, questId, rewards)
            else
                VorpCore.NotifyRightTip(_source, "Erro ao completar quest", 4000)
            end
        end)
    end)
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
    
    local questManager = LoadQuestManager()
    if not questManager then
        return
    end
    
    local quest = questManager.GetQuest(questId)
    if quest then
        quest.CanDoQuest(source, function(canDo)
            TriggerClientEvent('quest_diarias:canDoQuestResponse', source, questId, canDo)
        end)
    end
end)

-- Callback para obter informações de uma quest
VorpCore.Callback.Register('quest_diarias:getQuestInfo', function(source, cb, questId)
    local questManager = LoadQuestManager()
    if questManager then
        local questInfo = questManager.GetQuestInfo(questId)
        cb(questInfo)
    else
        cb(nil)
    end
end)

-- Callback para obter configuração de entrega (modelos aceitos etc.)
VorpCore.Callback.Register('quest_diarias:getDeliveryConfig', function(source, cb, questId)
    local questManager = LoadQuestManager()
    if not questManager then
        cb(nil)
        return
    end

    local quest = questManager.GetQuest(questId)
    if not quest or not quest.Config or not quest.Config.delivery then
        cb(nil)
        return
    end

    cb(quest.Config.delivery)
end)

-- Callback para obter todas as quests disponíveis
VorpCore.Callback.Register('quest_diarias:getAvailableQuests', function(source, cb)
    local questManager = LoadQuestManager()
    if questManager then
        local quests = questManager.GetAvailableQuests()
        cb(quests)
    else
        cb({})
    end
end)

-- [Comandos administrativos movidos para server/commands.lua]

-- ============================================================================
-- INICIALIZAÇÃO
-- ============================================================================

-- Pré-carrega o QuestManager quando o recurso inicia
CreateThread(function()
    Wait(5000) -- Aguarda um pouco para garantir que tudo esteja carregado
    LoadQuestManager()
end)

if Config.DevMode then
    print('[Quest Handler] Sistema de handler de quests inicializado')
end