-- ============================================================================
-- TESTE DE MISSÃO (SERVIDOR)
-- ============================================================================
-- Comando: /quest_test (restrito via ACE)
-- Ajustado para: apenas solicitar o spawn de um faisão "morto"
-- à frente do jogador, sem dar arma ou munição.
-- ============================================================================

local VorpCore = exports.vorp_core:GetCore()

RegisterCommand('quest_test', function(source, args, raw)
    local _source = source

    if _source == 0 then
        print('Este comando deve ser usado no jogo.')
        return
    end

    if not IsPlayerAceAllowed(_source, 'command.quest_test') then
        VorpCore.NotifyRightTip(_source, 'Você não tem permissão para este comando', 4000)
        return
    end

    local User = VorpCore.getUser(_source)
    if not User then return end
    local Character = User.getUsedCharacter
    if not Character then return end

    -- Distância opcional via argumento: /quest_test 3.0
    local distance = tonumber(args and args[1]) or 3.0

    -- Solicitar ao cliente que spawne um faisão morto à frente do jogador
    TriggerClientEvent('quest_diarias:testMission:spawnPheasant', _source, distance, true)
    VorpCore.NotifyRightTip(_source, ('Faisão morto será spawnado a %.1fm à frente'):format(distance), 4000)
end, false)