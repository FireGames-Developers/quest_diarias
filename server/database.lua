-- Database Manager - Sistema de Inicialização Automática do Banco
-- Desenvolvido por FTx3g

local Database = {}

-- Função para criar as tabelas necessárias
function Database.CreateTables()
    if Config.DevMode then
        print('[Database] Verificando e criando tabelas necessárias...')
    end
    
    -- Criar tabela daily_quests
    local createTableQuery = [[
        CREATE TABLE IF NOT EXISTS `daily_quests` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(50) NOT NULL,
            `quest_id` int(11) NOT NULL,
            `completed_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_identifier_quest` (`identifier`, `quest_id`),
            KEY `idx_completed_at` (`completed_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    
    exports.oxmysql:execute(createTableQuery, {}, function(result)
        if Config.DevMode then
            print('[Database] Tabela daily_quests verificada/criada com sucesso')
        end
        
        -- Após criar a tabela, configurar o evento de limpeza
        Database.CreateCleanupEvent()
    end)
end

-- Função para criar o evento de limpeza automática
function Database.CreateCleanupEvent()
    if Config.DevMode then
        print('[Database] Configurando evento de limpeza automática...')
    end
    
    -- Verificar se o evento já existe
    local checkEventQuery = [[
        SELECT COUNT(*) as count 
        FROM information_schema.EVENTS 
        WHERE EVENT_SCHEMA = DATABASE() 
        AND EVENT_NAME = 'cleanup_daily_quests'
    ]]
    
    exports.oxmysql:execute(checkEventQuery, {}, function(result)
        if result and result[1] and result[1].count == 0 then
            -- Evento não existe, criar
            local createEventQuery = [[
                CREATE EVENT IF NOT EXISTS `cleanup_daily_quests`
                ON SCHEDULE EVERY 1 DAY
                STARTS CURRENT_TIMESTAMP
                DO DELETE FROM `daily_quests` 
                WHERE `completed_at` < DATE_SUB(NOW(), INTERVAL 30 DAY)
            ]]
            
            exports.oxmysql:execute(createEventQuery, {}, function(eventResult)
                if Config.DevMode then
                    print('[Database] Evento de limpeza automática criado com sucesso')
                    print('[Database] Registros serão limpos automaticamente após 30 dias')
                end
            end)
        else
            if Config.DevMode then
                print('[Database] Evento de limpeza automática já existe')
            end
        end
    end)
end

-- Função para verificar se as tabelas existem
function Database.CheckTables(callback)
    local checkQuery = [[
        SELECT COUNT(*) as count 
        FROM information_schema.TABLES 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'daily_quests'
    ]]
    
    exports.oxmysql:execute(checkQuery, {}, function(result)
        if result and result[1] then
            local exists = result[1].count > 0
            if Config.DevMode then
                print(('[Database] Tabela daily_quests %s'):format(exists and 'existe' or 'não existe'))
            end
            callback(exists)
        else
            callback(false)
        end
    end)
end

-- Função para inicializar o banco de dados
function Database.Initialize()
    if Config.DevMode then
        print('[Database] Inicializando sistema de banco de dados...')
    end
    
    -- Aguardar um pouco para garantir que o oxmysql está pronto
    Citizen.Wait(1000)
    
    -- Verificar se as tabelas existem e criar se necessário
    Database.CheckTables(function(exists)
        if not exists then
            if Config.DevMode then
                print('[Database] Tabelas não encontradas, criando automaticamente...')
            end
            Database.CreateTables()
        else
            if Config.DevMode then
                print('[Database] Tabelas já existem, verificando evento de limpeza...')
            end
            Database.CreateCleanupEvent()
        end
        
        if Config.DevMode then
            print('[Database] Sistema de banco de dados inicializado com sucesso!')
        end
    end)
end

-- Função para executar limpeza manual (opcional)
function Database.ManualCleanup()
    local cleanupQuery = [[
        DELETE FROM `daily_quests` 
        WHERE `completed_at` < DATE_SUB(NOW(), INTERVAL 30 DAY)
    ]]
    
    exports.oxmysql:execute(cleanupQuery, {}, function(result)
        if Config.DevMode then
            print(('[Database] Limpeza manual executada. Registros removidos: %d'):format(result.affectedRows or 0))
        end
    end)
end

-- Função para obter estatísticas do banco
function Database.GetStats(callback)
    local statsQuery = [[
        SELECT 
            COUNT(*) as total_records,
            COUNT(DISTINCT identifier) as unique_players,
            COUNT(DISTINCT quest_id) as different_quests,
            DATE(MIN(completed_at)) as oldest_record,
            DATE(MAX(completed_at)) as newest_record
        FROM `daily_quests`
    ]]
    
    exports.oxmysql:execute(statsQuery, {}, function(result)
        if result and result[1] then
            callback(result[1])
        else
            callback(nil)
        end
    end)
end

-- Comando para administradores verificarem o status do banco
RegisterCommand('questdb_status', function(source, args, rawCommand)
    local user = exports.vorp_core:GetCore().getUser(source)
    if not user then return end
    
    local character = user.getUsedCharacter
    if not character then return end
    
    -- Verificar se é admin (você pode ajustar esta verificação conforme seu sistema)
    if character.group ~= 'admin' then
        TriggerClientEvent('vorp:TipBottom', source, 'Você não tem permissão para usar este comando', 3000)
        return
    end
    
    Database.GetStats(function(stats)
        if stats then
            local message = string.format(
                'Status do Banco de Dados Quest Diarias:\n' ..
                '• Total de registros: %d\n' ..
                '• Jogadores únicos: %d\n' ..
                '• Missões diferentes: %d\n' ..
                '• Registro mais antigo: %s\n' ..
                '• Registro mais recente: %s',
                stats.total_records,
                stats.unique_players,
                stats.different_quests,
                stats.oldest_record or 'N/A',
                stats.newest_record or 'N/A'
            )
            TriggerClientEvent('vorp:TipBottom', source, message, 10000)
        else
            TriggerClientEvent('vorp:TipBottom', source, 'Erro ao obter estatísticas do banco', 3000)
        end
    end)
end, false)

-- Comando para limpeza manual
RegisterCommand('questdb_cleanup', function(source, args, rawCommand)
    local user = exports.vorp_core:GetCore().getUser(source)
    if not user then return end
    
    local character = user.getUsedCharacter
    if not character then return end
    
    -- Verificar se é admin
    if character.group ~= 'admin' then
        TriggerClientEvent('vorp:TipBottom', source, 'Você não tem permissão para usar este comando', 3000)
        return
    end
    
    Database.ManualCleanup()
    TriggerClientEvent('vorp:TipBottom', source, 'Limpeza manual do banco executada', 3000)
end, false)

return Database