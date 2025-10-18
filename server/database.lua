-- ============================================================================
-- QUEST DIÁRIAS - MÓDULO DE BANCO DE DADOS
-- ============================================================================
-- Este módulo gerencia todas as operações de banco de dados para o sistema
-- de quests diárias, incluindo criação de tabelas, consultas e atualizações.
-- 
-- DEPENDÊNCIA DO VORP CORE: Este módulo utiliza o padrão de retorno de módulo
-- compatível com LoadResourceFile, evitando problemas de dependência circular
-- com o sistema require() do FiveM/RedM.
-- ============================================================================

local Database = {}

-- ============================================================================
-- CONFIGURAÇÕES DE BANCO DE DADOS
-- ============================================================================

-- Configurações das tabelas
Database.tables = {
    quest_diarias = {
        name = "quest_diarias",
        columns = {
            "id INT AUTO_INCREMENT PRIMARY KEY",
            "identifier VARCHAR(50) NOT NULL",
            "charid INT NOT NULL",
            "quest_id VARCHAR(100) NOT NULL",
            "status ENUM('active', 'completed', 'failed') DEFAULT 'active'",
            "progress TEXT",
            "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
            "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP",
            "completed_at TIMESTAMP NULL",
            "npc_index INT NULL",
            "npc_name VARCHAR(100) NULL"
        },
        indexes = {
            "INDEX idx_identifier_charid (identifier, charid)",
            "INDEX idx_quest_id (quest_id)",
            "INDEX idx_status (status)",
            "INDEX idx_created_at (created_at)"
        }
    },
    quest_diarias_history = {
        name = "quest_diarias_history",
        columns = {
            "id INT AUTO_INCREMENT PRIMARY KEY",
            "identifier VARCHAR(50) NOT NULL",
            "charid INT NOT NULL",
            "quest_id VARCHAR(100) NOT NULL",
            "completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
            "rewards_given TEXT",
            "npc_index INT NULL",
            "npc_name VARCHAR(100) NULL"
        },
        indexes = {
            "INDEX idx_identifier_charid (identifier, charid)",
            "INDEX idx_quest_id (quest_id)",
            "INDEX idx_completed_at (completed_at)"
        }
    }
}

-- ============================================================================
-- SHIM DE COMPATIBILIDADE COM OXMYSQL
-- ==========================================================================
-- Quando o global MySQL (mysql-async) não estiver disponível, mas o recurso
-- oxmysql estiver carregado, criamos um adaptador para expor MySQL.Async com
-- as funções fetchAll e execute, convertendo parâmetros nomeados (@param)
-- para posicionais (?) compatíveis com oxmysql.
-- ==========================================================================

