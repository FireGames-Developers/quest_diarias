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
AddEventHandler('quest_diarias:startQuest', function(questId, npcIndex)
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
        TriggerClientEvent('vorp:TipBottom', _source, "Erro interno do sistema de quests", 5000)
        return
    end
    
    -- Verifica se a quest existe
    local quest = questManager.GetQuest(questId)
    if not quest then
        TriggerClientEvent('vorp:TipBottom', _source, "Missão não encontrada", 5000)
        return
    end
    
    -- Verifica se o jogador já tem uma quest ativa
    local identifier = Character.identifier
    local charid = Character.charIdentifier

    -- Cancela automaticamente qualquer missão ativa de dias anteriores
    MySQL.Async.execute('UPDATE quest_diarias SET status = @failed WHERE identifier = @identifier AND charid = @charid AND status = @status AND DATE(created_at) < CURDATE()', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@status'] = 'active',
        ['@failed'] = 'failed'
    })
    
    MySQL.Async.fetchAll('SELECT * FROM quest_diarias WHERE identifier = @identifier AND charid = @charid AND status = @status', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@status'] = 'active'
    }, function(result)
        if result and #result > 0 then
            -- Mensagem genérica, sem depender de nome estático de NPC
            TriggerClientEvent('vorp:TipBottom', _source, 'Você já possui uma missão ativa no momento.', 5000)
            return
        end
        
        -- Bloqueio diário: se Config.MoreOne for falso, impede iniciar nova missão se já completou alguma hoje
        if not Config.MoreOne then
            MySQL.Async.fetchAll('SELECT 1 FROM quest_diarias_history WHERE identifier = @identifier AND charid = @charid AND DATE(FROM_UNIXTIME(completed_at)) = CURDATE() LIMIT 1', {
                ['@identifier'] = identifier,
                ['@charid'] = charid
            }, function(rows)
                if rows and #rows > 0 then
                    TriggerClientEvent('vorp:TipBottom', _source, 'Você já completou uma missão hoje. Volte amanhã.', 5000)
                    return
                end
                -- Inicia a nova quest
                local npcName = (Config.NPCs and npcIndex and Config.NPCs[npcIndex] and Config.NPCs[npcIndex].name) or nil
                MySQL.Async.execute('INSERT INTO quest_diarias (identifier, charid, quest_id, status, progress, created_at, npc_index, npc_name) VALUES (@identifier, @charid, @quest_id, @status, @progress, @created_at, @npc_index, @npc_name)', {
                    ['@identifier'] = identifier,
                    ['@charid'] = charid,
                    ['@quest_id'] = questId,
                    ['@status'] = 'active',
                    ['@progress'] = json.encode({}),
                    ['@created_at'] = os.time(),
                    ['@npc_index'] = npcIndex,
                    ['@npc_name'] = npcName
                }, function(insertId)
                    if insertId then
                        local qname = (quest.Config and quest.Config.name) or (quest.name or ('Missão '..tostring(questId)))
                        TriggerClientEvent('vorp:TipBottom', _source, "Missão '" .. qname .. "' iniciada!", 5000)
                        if quest.StartQuest and type(quest.StartQuest) == 'function' then
                            quest.StartQuest(_source, npcName)
                        end
                        TriggerClientEvent('quest_diarias:questStarted', _source, questId)
                    else
                        TriggerClientEvent('vorp:TipBottom', _source, "Erro ao iniciar quest", 5000)
                    end
                end)
            end)
        else
            -- Inicia a nova quest (sem bloqueio diário)
            local npcName = (Config.NPCs and npcIndex and Config.NPCs[npcIndex] and Config.NPCs[npcIndex].name) or nil
            MySQL.Async.execute('INSERT INTO quest_diarias (identifier, charid, quest_id, status, progress, created_at, npc_index, npc_name) VALUES (@identifier, @charid, @quest_id, @status, @progress, @created_at, @npc_index, @npc_name)', {
                ['@identifier'] = identifier,
                ['@charid'] = charid,
                ['@quest_id'] = questId,
                ['@status'] = 'active',
                ['@progress'] = json.encode({}),
                ['@created_at'] = os.time(),
                ['@npc_index'] = npcIndex,
                ['@npc_name'] = npcName
            }, function(insertId)
                if insertId then
                    local qname = (quest.Config and quest.Config.name) or (quest.name or ('Missão '..tostring(questId)))
                    TriggerClientEvent('vorp:TipBottom', _source, "Missão '" .. qname .. "' iniciada!", 5000)
                    if quest.StartQuest and type(quest.StartQuest) == 'function' then
                        quest.StartQuest(_source, npcName)
                    end
                    TriggerClientEvent('quest_diarias:questStarted', _source, questId)
                else
                    TriggerClientEvent('vorp:TipBottom', _source, "Erro ao iniciar quest", 5000)
                end
            end)
        end
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
        local affected = type(affectedRows) == 'number' and affectedRows or ((type(affectedRows) == 'table' and (affectedRows.affectedRows or affectedRows.changedRows or affectedRows.insertId)) or 0)
        if affected > 0 then
            TriggerClientEvent('quest_diarias:progressUpdated', _source, questId, progressData)
        end
    end)
