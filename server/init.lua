-- Inicialização do Sistema de Missões Diárias
-- Desenvolvido por FTx3g

-- Aguardar VORP Core estar pronto
Citizen.CreateThread(function()
    while not exports.vorp_core:GetCore() do
        Citizen.Wait(100)
    end
    
    if Config.DevMode then
        print('[Quest Diarias] VORP Core carregado, inicializando sistema...')
    end
    
    -- Carregar módulo de database
    local Database = require('server.database')
    
    -- Carregar módulo de auto-update
    local Updater = require('server.updater')
    
    -- Inicializar database
    Database.Initialize()
    
    -- Inicializar sistema de auto-update
    Updater.Initialize()
    
    if Config.DevMode then
        print('[Quest Diarias] Sistema inicializado com sucesso!')
        print('[Quest Diarias] Comandos administrativos disponíveis:')
        print('[Quest Diarias] - /questdb_status (verificar status do banco)')
        print('[Quest Diarias] - /questdb_cleanup (limpeza manual)')
        print('[Quest Diarias] - /quest_checkupdate (verificar atualizações)')
        print('[Quest Diarias] - /quest_update (detalhes da atualização)')
    end
    
    -- Health check a cada 30 minutos
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1800000) -- 30 minutos
            
            if Config.DevMode then
                Database.GetStats(function(stats)
                    print(('[Quest Diarias] Health Check - Total de registros: %d'):format(stats.totalRecords))
                end)
            end
        end
    end)
end)