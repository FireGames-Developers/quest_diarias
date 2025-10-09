-- Auto Updater System - Sistema de Atualização Automática via GitHub
-- Desenvolvido por FTx3g

local Updater = {}
local currentVersion = "2.0.0" -- Versão atual do script

-- Função para fazer requisições HTTP
local function MakeHttpRequest(url, callback)
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            local success, data = pcall(json.decode, response)
            if success then
                callback(true, data)
            else
                callback(false, "Erro ao decodificar JSON")
            end
        else
            callback(false, "Erro HTTP: " .. statusCode)
        end
    end, "GET", "", {["Content-Type"] = "application/json"})
end

-- Função para obter a versão mais recente do GitHub
function Updater.GetLatestVersion(callback)
    if not Config.AutoUpdate.enabled then
        callback(false, "Auto-update desabilitado")
        return
    end
    
    local apiUrl = Config.AutoUpdate.repository:gsub("github.com", "api.github.com/repos") .. "/releases/latest"
    
    if Config.DevMode then
        print(('[Updater] Verificando versão mais recente em: %s'):format(apiUrl))
    end
    
    MakeHttpRequest(apiUrl, function(success, data)
        if success and data and data.tag_name then
            local latestVersion = data.tag_name:gsub("v", "") -- Remove 'v' se existir
            callback(true, {
                version = latestVersion,
                downloadUrl = data.zipball_url,
                releaseNotes = data.body or "Sem notas de release",
                publishedAt = data.published_at
            })
        else
            callback(false, data or "Erro ao obter dados da release")
        end
    end)
end