local function __toPositional(query, params)
    local ordered = {}
    -- Suporta underscores em nomes de parâmetros (ex.: @quest_id)
    local newQuery = query:gsub("@([%w_]+)", function(key)
        local val = params['@' .. key]
        if val == nil then
            val = params[key]
        end
        ordered[#ordered + 1] = val
        return '?'
    end)
    return newQuery, ordered
end

function Database.SetupAdapter()
    if MySQL and MySQL.Async then
        return true
    end

    local ok, ox = pcall(function()
        return exports and exports.oxmysql
    end)

    if ok and ox then
        MySQL = {
            Async = {
                fetchAll = function(query, params, cb)
                    local q, p = __toPositional(query, params or {})
                    ox:query(q, p, function(result)
                        if cb then cb(result) end
                    end)
                end,
                execute = function(query, params, cb)
                    local q, p = __toPositional(query, params or {})
                    ox:execute(q, p, function(affected)
                        if cb then cb(affected) end
                    end)
                end
            }
        }
        print("^2[QUEST DIÁRIAS]^0 ✓ Adaptador oxmysql habilitado (MySQL.Async compatível)")
        return true
    end

    return false
end

-- ============================================================================
-- FUNÇÕES DE INICIALIZAÇÃO
-- ============================================================================

-- Função para criar uma tabela se ela não existir
function Database.CreateTable(tableName, tableConfig)
    local columns = table.concat(tableConfig.columns, ", ")
    local indexes = tableConfig.indexes and table.concat(tableConfig.indexes, ", ") or ""
    
    local query = string.format([[
        CREATE TABLE IF NOT EXISTS %s (
            %s%s
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]], tableName, columns, indexes ~= "" and ", " .. indexes or "")
    
    MySQL.Async.execute(query, {}, function(result)
        if result then
            print(string.format("^2[QUEST DIÁRIAS]^0 ✓ Tabela '%s' verificada/criada com sucesso", tableName))
        else
            print(string.format("^1[QUEST DIÁRIAS]^0 ✗ Erro ao criar tabela '%s'", tableName))
        end
    end)
end

-- Função para inicializar todas as tabelas
function Database.Initialize()
    print("^3[QUEST DIÁRIAS]^0 Inicializando banco de dados...")
    Database.SetupAdapter()
    if not MySQL or not MySQL.Async then
        print("^1[QUEST DIÁRIAS]^0 ✗ Erro: MySQL/oxmysql não está disponível")
        return false
    end

    -- Definição local: cria colunas ausentes automaticamente
    local function ensureColumns(tableName, colsDef)
        local schemaQuery = [[
            SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @table
        ]]
        MySQL.Async.fetchAll(schemaQuery, { ['@table'] = tableName }, function(result)
            local existing = {}
            for _, row in ipairs(result or {}) do
                existing[row.COLUMN_NAME] = true
            end
            local alters = {}
            for col, def in pairs(colsDef or {}) do
                if not existing[col] then
                    table.insert(alters, string.format("ADD COLUMN %s %s", col, def))
                end
            end
            if #alters > 0 then
                local alterStmt = string.format("ALTER TABLE %s %s", tableName, table.concat(alters, ", "))
                MySQL.Async.execute(alterStmt, {}, function(_)
                    print(string.format("^2[QUEST DIÁRIAS]^0 ✓ Tabela '%s' atualizada: %s", tableName, table.concat(alters, ", ")))
                end)
            end
        end)
    end

    for tableName, tableConfig in pairs(Database.tables) do
        Database.CreateTable(tableName, tableConfig)
    end
    -- Garantir colunas extras (npc_index, npc_name) mesmo em bases já existentes
    ensureColumns("quest_diarias", { npc_index = "INT NULL", npc_name = "VARCHAR(100) NULL" })
    ensureColumns("quest_diarias_history", { npc_index = "INT NULL", npc_name = "VARCHAR(100) NULL" })
    print("^2[QUEST DIÁRIAS]^0 ✓ Inicialização do banco de dados concluída")
    return true
end

-- ============================================================================
-- FUNÇÕES DE CONSULTA - QUESTS ATIVAS
-- ============================================================================

-- Busca quest ativa do jogador
function Database.GetActiveQuest(identifier, charid, callback)
    MySQL.Async.fetchAll('SELECT * FROM quest_diarias WHERE identifier = @identifier AND charid = @charid AND status = @status', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@status'] = 'active'
    }, function(result)
        if callback then
            callback(result and result[1] or nil)
        end
    end)
end

-- Busca todas as quests do jogador
function Database.GetPlayerQuests(identifier, charid, callback)
    MySQL.Async.fetchAll('SELECT * FROM quest_diarias WHERE identifier = @identifier AND charid = @charid ORDER BY created_at DESC', {
        ['@identifier'] = identifier,
        ['@charid'] = charid
    }, function(result)
        if callback then
            callback(result or {})
        end
    end)
end

-- Busca quest específica do jogador
function Database.GetPlayerQuest(identifier, charid, questId, callback)
    MySQL.Async.fetchAll('SELECT * FROM quest_diarias WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId
    }, function(result)
        if callback then
            callback(result and result[1] or nil)
        end
    end)
end

-- ============================================================================
-- FUNÇÕES DE MANIPULAÇÃO - QUESTS
-- ============================================================================

-- Cria uma nova quest
function Database.CreateQuest(identifier, charid, questId, callback)
    MySQL.Async.execute('INSERT INTO quest_diarias (identifier, charid, quest_id, status, progress, created_at) VALUES (@identifier, @charid, @quest_id, @status, @progress, @created_at)', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId,
        ['@status'] = 'active',
        ['@progress'] = json.encode({}),
        ['@created_at'] = os.time()
    }, function(insertId)
        if callback then
            callback(insertId and insertId > 0)
        end
    end)
end

-- Atualiza progresso da quest
function Database.UpdateQuestProgress(identifier, charid, questId, progress, callback)
    MySQL.Async.execute('UPDATE quest_diarias SET progress = @progress, updated_at = @updated_at WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND status = @status', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId,
        ['@status'] = 'active',
        ['@progress'] = json.encode(progress),
        ['@updated_at'] = os.time()
    }, function(affectedRows)
        local affected = type(affectedRows) == 'number' and affectedRows or ((type(affectedRows) == 'table' and (affectedRows.affectedRows or affectedRows.changedRows or affectedRows.insertId)) or 0)
        if callback then
            callback(affected > 0)
        end
    end)
end

-- Completa uma quest
function Database.CompleteQuest(identifier, charid, questId, callback)
    MySQL.Async.execute('UPDATE quest_diarias SET status = @status, completed_at = @completed_at WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND status = @active_status', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId,
        ['@status'] = 'completed',
        ['@completed_at'] = os.time(),
        ['@active_status'] = 'active'
    }, function(affectedRows)
        local affected = type(affectedRows) == 'number' and affectedRows or ((type(affectedRows) == 'table' and (affectedRows.affectedRows or affectedRows.changedRows or affectedRows.insertId)) or 0)
        if callback then
            callback(affected > 0)
        end
    end)
end

