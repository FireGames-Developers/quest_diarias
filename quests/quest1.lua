-- =========================================================================
-- Missão 1: Caça ao Faisão (Estrutura Modular)
-- =========================================================================
-- Estrutura com textos centralizados, eventos definidos e lógica isolada.
-- Permite reuso ao criar novas quests alterando apenas conteúdo.
-- =========================================================================

local Quest1 = {}

-- Configurações principais
Quest1.Config = {
    id = 1,
    name = "Caça ao Faisão",
    description = "Cace um faisão e traga a carcaça nas mãos para o NPC.",

    rewards = {
        money = 50,
        xp = 100,
        items = {
            -- { item = "bread", amount = 2 }
        }
    },

    markers = {
        huntingArea = {
            coords = vector3(-1200.0, 2400.0, 300.0),
            radius = 500.0,
            blip = {
                sprite = -1282792512,
                color = 3,
                name = "Área de Caça - Faisões"
            }
        }
    },

    delivery = {
        acceptedModels = {
            'A_C_PHEASANT_01',
            'P_FOXPHEASANT01X',
            'P_TAXIDERMYPHEASANT02X'
        }
    },

    texts = {
        start = "Vá até a área marcada e cace um faisão. Traga-o nas mãos para mim.",
        progress = "Objetivo: cace um faisão e traga a carcaça nas mãos.",
        complete = "Obrigada pela ajuda, estou com muita fome, vou preparar esse faisão e me alimentar",
        alreadyCompleted = ("Você já ajudou %s hoje. Volte amanhã para novas solicitações."):format(Config.NpcName or 'NPC'),
        notDelivered = "Você não me trouxe o faisão ainda, pegue o mais rápido possível pois estou com fome",
        deliverHint = "Entregue o faisão nas mãos para concluir a missão.",
        error = "Ocorreu um erro ao processar a missão."
    }
}

-- Eventos para integração
Quest1.Events = {
    attemptDelivery = 'quest_diarias:attemptDelivery',
    questStartedClient = 'quest_diarias:questStarted',
    questCompletedClient = 'quest_diarias:questCompleted'
}

-- Iniciar missão
function Quest1.StartQuest(source)
    local area = Quest1.Config.markers.huntingArea
    local blipData = {
        x = area.coords.x,
        y = area.coords.y,
        z = area.coords.z,
        sprite = Config.blipsprite,
        color = area.blip.color,
        name = area.blip.name
    }
    TriggerClientEvent('quest_diarias:createQuestBlip', source, Quest1.Config.id, blipData)
    TriggerClientEvent('vorp:TipBottom', source, Quest1.Config.texts.start, 6000)
    return true
end

-- Elegibilidade diária
function Quest1.CanDoQuest(source, callback)
    local VorpCore = exports.vorp_core:GetCore()
    local User = VorpCore.getUser(source)
    if not User then callback(false) return end
    local Character = User.getUsedCharacter
    if not Character then callback(false) return end

    local identifier = Character.identifier
    local charid = Character.charIdentifier

    exports.oxmysql:execute(
        'SELECT 1 FROM quest_diarias_history WHERE identifier = ? AND charid = ? AND quest_id = ? AND DATE(FROM_UNIXTIME(completed_at)) = CURDATE() LIMIT 1',
        {identifier, charid, Quest1.Config.id},
        function(rows)
            callback(not rows or #rows == 0)
        end
    )
end

-- Objetivos da missão (para /quest)
function Quest1.GetObjectives(progress)
    local objectives = {}
    table.insert(objectives, ('Missão: %s'):format(Quest1.Config.name))
    table.insert(objectives, Quest1.Config.description)
    table.insert(objectives, Quest1.Config.texts.progress)
    table.insert(objectives, Quest1.Config.texts.deliverHint)

    local status = (progress and progress.delivered) and 'Concluído' or 'Pendente'
    table.insert(objectives, ('Progresso: Entrega do faisão - %s'):format(status))

    local rewards = Quest1.Config.rewards
    if rewards then
        local items = {}
        if rewards.money and rewards.money > 0 then table.insert(items, ('$%d'):format(rewards.money)) end
        if rewards.xp and rewards.xp > 0 then table.insert(items, ('%d XP'):format(rewards.xp)) end
        if rewards.items and #rewards.items > 0 then table.insert(items, ('%d item(ns)'):format(#rewards.items)) end
        if #items > 0 then
            table.insert(objectives, ('Recompensas: %s'):format(table.concat(items, ', ')))
        end
    end

    return objectives
end

return Quest1