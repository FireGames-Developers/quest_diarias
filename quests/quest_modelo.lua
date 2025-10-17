-- =========================================================================
-- Quest Modelo: Estrutura Base para Criar Novas Missões
-- =========================================================================
-- Como usar:
-- 1) Duplique este arquivo para 'quests/questN.lua' (ex.: quest3.lua).
-- 2) Ajuste 'Quest.Config.id' para o número da sua missão.
-- 3) Preencha textos, recompensas e a forma de entrega (carregado nas mãos ou inventário).
-- 4) O menu chamará automaticamente o evento 'quest_diarias:quest<ID>:attemptDelivery'.
--    Este template registra dinamicamente esse evento com base no ID configurado.
-- =========================================================================

local Quest = {}

-- Configurações principais
Quest.Config = {
    id = 99, -- TODO: altere para o ID real da sua missão (número inteiro)
    name = "Minha Nova Missão",
    description = "Descreva aqui o objetivo principal da missão.",

    rewards = {
        money = 0,
        -- Exemplo: itens (opcional)
        items = {
            -- { item = "bread", amount = 1 }
        },
        -- Exemplo: arma (opcional)
        -- weapon = "WEAPON_REVOLVER_CATTLEMAN"
    },

    -- Forma de entrega (escolha UMA das opções abaixo)
    delivery = {
        -- Opção A: Entrega com item/carcaça nas mãos (modelos aceitos)
        -- acceptedModels = {
        --     'A_C_PHEASANT_01',
        --     'P_FOXPHEASANT01X'
        -- },

        -- Opção B: Entrega via inventário (nome do item)
        -- requiredItem = 'apple'
    },

    -- (Opcional) Marcadores no mapa/blip, se sua missão tiver uma área
    markers = {
        -- huntingArea = {
        --     coords = vector3(-1200.0, 2400.0, 300.0),
        --     radius = 300.0,
        --     blip = {
        --         sprite = -1282792512,
        --         color = 3,
        --         name = "Área da Missão"
        --     }
        -- }
    },

    texts = {
        start = "Orientação inicial da missão (mostrada ao aceitar).",
        progress = "Texto de progresso (o que o jogador deve fazer).",
        deliverHint = "Dica de como entregar (mãos ou inventário).",
        complete = "Mensagem de conclusão/reconhecimento.",
        alreadyCompleted = "Você já ajudou este NPC hoje. Volte amanhã para novas solicitações.",
        notDelivered = "Você ainda não trouxe o item solicitado.",
        error = "Ocorreu um erro ao processar a missão."
    }
}

-- Eventos para integração (padrão do sistema)
Quest.Events = {
    attemptDelivery = 'quest_diarias:attemptDelivery',
    questStartedClient = 'quest_diarias:questStarted',
    questCompletedClient = 'quest_diarias:questCompleted'
}

-- Iniciar missão: cria blip (se configurado) e mostra instruções
function Quest.StartQuest(source)
    local area = Quest.Config.markers and Quest.Config.markers.huntingArea
    if area then
        local blipData = {
            x = area.coords.x,
            y = area.coords.y,
            z = area.coords.z,
            sprite = Config.blipsprite or (area.blip and area.blip.sprite) or -1282792512,
            color = (area.blip and area.blip.color) or 3,
            name = (area.blip and area.blip.name) or Quest.Config.name
        }
        TriggerClientEvent('quest_diarias:createQuestBlip', source, Quest.Config.id, blipData)
    end
    if Quest.Config.texts and Quest.Config.texts.start then
        TriggerClientEvent('vorp:TipBottom', source, Quest.Config.texts.start, 6000)
    end
    return true
end

-- Objetivos (para /quest): descreve o que fazer e recompensas
function Quest.GetObjectives(progress)
    local objectives = {}
    table.insert(objectives, ('Missão: %s'):format(Quest.Config.name))
    table.insert(objectives, Quest.Config.description)
    table.insert(objectives, Quest.Config.texts.progress)
    table.insert(objectives, Quest.Config.texts.deliverHint)

    local status = (progress and progress.delivered) and 'Concluído' or 'Pendente'
    table.insert(objectives, ('Progresso: Entrega - %s'):format(status))

    local rewards = Quest.Config.rewards
    if rewards then
        local items = {}
        if rewards.money and rewards.money > 0 then table.insert(items, ('$%d'):format(rewards.money)) end
        if rewards.weapon then table.insert(items, 'Arma Especial') end
        if rewards.items and #rewards.items > 0 then table.insert(items, ('%d item(ns)'):format(#rewards.items)) end
        if #items > 0 then
            table.insert(objectives, ('Recompensas: %s'):format(table.concat(items, ', ')))
        end
    end

    return objectives
end

-- Teste da missão (para /quest_test)
-- Escolhe automaticamente um teste baseado na configuração de entrega:
-- - Se delivery.requiredItem estiver definido, dá o item ao jogador.
-- - Caso contrário, pode spawnar um animal/objeto próximo para teste.
function Quest.RunTest(source, params)
    local delivery = Quest.Config.delivery or {}

    if delivery.requiredItem then
        local itemName = delivery.requiredItem
        local canCarry = exports.vorp_inventory:canCarryItem(source, itemName, 1)
        if canCarry then
            exports.vorp_inventory:addItem(source, itemName, 1, nil, function(success)
                local msg = success and ('Você recebeu %s para teste.'):format(itemName)
                                    or ('Não foi possível adicionar %s ao inventário.'):format(itemName)
                TriggerClientEvent('vorp:TipBottom', source, msg, 6000)
            end)
        else
            TriggerClientEvent('vorp:TipBottom', source, 'Inventário cheio. Faça espaço para receber o item.', 6000)
        end
        return
    end

    -- Caso de modelos aceitos: envia payload para cliente spawnar um objeto/animal
    local payload = {
        action = 'spawnExample',
        model = (delivery.acceptedModels and delivery.acceptedModels[1]) or 'A_C_PHEASANT_01',
        distance = (params and params.distance) or 3.0,
        dead = true
    }
    TriggerClientEvent('quest_diarias:runMissionTest', source, Quest.Config.id, payload)
end

-- ========================================================================
-- CLIENTE: Registro de entrega por missão (usa fluxo genérico do sistema)
-- ========================================================================
if not IsDuplicityVersion() then
    local attemptEventName = ('quest_diarias:quest%d:attemptDelivery'):format(Quest.Config.id)

    RegisterNetEvent(attemptEventName)
    AddEventHandler(attemptEventName, function()
        -- Usa o fluxo genérico de entrega do sistema, que trata
        -- tanto inventário (requiredItem) quanto item nas mãos (acceptedModels)
        TriggerEvent('quest_diarias:attemptDelivery', Quest.Config.id)
    end)
end

-- Retorno apenas no servidor para compatibilidade com QuestManager
if IsDuplicityVersion() then return Quest end