end)

-- Evento para completar uma quest
RegisterNetEvent('quest_diarias:completeQuest')
AddEventHandler('quest_diarias:completeQuest', function(questId, npcIndex)
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
        TriggerClientEvent('vorp:TipBottom', _source, "Erro interno do sistema de quests", 5000)
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
            TriggerClientEvent('vorp:TipBottom', _source, "Missão não encontrada ou não está ativa", 5000)
            return
        end
        
        local questData = result[1]
        local quest = questManager.GetQuest(questId)
        
        if not quest then
            TriggerClientEvent('vorp:TipBottom', _source, "Configuração de missão não encontrada", 5000)
            return
        end
        
        -- Valida NPC, se houver registro. Se não houver, registra agora.
        local recordedNpcIndex = questData.npc_index
        local recordedNpcName = questData.npc_name
        local npcName = (Config.NPCs and npcIndex and Config.NPCs[npcIndex] and Config.NPCs[npcIndex].name) or nil
        
        if recordedNpcIndex ~= nil then
            if tonumber(recordedNpcIndex) ~= tonumber(npcIndex) then
                TriggerClientEvent('vorp:TipBottom', _source, 'Entrega inválida: NPC diferente da missão iniciada.', 5000)
                return
            end
        else
            -- Atualiza o registro com o NPC atual se ainda não havia
            MySQL.Async.execute('UPDATE quest_diarias SET npc_index = @npc_index, npc_name = @npc_name WHERE id = @id', {
                ['@id'] = questData.id,
                ['@npc_index'] = npcIndex,
                ['@npc_name'] = npcName
            })
        end
        
        -- Marca a quest como completada
        MySQL.Async.execute('UPDATE quest_diarias SET status = @status, completed_at = @completed_at WHERE id = @id', {
            ['@id'] = questData.id,
            ['@status'] = 'completed',
            ['@completed_at'] = os.time()
        }, function(affectedRows)
            local affected = type(affectedRows) == 'number' and affectedRows or ((type(affectedRows) == 'table' and (affectedRows.affectedRows or affectedRows.changedRows or affectedRows.insertId)) or 0)
            if affected > 0 then
                -- Adiciona recompensas conforme configuração da quest
                local rewards = quest.Config and quest.Config.rewards or nil
                if rewards then
                    if rewards.money and rewards.money > 0 then
                        -- 0 = dinheiro padrão
                        Character.addCurrency(0, rewards.money)
                    end
                    -- Itens
                    if rewards.items then
                        for _, item in pairs(rewards.items) do
                            if item.item and item.amount and item.amount > 0 then
                                exports.vorp_inventory:addItem(_source, item.item, item.amount)
                            end
                        end
                    end
                    -- Arma (Cattleman Revolver etc.)
                    if rewards.weapon then
                        local weaponName = (type(rewards.weapon) == 'string') and rewards.weapon or rewards.weapon.name
                        if weaponName then
                            local ammo = { ["nothing"] = 0 }
                            local components = { ["nothing"] = 0 }
                            local comps = {}
                            exports.vorp_inventory:createWeapon(_source, weaponName, ammo, components, comps)
                        end
                    end
                end
                
                -- Registra no histórico com NPC
                MySQL.Async.execute('INSERT INTO quest_diarias_history (identifier, charid, quest_id, completed_at, rewards_given, npc_index, npc_name) VALUES (@identifier, @charid, @quest_id, @completed_at, @rewards_given, @npc_index, @npc_name)', {
                    ['@identifier'] = identifier,
                    ['@charid'] = charid,
                    ['@quest_id'] = questId,
                    ['@completed_at'] = os.time(),
                    ['@rewards_given'] = json.encode(rewards or {}),
                    ['@npc_index'] = npcIndex,
                    ['@npc_name'] = npcName
                })
                
                local qname = (quest.Config and quest.Config.name) or (quest.name or ('Missão '..tostring(questId)))
                TriggerClientEvent('vorp:TipBottom', _source, "Missão '" .. qname .. "' completada!", 5000)
                TriggerClientEvent('quest_diarias:questCompleted', _source, questId, rewards)
            else
                TriggerClientEvent('vorp:TipBottom', _source, "Erro ao completar quest", 5000)
            end
        end)
    end)
end)

