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

-- ============================================================================
-- COMANDOS ADMINISTRATIVOS
-- ============================================================================

-- Comando para listar quests ativas
RegisterCommand('quest_list', function(source, args, rawCommand)
    local _source = source
    
    if _source == 0 then
        print("Este comando só pode ser usado no jogo")
        return
    end
    
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
    
    MySQL.Async.fetchAll('SELECT * FROM quest_diarias WHERE identifier = @identifier AND charid = @charid ORDER BY created_at DESC LIMIT 10', {
        ['@identifier'] = identifier,
        ['@charid'] = charid
    }, function(result)
        if result and #result > 0 then
            VorpCore.NotifyRightTip(_source, "Suas quests:", 2000)
            for _, quest in pairs(result) do
                local status = quest.status == 'active' and "Ativa" or "Completada"
                VorpCore.NotifyRightTip(_source, quest.quest_id .. " - " .. status, 3000)
            end
        else
            VorpCore.NotifyRightTip(_source, "Você não possui quests", 4000)
        end
    end)
end, false)

-- Comando para resetar conclusão de hoje e permitir refazer
-- Uso: /quest_reset [questId]
-- Se questId não for informado, tenta resetar a última completada hoje
RegisterCommand('quest_reset', function(source, args, rawCommand)
    local _source = source
    if _source == 0 then
        print("Este comando só pode ser usado no jogo")
        return
    end

    local User = VorpCore.getUser(_source)
    if not User then return end
    local Character = User.getUsedCharacter
    if not Character then return end

    local identifier = Character.identifier
    local charid = Character.charIdentifier
    local questId = tonumber(args and args[1])

    -- Se questId não fornecido, buscar a última completada hoje
    if not questId then
        MySQL.Async.fetchAll('SELECT quest_id FROM quest_diarias_history WHERE identifier = @identifier AND charid = @charid AND DATE(FROM_UNIXTIME(completed_at)) = CURDATE() ORDER BY completed_at DESC LIMIT 1', {
            ['@identifier'] = identifier,
            ['@charid'] = charid
        }, function(rows)
            if rows and rows[1] and rows[1].quest_id then
                questId = tonumber(rows[1].quest_id)
            end

            -- Prosseguir com reset
            if not questId then
                VorpCore.NotifyRightTip(_source, 'Nenhuma missão completada hoje encontrada para reset', 5000)
                return
            end
            ExecuteQuestReset(_source, identifier, charid, questId)
        end)
    else
        ExecuteQuestReset(_source, identifier, charid, questId)
    end
end, false)

-- Função auxiliar para executar o reset
function ExecuteQuestReset(_source, identifier, charid, questId)
    -- Remover entradas do histórico do dia
    MySQL.Async.execute('DELETE FROM quest_diarias_history WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND DATE(FROM_UNIXTIME(completed_at)) = CURDATE()', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId
    }, function(histDeleted)
        -- Opcional: reabrir a quest marcando status como active caso esteja completed
        MySQL.Async.execute('UPDATE quest_diarias SET status = @status, updated_at = @updated_at, completed_at = NULL WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND status = @completed', {
            ['@identifier'] = identifier,
            ['@charid'] = charid,
            ['@quest_id'] = questId,
            ['@status'] = 'active',
            ['@updated_at'] = os.time(),
            ['@completed'] = 'completed'
        }, function(rowsAffected)
            local msg
            if (histDeleted or 0) > 0 then
                msg = ('Reset realizado: removidas %d entradas de hoje para missão %s.'):format(histDeleted or 0, tostring(questId))
            else
                msg = ('Nenhuma entrada de histórico de hoje para missão %s.'):format(tostring(questId))
            end
            VorpCore.NotifyRightTip(_source, msg, 6000)
        end)
    end)
end

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