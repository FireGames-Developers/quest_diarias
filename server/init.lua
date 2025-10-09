-- Initialization Script - Sistema de Inicialização do Servidor
-- Desenvolvido por FTx3g

-- Aguardar o VORP Core estar pronto
local VorpCore = exports.vorp_core:GetCore()

-- Carregar módulos necessários
local Database = require('server.database')

-- Função de inicialização principal
local function Initialize()
    if Config.DevMode then
        print('========================================')
        print('    Quest Diarias - Sistema v2.0.0')
        print('    Desenvolvido por: FTx3g')
        print('========================================')
        print('[Init] Iniciando sistema de missões diárias...')
    end
    
    -- Inicializar o banco de dados
    Database.Initialize()
    
    if Config.DevMode then
        print('[Init] Sistema inicializado com sucesso!')
        print('[Init] Comandos disponíveis para admins:')
        print('[Init] • /questdb_status - Ver estatísticas do banco')
        print('[Init] • /questdb_cleanup - Limpeza manual do banco')
        print('========================================')
    end
end

-- Event quando o recurso é iniciado
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Aguardar um pouco para garantir que todas as dependências estão carregadas
        Citizen.SetTimeout(2000, function()
            Initialize()
        end)
    end
end)

-- Event quando o recurso é parado
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if Config.DevMode then
            print('[Init] Sistema de missões diárias finalizado')
        end
    end
end)

-- Verificação de saúde do sistema (executada a cada 30 minutos)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1800000) -- 30 minutos
        
        if Config.DevMode then
            Database.GetStats(function(stats)
                if stats then
                    print(('[Health Check] Sistema funcionando. Registros ativos: %d'):format(stats.total_records))
                else
                    print('[Health Check] Aviso: Não foi possível obter estatísticas do banco')
                end
            end)
        end
    end
end)