-- Falha uma quest
function Database.FailQuest(identifier, charid, questId, callback)
    MySQL.Async.execute('UPDATE quest_diarias SET status = @status, updated_at = @updated_at WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND status = @active_status', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId,
        ['@status'] = 'failed',
        ['@updated_at'] = os.time(),
        ['@active_status'] = 'active'
    }, function(affectedRows)
        local affected = type(affectedRows) == 'number' and affectedRows or ((type(affectedRows) == 'table' and (affectedRows.affectedRows or affectedRows.changedRows or affectedRows.insertId)) or 0)
        if callback then
            callback(affected > 0)
        end
    end)
end

-- ============================================================================
-- FUNÇÕES DE HISTÓRICO
-- ============================================================================

-- Adiciona entrada no histórico
function Database.AddToHistory(identifier, charid, questId, rewards, callback)
    MySQL.Async.execute('INSERT INTO quest_diarias_history (identifier, charid, quest_id, completed_at, rewards_given) VALUES (@identifier, @charid, @quest_id, @completed_at, @rewards_given)', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId,
        ['@completed_at'] = os.time(),
        ['@rewards_given'] = json.encode(rewards or {})
    }, function(insertId)
        if callback then
            callback(insertId and insertId > 0)
        end
    end)
end

-- Busca histórico do jogador
function Database.GetPlayerHistory(identifier, charid, limit, callback)
    local limitClause = limit and limit > 0 and limit or 50
    MySQL.Async.fetchAll('SELECT * FROM quest_diarias_history WHERE identifier = @identifier AND charid = @charid ORDER BY completed_at DESC LIMIT @limit', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@limit'] = limitClause
    }, function(result)
        if callback then
            callback(result or {})
        end
    end)
end

-- Verifica se o jogador já completou uma quest hoje
function Database.HasCompletedQuestToday(identifier, charid, questId, callback)
    local today = os.date("%Y-%m-%d")
    MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM quest_diarias_history WHERE identifier = @identifier AND charid = @charid AND quest_id = @quest_id AND DATE(FROM_UNIXTIME(completed_at)) = @today', {
        ['@identifier'] = identifier,
        ['@charid'] = charid,
        ['@quest_id'] = questId,
        ['@today'] = today
    }, function(result)
        if callback then
            local count = result and result[1] and result[1].count or 0
            callback(count > 0)
        end
    end)
end

-- ============================================================================
-- FUNÇÕES DE LIMPEZA E MANUTENÇÃO
-- ============================================================================

-- Remove quests antigas (mais de X dias)
function Database.CleanupOldQuests(daysOld, callback)
    daysOld = daysOld or 30 -- Padrão: 30 dias
    local cutoffTime = os.time() - (daysOld * 24 * 60 * 60)
    
    MySQL.Async.execute('DELETE FROM quest_diarias WHERE status IN (@completed, @failed) AND updated_at < @cutoff_time', {
        ['@completed'] = 'completed',
        ['@failed'] = 'failed',
        ['@cutoff_time'] = cutoffTime
    }, function(affectedRows)
        if callback then
            callback(affectedRows or 0)
        end
        print(string.format("^3[QUEST DIÁRIAS]^0 Limpeza: %d quests antigas removidas", affectedRows or 0))
    end)
end

-- Remove histórico antigo (mais de X dias)
function Database.CleanupOldHistory(daysOld, callback)
    daysOld = daysOld or 90 -- Padrão: 90 dias
    local cutoffTime = os.time() - (daysOld * 24 * 60 * 60)
    
    MySQL.Async.execute('DELETE FROM quest_diarias_history WHERE completed_at < @cutoff_time', {
        ['@cutoff_time'] = cutoffTime
    }, function(affectedRows)
        if callback then
            callback(affectedRows or 0)
        end
        print(string.format("^3[QUEST DIÁRIAS]^0 Limpeza: %d entradas de histórico antigas removidas", affectedRows or 0))
    end)
end

-- ============================================================================
-- FUNÇÕES DE ESTATÍSTICAS
-- ============================================================================

-- Obtém estatísticas gerais do sistema
function Database.GetSystemStats(callback)
    MySQL.Async.fetchAll([[
        SELECT 
            (SELECT COUNT(*) FROM quest_diarias WHERE status = 'active') as active_quests,
            (SELECT COUNT(*) FROM quest_diarias WHERE status = 'completed') as completed_quests,
            (SELECT COUNT(*) FROM quest_diarias WHERE status = 'failed') as failed_quests,
            (SELECT COUNT(*) FROM quest_diarias_history) as total_history,
            (SELECT COUNT(DISTINCT identifier) FROM quest_diarias) as unique_players
    ]], {}, function(result)
        if callback then
            callback(result and result[1] or {})
        end
    end)
end

-- ============================================================================
-- RETORNO DO MÓDULO
-- ============================================================================
-- IMPORTANTE: Este retorno é essencial para que o LoadResourceFile funcione
-- corretamente. O módulo deve ser retornado como uma função que retorna
-- a tabela Database quando executada.
-- ============================================================================

return function()
    return Database
end