-- Event para verificar se pode fazer uma quest (controle diário centralizado)
RegisterServerEvent('quest_diarias:canDoQuest')
AddEventHandler('quest_diarias:canDoQuest', function(questId)
    local source = source
    local User = VorpCore.getUser(source)
    if not User then return end
    local Character = User.getUsedCharacter
    if not Character then return end

    local identifier = Character.identifier
    local charid = Character.charIdentifier

    -- Se config permite várias por dia, sempre elegível (respeita missão ativa no start)
    if Config.MoreOne then
        TriggerClientEvent('quest_diarias:canDoQuestResponse', source, questId, true)
        return
    end

    -- Regra geral: se já completou QUALQUER missão hoje, não pode iniciar outra
    MySQL.Async.fetchAll('SELECT 1 FROM quest_diarias_history WHERE identifier = @identifier AND charid = @charid AND DATE(completed_at) = CURDATE() LIMIT 1', {
        ['@identifier'] = identifier,
        ['@charid'] = charid
    }, function(rows)
        local canDo = not rows or #rows == 0
        TriggerClientEvent('quest_diarias:canDoQuestResponse', source, questId, canDo)
    end)
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

-- Novo evento: entrega via inventário (missões com delivery.requiredItem)
RegisterNetEvent('quest_diarias:attemptDeliveryInventory')
AddEventHandler('quest_diarias:attemptDeliveryInventory', function(questId, npcIndex)
    local _source = source
    local User = VorpCore.getUser(_source)
    if not User then return end
    local Character = User.getUsedCharacter
    if not Character then return end

    local questManager = LoadQuestManager()
    if not questManager then
        TriggerClientEvent('vorp:TipBottom', _source, "Erro interno do sistema de quests", 5000)
        return
    end

    local identifier = Character.identifier
    local charid = Character.charIdentifier

    MySQL.Async.fetchAll('SELECT * FROM quest_diarias WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND status = @status', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId,
        ['@status'] = 'active'
    }, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('vorp:TipBottom', _source, "Missão não encontrada ou não está ativa", 5000)
            return
        end

        local questRow = result[1]
        local recordedNpcIndex = questRow.npc_index
        local npcName = (Config.NPCs and npcIndex and Config.NPCs[npcIndex] and Config.NPCs[npcIndex].name) or nil

        if recordedNpcIndex ~= nil then
            if tonumber(recordedNpcIndex) ~= tonumber(npcIndex) then
                TriggerClientEvent('vorp:TipBottom', _source, 'Entrega inválida: fale com o mesmo NPC da missão.', 5000)
                return
            end
        else
            -- Atualiza com o NPC atual se ainda não definido
            MySQL.Async.execute('UPDATE quest_diarias SET npc_index = @npc_index, npc_name = @npc_name WHERE id = @id', {
                ['@id'] = questRow.id,
                ['@npc_index'] = npcIndex,
                ['@npc_name'] = npcName
            })
        end

        local quest = questManager.GetQuest(questId)
        if not quest or not quest.Config or not quest.Config.delivery or not quest.Config.delivery.requiredItem then
            TriggerClientEvent('vorp:TipBottom', _source, "Configuração de entrega inválida.", 5000)
            return
        end

        local itemName = quest.Config.delivery.requiredItem
        local count = exports.vorp_inventory:getItemCount(_source, nil, itemName, nil)

        if not count or tonumber(count) < 1 then
            local msg = (quest.Config.texts and quest.Config.texts.notDelivered) or "Você ainda não tem a maçã. Volte quando conseguir uma."
            TriggerClientEvent('vorp:TipBottom', _source, msg, 5000)
            return
        end

        local ok = exports.vorp_inventory:subItem(_source, itemName, 1)
        if ok then
            TriggerClientEvent('quest_diarias:inventoryDeliverySuccess', _source, questId)
        else
            TriggerClientEvent('vorp:TipBottom', _source, "Não foi possível retirar a maçã do inventário.", 5000)
        end
    end)
end)

-- ============================================================================
-- INICIALIZAÇÃO
-- ============================================================================

-- Diminui tempo de espera inicial para pré-carregar QuestManager
CreateThread(function()
    Wait(2000) -- era 5000, agora 2000
    LoadQuestManager()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if Config.DevMode then
            print('[Quest Server] Recarregando QuestManager após restart')
        end
        LoadQuestManager()
    end
end)

if Config.DevMode then
    print('[Quest Handler] Sistema de handler de quests inicializado')
end

VorpCore.Callback.Register('quest_diarias:validateNpcForDelivery', function(source, cb, questId, npcIndex)
    local User = VorpCore.getUser(source)
    if not User then cb(false) return end
    local Character = User.getUsedCharacter
    if not Character then cb(false) return end

    local identifier = Character.identifier
    local charid = Character.charIdentifier

    MySQL.Async.fetchAll('SELECT npc_index FROM quest_diarias WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND status = @status', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId,
        ['@status'] = 'active'
    }, function(result)
        if not result or #result == 0 then cb(false) return end
        local recordedNpcIndex = result[1].npc_index
        if recordedNpcIndex == nil then
            local npcName = (Config.NPCs and npcIndex and Config.NPCs[npcIndex] and Config.NPCs[npcIndex].name) or nil
            MySQL.Async.execute('UPDATE quest_diarias SET npc_index = @npc_index, npc_name = @npc_name WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND status = @status', {
                ['@npc_index'] = npcIndex,
                ['@npc_name'] = npcName,
                ['@identifier'] = identifier,
                ['@charid'] = charid,
                ['@quest_id'] = questId,
                ['@status'] = 'active'
            })
            cb(true)
            return
        end
        cb(tonumber(recordedNpcIndex) == tonumber(npcIndex))
    end)
end)