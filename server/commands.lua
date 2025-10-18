-- =========================================================================
-- Comandos do Sistema de Missões Diárias
-- =========================================================================
-- Consolida: /quest (objetivos), /quest_list, /quest_reset, /quest_test
-- =========================================================================

local VorpCore = exports.vorp_core:GetCore()

-- Carregamento seguro do QuestManager via ModuleLoader
local QuestManager = nil
local function LoadQuestManager()
    if QuestManager then return QuestManager end
    QuestManager = ModuleLoader.LoadModule("modules/quest_manager.lua", "QuestManager")
    return QuestManager
end

-- =========================================================================
-- /quest - Exibe objetivos e informações da missão ativa
-- =========================================================================
RegisterCommand('quest', function(source, args, raw)
    local _source = source
    if _source == 0 then
        print('Este comando deve ser usado no jogo.')
        return
    end

    local User = VorpCore.getUser(_source)
    if not User then return end
    local Character = User.getUsedCharacter
    if not Character then return end

    local identifier = Character.identifier
    local charid = Character.charIdentifier

    -- Buscar missão ativa
    MySQL.Async.fetchAll('SELECT * FROM quest_diarias WHERE identifier = @identifier AND charid = @charid AND status = @status ORDER BY created_at DESC LIMIT 1', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@status'] = 'active'
    }, function(rows)
        if not rows or #rows == 0 then
            TriggerClientEvent('vorp:TipBottom', _source, 'Você não possui missão ativa no momento.', 5000)
            return
        end

        local active = rows[1]
        local questId = tonumber(active.quest_id)
        local progress = {}
        if active.progress and type(active.progress) == 'string' then
            local ok, decoded = pcall(json.decode, active.progress)
            if ok and decoded then progress = decoded end
        end

        local qm = LoadQuestManager()
        if not qm then
            TriggerClientEvent('vorp:TipBottom', _source, 'Erro ao carregar gerenciador de missões.', 5000)
            return
        end

        local quest = qm.GetQuest(questId)
        if not quest then
            TriggerClientEvent('vorp:TipBottom', _source, ('Missão %s não encontrada.'):format(tostring(questId)), 5000)
            return
        end

        -- Resumo conciso da missão
        local info = qm.GetQuestInfo(questId)
        local name = info and info.name or ('Missão '..tostring(questId))
        local desc = info and info.description or ''
        local status = 'Pendente'
        if progress and progress.delivered then status = 'Concluída' end
        local summary = ('%s\n%s\nStatus: %s'):format(name, desc, status)
        TriggerClientEvent('vorp:TipBottom', _source, summary, 5000)
    end)
end, false)

-- =========================================================================
-- /quest_list - Lista últimas quests do personagem
-- =========================================================================
RegisterCommand('quest_list', function(source, args, rawCommand)
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

    MySQL.Async.fetchAll('SELECT * FROM quest_diarias WHERE identifier = @identifier AND charid = @charid ORDER BY created_at DESC LIMIT 10', {
        ['@identifier'] = identifier,
        ['@charid'] = charid
    }, function(result)
        if result and #result > 0 then
            TriggerClientEvent('vorp:TipBottom', _source, "Suas quests:", 5000)
            for _, quest in pairs(result) do
                local status = quest.status == 'active' and "Ativa" or "Completada"
                TriggerClientEvent('vorp:TipBottom', _source, quest.quest_id .. " - " .. status, 5000)
            end
        else
            TriggerClientEvent('vorp:TipBottom', _source, "Você não possui quests", 5000)
        end
    end)
end, false)

-- =========================================================================
-- /quest_reset - Reseta conclusão do dia para uma missão
-- =========================================================================
local function ExecuteQuestReset(_source, identifier, charid, questId)
    MySQL.Async.execute('DELETE FROM quest_diarias_history WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND DATE(FROM_UNIXTIME(completed_at)) = CURDATE()', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId
    }, function(histDeleted)
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
            TriggerClientEvent('vorp:TipBottom', _source, msg, 5000)
        end)
    end)
end

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

    if not questId then
        MySQL.Async.fetchAll('SELECT quest_id FROM quest_diarias_history WHERE identifier = @identifier AND charid = @charid AND DATE(completed_at) = CURDATE() ORDER BY completed_at DESC LIMIT 1', {
            ['@identifier'] = identifier,
            ['@charid'] = charid
        }, function(rows)
            if rows and rows[1] and rows[1].quest_id then
                questId = tonumber(rows[1].quest_id)
            end
            if not questId then
                TriggerClientEvent('vorp:TipBottom', _source, 'Nenhuma missão completada hoje encontrada para reset', 5000)
                return
            end
            ExecuteQuestReset(_source, identifier, charid, questId)
        end)
    else
        ExecuteQuestReset(_source, identifier, charid, questId)
    end
end, false)

-- =========================================================================
-- /quest_test - Comando de teste para spawnar faisão morto
-- =========================================================================
RegisterCommand('quest_test', function(source, args, raw)
    local _source = source

    if _source == 0 then
        print('Este comando deve ser usado no jogo.')
        return
    end

    if not IsPlayerAceAllowed(_source, 'command.quest_test') then
        TriggerClientEvent('vorp:TipBottom', _source, 'Você não tem permissão para este comando', 5000)
        return
    end

    local User = VorpCore.getUser(_source)
    if not User then return end
    local Character = User.getUsedCharacter
    if not Character then return end

    local distance = tonumber(args and args[1]) or 3.0

    local qm = LoadQuestManager()
    if not qm then
        TriggerClientEvent('vorp:TipBottom', _source, 'Erro ao carregar gerenciador de missões.', 5000)
        return
    end

    local questId = tonumber(args and args[2]) or (Config and Config.mission) or 1
    local quest = qm.GetQuest(questId)
    if not quest then
        TriggerClientEvent('vorp:TipBottom', _source, ('Missão %s não encontrada para teste.'):format(tostring(questId)), 5000)
        return
    end

    if quest.RunTest and type(quest.RunTest) == 'function' then
        quest.RunTest(_source, { distance = distance, dead = true })
        TriggerClientEvent('vorp:TipBottom', _source, ('Teste da missão %d executado (distância %.1fm)'):format(questId, distance), 5000)
    else
        TriggerClientEvent('vorp:TipBottom', _source, 'Esta missão não possui rotina de teste configurada.', 5000)
    end
end, false)