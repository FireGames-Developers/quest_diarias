-- ============================================================================
-- QUEST DIÁRIAS - SISTEMA DE INICIALIZAÇÃO
-- ============================================================================
-- Este arquivo é responsável por inicializar todos os módulos do sistema
-- de quest diárias após o VORP Core estar totalmente carregado.
-- 
-- DEPENDÊNCIA CRÍTICA: Este script depende do evento 'vorp:SelectedCharacter'
-- do VORP Core para garantir inicialização segura. O evento é disparado quando
-- um jogador seleciona seu personagem, indicando que o VORP Core está
-- completamente carregado e todos os seus sistemas estão operacionais.
-- ============================================================================

local VorpCore = exports.vorp_core:GetCore()

-- Variáveis de controle de inicialização
local isInitialized = false
local initializationAttempts = 0
local maxInitializationAttempts = 3

-- ============================================================================
-- FUNÇÃO DE INICIALIZAÇÃO DOS MÓDULOS
-- ============================================================================
-- Esta função carrega e inicializa todos os módulos necessários do sistema
-- de quest diárias de forma segura, com tratamento de erros robusto.
-- ============================================================================
local function InitializeQuestSystem()
    if isInitialized then
        return -- Evita inicialização dupla
    end
    
    initializationAttempts = initializationAttempts + 1
    print("^3[QUEST DIÁRIAS]^0 Tentativa de inicialização #" .. initializationAttempts)
    
    local success = true
    
    -- ========================================================================
    -- INICIALIZAÇÃO DO MÓDULO DE BANCO DE DADOS
    -- ========================================================================
    local Database = ModuleLoader.LoadModule("server/database.lua", "Database")
    if Database and Database.Initialize then
        local dbOk = false
        local ok, err = pcall(function()
            dbOk = Database.Initialize()
        end)
        if ok and dbOk then
            print("^2[QUEST DIÁRIAS]^0 ✓ Módulo de banco de dados inicializado com sucesso via ModuleLoader")
        else
            print("^1[QUEST DIÁRIAS]^0 ✗ Erro: Falha ao inicializar banco de dados via ModuleLoader" .. (err and (" - " .. tostring(err)) or ""))
            success = false
        end
    else
        print("^1[QUEST DIÁRIAS]^0 ✗ Erro: Falha ao carregar módulo de banco de dados via ModuleLoader")
        success = false
    end
    
    -- ========================================================================
    -- INICIALIZAÇÃO DO MÓDULO DE ATUALIZAÇÕES
    -- ========================================================================
    local Updater = ModuleLoader.LoadModule("server/updater.lua", "Updater")
    if Updater and Updater.Initialize then
        Updater.Initialize()
        print("^2[QUEST DIÁRIAS]^0 ✓ Módulo de atualizações inicializado com sucesso via ModuleLoader")
    else
        print("^1[QUEST DIÁRIAS]^0 ✗ Erro: Falha ao carregar módulo de atualizações via ModuleLoader")
        success = false
    end
    
    if success then
        isInitialized = true
        print("^2[QUEST DIÁRIAS]^0 ✓ Sistema inicializado com sucesso após evento VORP")
    else
        print("^1[QUEST DIÁRIAS]^0 ✗ Falha na inicialização (tentativa " .. initializationAttempts .. "/" .. maxInitializationAttempts .. ")")
        
        -- Tenta novamente se não excedeu o limite de tentativas
        if initializationAttempts < maxInitializationAttempts then
            SetTimeout(5000, function()
                print("^3[QUEST DIÁRIAS]^0 Reagendando inicialização em 5 segundos...")
                InitializeQuestSystem()
            end)
        else
            print("^1[QUEST DIÁRIAS]^0 ✗ ERRO CRÍTICO: Máximo de tentativas de inicialização excedido!")
        end
    end
end

-- ============================================================================
-- LISTENER DO EVENTO VORP CORE
-- ============================================================================
-- IMPORTANTE: Este evento é uma dependência crítica do VORP Core.
-- O evento 'vorp:SelectedCharacter' é disparado quando um jogador seleciona
-- seu personagem, garantindo que o VORP Core está totalmente carregado.
-- 
-- Evitamos usar este evento sempre que possível, mas neste caso é necessário
-- para garantir que todos os sistemas do VORP estejam operacionais antes
-- de inicializar nossos módulos que dependem deles.
-- ============================================================================
AddEventHandler('vorp:SelectedCharacter', function(source, player)
    -- Só inicializa uma vez, quando o primeiro jogador se conecta
    if not isInitialized and initializationAttempts == 0 then
        print("^3[QUEST DIÁRIAS]^0 Evento VORP detectado - iniciando sistema...")
        InitializeQuestSystem()
    end
end)

-- ============================================================================
-- SISTEMA DE FALLBACK
-- ============================================================================
-- Como medida de segurança, também tentamos inicializar após um delay
-- caso o evento VORP não seja disparado por algum motivo.
-- ============================================================================
CreateThread(function()
    Wait(30000) -- Aguarda 30 segundos
    
    if not isInitialized and initializationAttempts == 0 then
        print("^3[QUEST DIÁRIAS]^0 Fallback: Iniciando sistema após timeout (evento VORP não detectado)")
        InitializeQuestSystem()
    end
end)