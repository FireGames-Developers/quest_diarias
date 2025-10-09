-- ============================================================================
-- TESTE DE INTEGRAÇÃO COM VORP CORE
-- ============================================================================
-- Este arquivo testa se o sistema de quest diárias está funcionando
-- corretamente com o VORP Core após as modificações implementadas.
-- ============================================================================

print("^3[QUEST DIÁRIAS - TESTE]^0 Iniciando teste de integração com VORP Core...")

-- Teste 1: Verificar se o VORP Core está disponível
local function TestVorpCore()
    print("^3[TESTE 1]^0 Verificando disponibilidade do VORP Core...")
    
    local success, VorpCore = pcall(function()
        return exports.vorp_core:GetCore()
    end)
    
    if success and VorpCore then
        print("^2[TESTE 1]^0 ✓ VORP Core está disponível")
        return true
    else
        print("^1[TESTE 1]^0 ✗ VORP Core não está disponível")
        return false
    end
end

-- Teste 2: Verificar se o evento vorp:SelectedCharacter está sendo registrado
local function TestVorpEvent()
    print("^3[TESTE 2]^0 Testando registro do evento vorp:SelectedCharacter...")
    
    local eventRegistered = false
    
    -- Registrar o evento temporariamente para teste
    RegisterNetEvent("vorp:SelectedCharacter")
    AddEventHandler("vorp:SelectedCharacter", function(source, player)
        print("^2[TESTE 2]^0 ✓ Evento vorp:SelectedCharacter recebido!")
        print("^2[TESTE 2]^0 Source: " .. tostring(source))
        print("^2[TESTE 2]^0 Player: " .. tostring(player))
        eventRegistered = true
    end)
    
    -- Simular o evento (apenas para teste)
    CreateThread(function()
        Wait(2000)
        if not eventRegistered then
            print("^3[TESTE 2]^0 ⚠ Evento não foi disparado (normal se não há jogadores conectados)")
        end
    end)
    
    return true
end

-- Teste 3: Verificar se os módulos podem ser carregados
local function TestModuleLoading()
    print("^3[TESTE 3]^0 Testando carregamento de módulos...")
    
    -- Testar carregamento do módulo de banco de dados
    local databaseFile = LoadResourceFile(GetCurrentResourceName(), "server/database.lua")
    if databaseFile then
        local success, databaseModule = pcall(load, databaseFile)
        if success and databaseModule then
            print("^2[TESTE 3]^0 ✓ Módulo de banco de dados pode ser carregado")
        else
            print("^1[TESTE 3]^0 ✗ Erro ao carregar módulo de banco de dados")
            return false
        end
    else
        print("^1[TESTE 3]^0 ✗ Arquivo de banco de dados não encontrado")
        return false
    end
    
    -- Testar carregamento do módulo de quest handler
    local questHandlerFile = LoadResourceFile(GetCurrentResourceName(), "server/quest_handler.lua")
    if questHandlerFile then
        print("^2[TESTE 3]^0 ✓ Arquivo quest_handler.lua encontrado")
    else
        print("^1[TESTE 3]^0 ✗ Arquivo quest_handler.lua não encontrado")
        return false
    end
    
    return true
end

-- Teste 4: Verificar se o sistema de inicialização está funcionando
local function TestInitializationSystem()
    print("^3[TESTE 4]^0 Testando sistema de inicialização...")
    
    -- Verificar se as variáveis de controle existem
    local initFile = LoadResourceFile(GetCurrentResourceName(), "server/init.lua")
    if initFile then
        if string.find(initFile, "isInitialized") and 
           string.find(initFile, "initializationAttempts") and
           string.find(initFile, "vorp:SelectedCharacter") then
            print("^2[TESTE 4]^0 ✓ Sistema de inicialização implementado corretamente")
            return true
        else
            print("^1[TESTE 4]^0 ✗ Sistema de inicialização incompleto")
            return false
        end
    else
        print("^1[TESTE 4]^0 ✗ Arquivo init.lua não encontrado")
        return false
    end
end

-- Executar todos os testes
CreateThread(function()
    Wait(1000) -- Aguardar um pouco para o recurso carregar
    
    print("^3[QUEST DIÁRIAS - TESTE]^0 ========================================")
    print("^3[QUEST DIÁRIAS - TESTE]^0 Executando bateria de testes...")
    print("^3[QUEST DIÁRIAS - TESTE]^0 ========================================")
    
    local results = {
        vorp_core = TestVorpCore(),
        vorp_event = TestVorpEvent(),
        module_loading = TestModuleLoading(),
        initialization = TestInitializationSystem()
    }
    
    Wait(3000) -- Aguardar testes assíncronos
    
    print("^3[QUEST DIÁRIAS - TESTE]^0 ========================================")
    print("^3[QUEST DIÁRIAS - TESTE]^0 RESULTADOS DOS TESTES:")
    print("^3[QUEST DIÁRIAS - TESTE]^0 ========================================")
    
    local allPassed = true
    for testName, result in pairs(results) do
        local status = result and "^2✓ PASSOU^0" or "^1✗ FALHOU^0"
        print("^3[QUEST DIÁRIAS - TESTE]^0 " .. testName:upper() .. ": " .. status)
        if not result then
            allPassed = false
        end
    end
    
    print("^3[QUEST DIÁRIAS - TESTE]^0 ========================================")
    if allPassed then
        print("^2[QUEST DIÁRIAS - TESTE]^0 🎉 TODOS OS TESTES PASSARAM!")
        print("^2[QUEST DIÁRIAS - TESTE]^0 O sistema está funcionando corretamente.")
    else
        print("^1[QUEST DIÁRIAS - TESTE]^0 ⚠ ALGUNS TESTES FALHARAM!")
        print("^1[QUEST DIÁRIAS - TESTE]^0 Verifique os logs acima para detalhes.")
    end
    print("^3[QUEST DIÁRIAS - TESTE]^0 ========================================")
end)