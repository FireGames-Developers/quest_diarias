-- ============================================================================
-- SISTEMA DE CARREGAMENTO DE MÓDULOS - QUEST DIÁRIAS
-- ============================================================================
-- Sistema centralizado para carregar módulos de forma segura usando LoadResourceFile
-- em vez de require() para evitar problemas de dependência circular no FiveM/RedM.
-- ============================================================================

ModuleLoader = {}
ModuleLoader.LoadedModules = {}

-- Função para carregar um módulo de forma segura
function ModuleLoader.LoadModule(modulePath, moduleName)
    moduleName = moduleName or modulePath
    
    -- Verificar se já foi carregado
    if ModuleLoader.LoadedModules[moduleName] then
        return ModuleLoader.LoadedModules[moduleName]
    end
    
    -- Tentar carregar o arquivo
    local moduleFile = LoadResourceFile(GetCurrentResourceName(), modulePath)
    if not moduleFile then
        print("^1[QUEST DIÁRIAS]^0 ✗ Erro: Não foi possível carregar " .. modulePath)
        return nil
    end
    
    -- Tentar compilar o módulo
    local moduleFunction, compileError = load(moduleFile, modulePath)
    if not moduleFunction then
        print("^1[QUEST DIÁRIAS]^0 ✗ Erro ao compilar " .. modulePath .. ": " .. (compileError or "desconhecido"))
        return nil
    end
    
    -- Tentar executar o módulo
    local success, moduleResult = pcall(moduleFunction)
    if not success then
        print("^1[QUEST DIÁRIAS]^0 ✗ Erro ao executar " .. modulePath .. ": " .. (moduleResult or "desconhecido"))
        return nil
    end
    
    -- Se o resultado é uma função, executá-la para obter o módulo real
    if type(moduleResult) == "function" then
        local functionSuccess, actualModule = pcall(moduleResult)
        if functionSuccess then
            moduleResult = actualModule
        else
            print("^1[QUEST DIÁRIAS]^0 ✗ Erro ao executar função do módulo " .. modulePath .. ": " .. (actualModule or "desconhecido"))
            return nil
        end
    end
    
    -- Armazenar o módulo carregado
    ModuleLoader.LoadedModules[moduleName] = moduleResult
    print("^2[QUEST DIÁRIAS]^0 ✓ Módulo " .. moduleName .. " carregado com sucesso")
    
    return moduleResult
end

-- Função para obter um módulo já carregado
function ModuleLoader.GetModule(moduleName)
    return ModuleLoader.LoadedModules[moduleName]
end

-- Função para verificar se um módulo está carregado
function ModuleLoader.IsModuleLoaded(moduleName)
    return ModuleLoader.LoadedModules[moduleName] ~= nil
end

-- Função para listar todos os módulos carregados
function ModuleLoader.GetLoadedModules()
    local modules = {}
    for name, _ in pairs(ModuleLoader.LoadedModules) do
        table.insert(modules, name)
    end
    return modules
end

-- Reset interno (usado em restart de resource)
function ModuleLoader.Reset()
    ModuleLoader.LoadedModules = {}
end

print("^2[QUEST DIÁRIAS]^0 ✓ Sistema de carregamento de módulos inicializado")

return ModuleLoader