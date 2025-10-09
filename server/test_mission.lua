-- ============================================================================
-- TESTE DE MISSÃO (SERVIDOR)
-- ============================================================================
-- Comando: /test_mission (restrito via ACE)
-- 1) Verifica munição de REVÓLVER do jogador; se < 10, dá um Cattleman
-- 2) Solicita spawn de faisão no cliente
-- ============================================================================

local VorpCore = exports.vorp_core:GetCore()
local inventory = exports.vorp_inventory

-- Soma total de munições de REVÓLVER (chaves que contenham 'REVOLVER')
local function GetTotalRevolverAmmo(source)
    local ammo = inventory:getUserAmmo(source)
    local total = 0
    if type(ammo) == 'table' then
        for key, value in pairs(ammo) do
            if type(key) == 'string' and string.find(string.upper(key), 'REVOLVER', 1, true) then
                total = total + (tonumber(value) or 0)
            end
        end
    end
    return total
end

RegisterCommand('test_mission', function(source, args, raw)
    local _source = source

    if _source == 0 then
        print('Este comando deve ser usado no jogo.')
        return
    end

    if not IsPlayerAceAllowed(_source, 'command.test_mission') then
        VorpCore.NotifyRightTip(_source, 'Você não tem permissão para este comando', 4000)
        return
    end

    local User = VorpCore.getUser(_source)
    if not User then return end
    local Character = User.getUsedCharacter
    if not Character then return end

    -- 1) Verificar munição de REVÓLVER
    local totalRevolverAmmo = GetTotalRevolverAmmo(_source)

    -- 2) Dar Cattleman se munição < 10 (validar capacidade)
    if totalRevolverAmmo < 10 then
        local canCarry = inventory:canCarryWeapons(_source, 1, nil, 'WEAPON_REVOLVER_CATTLEMAN')
        if not canCarry then
            VorpCore.NotifyRightTip(_source, 'Inventário não comporta um revólver', 4000)
        else
            inventory:createWeapon(_source, 'WEAPON_REVOLVER_CATTLEMAN')
            VorpCore.NotifyRightTip(_source, 'Revólver Cattleman fornecido para testes', 4000)
        end
    else
        VorpCore.NotifyRightTip(_source, ('Munição de revólver suficiente: %d'):format(totalRevolverAmmo), 4000)
    end

    -- 3) Spawnear faisão no cliente
    TriggerClientEvent('quest_diarias:testMission:spawnPheasant', _source, 6.0)
end, false)