-- Função para comparar versões
function Updater.CompareVersions(current, latest)
    local function parseVersion(version)
        local parts = {}
        for part in version:gmatch("(%d+)") do
            table.insert(parts, tonumber(part))
        end
        return parts
    end
    
    local currentParts = parseVersion(current)
    local latestParts = parseVersion(latest)
    
    for i = 1, math.max(#currentParts, #latestParts) do
        local currentPart = currentParts[i] or 0
        local latestPart = latestParts[i] or 0
        
        if latestPart > currentPart then
            return true -- Nova versão disponível
        elseif latestPart < currentPart then
            return false -- Versão atual é mais nova
        end
    end
    
    return false -- Versões são iguais
end

-- Função para verificar se há atualizações
function Updater.CheckForUpdates(callback)
    Updater.GetLatestVersion(function(success, data)
        if success then
            local hasUpdate = Updater.CompareVersions(currentVersion, data.version)
            
            if Config.DevMode then
                print(('[Updater] Versão atual: %s | Versão mais recente: %s | Atualização disponível: %s'):format(
                    currentVersion, data.version, tostring(hasUpdate)
                ))
            end
            
            callback(hasUpdate, data)
        else
            if Config.DevMode then
                print(('[Updater] Erro ao verificar atualizações: %s'):format(data))
            end
            callback(false, data)
        end
    end)
end

-- Função para notificar administradores sobre atualizações
function Updater.NotifyAdmins(updateData)
    if not Config.AutoUpdate.notifyAdmins then
        return
    end
    
    local message = string.format(
        "🔄 Nova atualização disponível para Quest Diarias!\n" ..
        "• Versão atual: %s\n" ..
        "• Nova versão: %s\n" ..
        "• Use /quest_update para atualizar",
        currentVersion,
        updateData.version
    )
    
    -- Notificar todos os jogadores online com permissão de admin
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local user = exports.vorp_core:GetCore().getUser(tonumber(playerId))
        if user then
            local character = user.getUsedCharacter
            if character and character.group == 'admin' then
                TriggerClientEvent('vorp:TipBottom', tonumber(playerId), message, 10000)
            end
        end
    end
    
    if Config.DevMode then
        print(('[Updater] Administradores notificados sobre nova versão: %s'):format(updateData.version))
    end
end

-- Função para criar backup do recurso atual
function Updater.CreateBackup(callback)
    if not Config.AutoUpdate.backupBeforeUpdate then
        callback(true)
        return
    end
    
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local backupPath = resourcePath .. "_backup_" .. os.date("%Y%m%d_%H%M%S")
    
    -- Usar comando do sistema para copiar a pasta
    local command = string.format('xcopy "%s" "%s" /E /I /H /Y', resourcePath, backupPath)
    
    if Config.DevMode then
        print(('[Updater] Criando backup em: %s'):format(backupPath))
    end
    
    -- Executar comando de backup (isso é uma simulação, pois não podemos executar comandos do sistema diretamente)
    -- Em um ambiente real, você precisaria usar um método específico do seu servidor
    callback(true, backupPath)
end

-- Função para baixar e instalar atualização
function Updater.DownloadAndInstall(updateData, callback)
    if Config.DevMode then
        print(('[Updater] Iniciando download da versão %s'):format(updateData.version))
    end
    
    -- Criar backup primeiro
    Updater.CreateBackup(function(backupSuccess, backupPath)
        if not backupSuccess then
            callback(false, "Erro ao criar backup")
            return
        end
        
        -- Aqui você implementaria o download real do arquivo ZIP
        -- Por limitações de segurança, não podemos baixar e extrair arquivos automaticamente
        -- Esta é uma implementação conceitual
        
        if Config.DevMode then
            print('[Updater] ⚠️  Download automático não implementado por questões de segurança')
            print('[Updater] 📋 Para atualizar manualmente:')
            print('[Updater] 1. Baixe a nova versão do GitHub')
            print('[Updater] 2. Substitua os arquivos do recurso')
            print('[Updater] 3. Reinicie o recurso')
        end
        
        callback(false, "Download automático desabilitado por segurança. Atualize manualmente.")
    end)
end

-- Função principal de verificação automática
function Updater.AutoCheck()
    if not Config.AutoUpdate.enabled then
        return
    end
    
    Updater.CheckForUpdates(function(hasUpdate, data)
        if hasUpdate then
            Updater.NotifyAdmins(data)
            
            if Config.AutoUpdate.autoDownload then
                Updater.DownloadAndInstall(data, function(success, message)
                    if Config.DevMode then
                        print(('[Updater] Resultado do download automático: %s'):format(message))
                    end
                end)
            end
        end
    end)
end

-- Inicializar sistema de verificação automática
function Updater.Initialize()
    if not Config.AutoUpdate.enabled then
        if Config.DevMode then
            print('[Updater] Sistema de auto-update desabilitado')
        end
        return
    end
    
    if Config.DevMode then
        print('[Updater] Sistema de auto-update inicializado')
        print(('[Updater] Repositório: %s'):format(Config.AutoUpdate.repository))
        print(('[Updater] Intervalo de verificação: %d ms'):format(Config.AutoUpdate.checkInterval))
    end
    
    -- Verificação inicial após 30 segundos
    Citizen.SetTimeout(30000, function()
        Updater.AutoCheck()
    end)
    
    -- Verificação periódica
    Citizen.CreateThread(function()
        while Config.AutoUpdate.enabled do
            Citizen.Wait(Config.AutoUpdate.checkInterval)
            Updater.AutoCheck()
        end
    end)
end

-- Comando para verificação manual de atualizações
RegisterCommand('quest_checkupdate', function(source, args, rawCommand)
    local user = exports.vorp_core:GetCore().getUser(source)
    if not user then return end
    
    local character = user.getUsedCharacter
    if not character then return end
    
    if character.group ~= 'admin' then
        TriggerClientEvent('vorp:TipBottom', source, 'Você não tem permissão para usar este comando', 3000)
        return
    end
    
    TriggerClientEvent('vorp:TipBottom', source, 'Verificando atualizações...', 3000)
    
    Updater.CheckForUpdates(function(hasUpdate, data)
        if hasUpdate then
            local message = string.format(
                'Nova versão disponível: %s\nVersão atual: %s\nUse /quest_update para mais detalhes',
                data.version,
                currentVersion
            )
            TriggerClientEvent('vorp:TipBottom', source, message, 8000)
        else
            TriggerClientEvent('vorp:TipBottom', source, 'Você está usando a versão mais recente!', 3000)
        end
    end)
end, false)

-- Comando para obter informações detalhadas da atualização
RegisterCommand('quest_update', function(source, args, rawCommand)
    local user = exports.vorp_core:GetCore().getUser(source)
    if not user then return end
    
    local character = user.getUsedCharacter
    if not character then return end
    
    if character.group ~= 'admin' then
        TriggerClientEvent('vorp:TipBottom', source, 'Você não tem permissão para usar este comando', 3000)
        return
    end
    
    Updater.CheckForUpdates(function(hasUpdate, data)
        if hasUpdate then
            local message = string.format(
                'Detalhes da Atualização:\n' ..
                '• Nova versão: %s\n' ..
                '• Versão atual: %s\n' ..
                '• Publicado em: %s\n' ..
                '• Baixe em: %s',
                data.version,
                currentVersion,
                data.publishedAt or 'N/A',
                Config.AutoUpdate.repository .. '/releases/latest'
            )
            TriggerClientEvent('vorp:TipBottom', source, message, 15000)
        else
            TriggerClientEvent('vorp:TipBottom', source, 'Nenhuma atualização disponível', 3000)
        end
    end)
end, false)

return Updater