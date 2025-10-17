-- =========================================================================
-- Missão 2: Doces Para Karine (Entrega de Maçã)
-- =========================================================================
-- Objetivo: Entregar uma maçã para a Karine. Recompensa: Cattleman Revolver.
-- Estrutura segue o padrão modular da missão 1.
-- =========================================================================

local Quest2 = {}

-- Configurações principais
Quest2.Config = {
    id = 2,
    name = "Doces Para Karine",
    description = "Encontre uma maçã fresquinha e entregue à Karine.",

    rewards = {
        money = 0,
        weapon = "WEAPON_REVOLVER_CATTLEMAN", -- adicionada diretamente ao inventário
        items = {
            -- pode adicionar brindes aqui se desejar
        }
    },

    delivery = {
        requiredItem = "apple" -- entregue via inventário
    },

    texts = {
        start = "Eu estou desejando algo doce... Traga uma maçã bem vermelha pra mim!",
        progress = "Procure uma maçã e traga para a Karine.",
        deliverHint = "Abra o menu da Karine e escolha Entregar Itens com a maçã no inventário.",
        complete = "Uau, perfeita! Essa maçã está deliciosa. Aqui está sua recompensa!",
        alreadyCompleted = "Você já ajudou este NPC hoje. Volte amanhã para novas missões.",
        notDelivered = "Você ainda não tem a maçã. Volte quando conseguir uma.",
        error = "Ocorreu um erro ao processar a missão."
    }
}

-- Eventos para integração (mantém compatibilidade com fluxo existente)
Quest2.Events = {
    attemptDelivery = 'quest_diarias:attemptDelivery',
    questStartedClient = 'quest_diarias:questStarted',
    questCompletedClient = 'quest_diarias:questCompleted'
}

-- Iniciar missão
function Quest2.StartQuest(source)
    TriggerClientEvent('vorp:TipBottom', source, Quest2.Config.texts.start, 6000)
    return true
end

-- Objetivos da missão (para /quest)
function Quest2.GetObjectives(progress)
    local objectives = {}
    table.insert(objectives, ('Missão: %s'):format(Quest2.Config.name))
    table.insert(objectives, Quest2.Config.description)
    table.insert(objectives, Quest2.Config.texts.progress)
    table.insert(objectives, Quest2.Config.texts.deliverHint)

    local status = (progress and progress.delivered) and 'Concluído' or 'Pendente'
    table.insert(objectives, ('Progresso: Entrega da maçã - %s'):format(status))

    local rewards = Quest2.Config.rewards
    if rewards then
        local items = {}
        if rewards.money and rewards.money > 0 then table.insert(items, ('$%d'):format(rewards.money)) end
        if rewards.weapon then table.insert(items, 'Cattleman Revolver') end
        if rewards.items and #rewards.items > 0 then table.insert(items, ('%d item(ns)'):format(#rewards.items)) end
        if #items > 0 then
            table.insert(objectives, ('Recompensas: %s'):format(table.concat(items, ', ')))
        end
    end

    return objectives
end

-- Teste específico da missão 2 (executado via /quest_test)
function Quest2.RunTest(source, params)
    -- Para missão 2, damos uma maçã no inventário para testar entrega.
    local itemName = Quest2.Config.delivery.requiredItem
    local canCarry = exports.vorp_inventory:canCarryItem(source, itemName, 1)
    if canCarry then
        exports.vorp_inventory:addItem(source, itemName, 1, nil, function(success)
            if success then
                TriggerClientEvent('vorp:TipBottom', source, 'Você recebeu uma maçã para teste. Entregue à Karine.', 6000)
            else
                TriggerClientEvent('vorp:TipBottom', source, 'Não foi possível adicionar a maçã ao seu inventário.', 6000)
            end
        end)
    else
        TriggerClientEvent('vorp:TipBottom', source, 'Seu inventário está cheio. Faça espaço para receber a maçã.', 6000)
    end
end

-- retorno movido para o final do arquivo para suportar cliente

-- Eventos de entrega por-quest (cliente/servidor)
if not IsDuplicityVersion() then
    -- Cliente: aciona servidor e completa ao sucesso
    RegisterNetEvent('quest_diarias:quest2:attemptDelivery')
    AddEventHandler('quest_diarias:quest2:attemptDelivery', function()
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
    
        -- no client-side inventory removal; delegate to server
        local Quest2 = Quest2
        TriggerServerEvent('quest_diarias:quest2:attemptDelivery', npcIdx)
    end)
    
    -- Cliente: sucesso da entrega da missão 2, concluir
    RegisterNetEvent('quest_diarias:quest2:deliverySuccess')
    AddEventHandler('quest_diarias:quest2:deliverySuccess', function()
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
        TriggerServerEvent('quest_diarias:completeQuest', Quest2.Config.id, npcIdx)
    end)
end

if IsDuplicityVersion() then
    -- Servidor: valida inventário, subtrai item e confirma sucesso
    local VorpCore = exports.vorp_core:GetCore()

    RegisterNetEvent('quest_diarias:quest2:attemptDelivery')
    AddEventHandler('quest_diarias:quest2:attemptDelivery', function(npcIndex)
        local _source = source
        local User = VorpCore.getUser(_source)
        if not User then return end
        local Character = User.getUsedCharacter
        if not Character then return end

        local identifier = Character.identifier
        local charid = Character.charIdentifier

        MySQL.Async.fetchAll('SELECT * FROM quest_diarias WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND status = @status', {
            ['@identifier'] = identifier,
            ['@charid'] = charid,
            ['@quest_id'] = Quest2.Config.id,
            ['@status'] = 'active'
        }, function(rows)
            if not rows or #rows == 0 then
                TriggerClientEvent('vorp:TipBottom', _source, 'Missão não encontrada ou não está ativa', 4000)
                return
            end

            local questRow = rows[1]
            local recordedNpcIndex = questRow.npc_index
            if recordedNpcIndex ~= nil and npcIndex ~= nil and tonumber(recordedNpcIndex) ~= tonumber(npcIndex) then
                TriggerClientEvent('vorp:TipBottom', _source, 'Entrega inválida: volte ao mesmo NPC que iniciou a missão.', 5000)
                return
            end
            if recordedNpcIndex == nil and npcIndex ~= nil then
                local npcName = (Config.NPCs and Config.NPCs[npcIndex] and Config.NPCs[npcIndex].name) or nil
                MySQL.Async.execute('UPDATE quest_diarias SET npc_index = @npc_index, npc_name = @npc_name WHERE id = @id', {
                    ['@npc_index'] = npcIndex,
                    ['@npc_name'] = npcName,
                    ['@id'] = questRow.id
                })
            end

            local itemName = Quest2.Config.delivery.requiredItem
            local count = exports.vorp_inventory:getItemCount(_source, nil, itemName, nil)
            if not count or tonumber(count) < 1 then
                local msg = (Quest2.Config.texts and Quest2.Config.texts.notDelivered) or 'Você ainda não tem a maçã. Volte quando conseguir uma.'
                TriggerClientEvent('vorp:TipBottom', _source, msg, 5000)
                return
            end

            local ok = exports.vorp_inventory:subItem(_source, itemName, 1)
            if ok then
                TriggerClientEvent('quest_diarias:quest2:deliverySuccess', _source)
            else
                TriggerClientEvent('vorp:TipBottom', _source, 'Não foi possível retirar a maçã do inventário.', 4000)
            end
        end)
    end)
end

-- Retorno apenas no servidor para compatibilidade com QuestManager
if IsDuplicityVersion() then return Quest2 end