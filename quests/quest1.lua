-- Missão 1: Caça ao Faisão
-- Desenvolvido por FTx3g

Quest1 = {}

-- Configurações da Missão
Quest1.Config = {
    id = 1,
    name = "Caça ao Faisão",
    description = "Caçar um faisão e trazer sua carcaça para o NPC",
    
    -- Item necessário para completar a missão
    requiredItem = "carcass_pheasant_perfect", -- Item da carcaça do faisão
    requiredAmount = 1,
    
    -- Recompensas
    rewards = {
        money = 50,
        xp = 100,
        items = {
            -- { item = "bread", amount = 2 }
        }
    },
    
    -- Marcadores no mapa
    markers = {
        huntingArea = {
            coords = vector3(-1200.0, 2400.0, 300.0),
            radius = 500.0,
            blip = {
                sprite = -1282792512, -- Sprite de caça
                color = 3,
                name = "Área de Caça - Faisões"
            }
        }
    },
    
    -- Textos da missão
    texts = {
        start = "Vá até a área marcada no mapa e caçar um faisão. Traga a carcaça de volta para mim.",
        progress = "Você precisa caçar um faisão na área marcada.",
        complete = "Excelente trabalho! Aqui está sua recompensa.",
        alreadyCompleted = ("Você já ajudou %s hoje. Volte amanhã para novas solicitações."):format(Config.NpcName or 'NPC'),
        noItem = "Você não tem a carcaça do faisão necessária.",
        error = "Ocorreu um erro ao processar a missão."
    }
}

-- Função para verificar se o jogador tem o item necessário
function Quest1.HasRequiredItem(source)
    local User = exports.vorp_core:GetUser(source)
    if not User then return false end
    
    local Character = User.getUsedCharacter
    if not Character then return false end
    
    -- Verificar se o jogador tem o item no inventário
    local hasItem = exports.vorp_inventory:getItem(source, Quest1.Config.requiredItem)
    return hasItem and hasItem.count >= Quest1.Config.requiredAmount
end

-- Função para remover o item do inventário
function Quest1.RemoveRequiredItem(source)
    exports.vorp_inventory:subItem(source, Quest1.Config.requiredItem, Quest1.Config.requiredAmount)
end

-- Função para dar recompensas
function Quest1.GiveRewards(source)
    local User = exports.vorp_core:GetUser(source)
    if not User then return false end
    
    local Character = User.getUsedCharacter
    if not Character then return false end
    
    -- Dar dinheiro
    if Quest1.Config.rewards.money > 0 then
        Character.addCurrency(0, Quest1.Config.rewards.money) -- 0 = dinheiro
    end
    
    -- Dar XP (se aplicável)
    if Quest1.Config.rewards.xp > 0 then
        -- Implementar sistema de XP se necessário
    end
    
    -- Dar itens
    for _, reward in pairs(Quest1.Config.rewards.items) do
        exports.vorp_inventory:addItem(source, reward.item, reward.amount)
    end
    
    return true
end

-- Função para iniciar a missão
function Quest1.StartQuest(source)
    -- Criar blip da área de caça
    local area = Quest1.Config.markers.huntingArea
    local blipData = { x = area.coords.x, y = area.coords.y, z = area.coords.z, sprite = Config.blipsprite, color = area.blip.color, name = area.blip.name }
    TriggerClientEvent('quest_diarias:createQuestBlip', source, Quest1.Config.id, blipData)
    
    -- Notificar o jogador
    TriggerClientEvent('vorp:TipBottom', source, Quest1.Config.texts.start, 5000)
    
    return true
end

-- Função para completar a missão
function Quest1.CompleteQuest(source)
    -- Verificar se o jogador tem o item
    if not Quest1.HasRequiredItem(source) then
        TriggerClientEvent('vorp:TipBottom', source, Quest1.Config.texts.noItem, 3000)
        return false
    end
    
    -- Verificar se já completou hoje
    local identifier = GetPlayerIdentifier(source, 0)
    exports.oxmysql:execute('SELECT * FROM daily_quests WHERE identifier = ? AND quest_id = ? AND DATE(completed_at) = CURDATE()', 
        {identifier, Quest1.Config.id}, function(result)
        if result and #result > 0 then
            TriggerClientEvent('vorp:TipBottom', source, Quest1.Config.texts.alreadyCompleted, 3000)
            return false
        end
        
        -- Remover item do inventário
        Quest1.RemoveRequiredItem(source)
        
        -- Dar recompensas
        if Quest1.GiveRewards(source) then
            -- Registrar conclusão no banco
            exports.oxmysql:execute('INSERT INTO daily_quests (identifier, quest_id, completed_at) VALUES (?, ?, NOW())', 
                {identifier, Quest1.Config.id})
            
            -- Remover blip da área de caça
            TriggerClientEvent('quest_diarias:removeQuestBlip', source, Quest1.Config.id)
            
            -- Notificar sucesso
            TriggerClientEvent('vorp:TipBottom', source, Quest1.Config.texts.complete, 3000)
            return true
        else
            TriggerClientEvent('vorp:TipBottom', source, Quest1.Config.texts.error, 3000)
            return false
        end
    end)
end

-- Função para verificar se pode fazer a missão
function Quest1.CanDoQuest(source, callback)
    local identifier = GetPlayerIdentifier(source, 0)
    exports.oxmysql:execute('SELECT * FROM daily_quests WHERE identifier = ? AND quest_id = ? AND DATE(completed_at) = CURDATE()', 
        {identifier, Quest1.Config.id}, function(result)
        callback(not result or #result == 0)
    end)
end

return Quest1