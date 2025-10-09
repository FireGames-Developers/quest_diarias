-- Sistema de Auto-Update para Quest Diárias
-- Desenvolvido por FTx3g

local Updater = {}

-- Função para fazer requisições HTTP
local function MakeHttpRequest(url, callback)
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            callback(true, response)
        else
            if Config.DevMode then
                print(('[Quest Diarias] HTTP falhou (%d) ao verificar: %s'):format(tonumber(statusCode) or -1, url))
            end
            callback(false, nil)
        end
    end, 'GET', '', {
        ['User-Agent'] = 'quest_diarias-updater/1.0'
    })
end

-- Função para obter a versão mais recente do GitHub
local function GetLatestVersion(callback)
    local urlLatest = string.format('https://api.github.com/repos/%s/releases/latest', Config.AutoUpdate.Repository)

    local function fallbackToTags()
        local urlTags = string.format('https://api.github.com/repos/%s/tags', Config.AutoUpdate.Repository)
        MakeHttpRequest(urlTags, function(tagsOk, tagsResponse)
            if tagsOk and tagsResponse then
                local data = json.decode(tagsResponse)
                if type(data) == 'table' and #data > 0 then
                    -- Selecionar a melhor tag por comparação de versões
                    local best = data[1].name
                    for i = 2, #data do
                        local name = data[i].name
                        if CompareVersions(best, name) then
                            best = name
                        end
                    end
                    callback(true, best, { source = 'tags' })
                else
                    callback(false, nil, nil)
                end
            else
                callback(false, nil, nil)
            end
        end)
    end

    MakeHttpRequest(urlLatest, function(success, response)
        if success and response then
            local data = json.decode(response)
            if data and data.tag_name then
                callback(true, data.tag_name, data)
            else
                -- Sem releases válidos, tentar fallback via tags
                fallbackToTags()
            end
        else
            -- Falha (ex.: 404), tentar fallback via tags
            fallbackToTags()
        end
    end)
end

-- Função para comparar versões
local function CompareVersions(current, latest)
    -- Remove 'v' prefix se existir
    current = current:gsub('^v', '')
    latest = latest:gsub('^v', '')
    
    local currentParts = {}
    local latestParts = {}
    
    for part in current:gmatch('[^%.]+') do
        table.insert(currentParts, tonumber(part) or 0)
    end
    
    for part in latest:gmatch('[^%.]+') do
        table.insert(latestParts, tonumber(part) or 0)
    end
    
    -- Garantir que ambas as versões tenham o mesmo número de partes
    while #currentParts < #latestParts do
        table.insert(currentParts, 0)
    end
    while #latestParts < #currentParts do
        table.insert(latestParts, 0)
    end
    
    for i = 1, #currentParts do
        if latestParts[i] > currentParts[i] then
            return true -- Nova versão disponível
        elseif latestParts[i] < currentParts[i] then
            return false -- Versão atual é mais nova
        end
    end
    
    return false -- Versões são iguais
end

-- Função para verificar atualizações
local function CheckForUpdates(callback)
    if not Config.AutoUpdate.Enabled then
        return
    end
    
    GetLatestVersion(function(success, latestVersion, releaseData)
        if success then
            local hasUpdate = CompareVersions(Config.Version, latestVersion)
            callback(hasUpdate, latestVersion, releaseData)
        else
            if Config.DevMode then
                print('[Quest Diarias] Erro ao verificar atualizações no GitHub')
            end
            callback(false, nil, nil)
        end
    end)
end

-- Função para notificar administradores
local function NotifyAdmins(message)
    if not Config.AutoUpdate.NotifyAdmins then
        return
    end
    
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local user = exports.vorp_core:GetUser(tonumber(playerId))
        if user then
            local character = user.getUsedCharacter
            if character and character.group == 'admin' then
                TriggerClientEvent('vorp:TipRight', tonumber(playerId), message, 8000)
            end
        end
    end
end

-- Função para criar backup antes da atualização
local function CreateBackup()
    if not Config.AutoUpdate.BackupBeforeUpdate then
        return true
    end
    
    -- Aqui você implementaria a lógica de backup
    -- Por exemplo, copiar arquivos importantes para uma pasta de backup
    if Config.DevMode then
        print('[Quest Diarias] Backup criado antes da atualização')
    end
    
    return true
end

-- Função para baixar e instalar atualização (conceitual)
local function DownloadAndInstall(releaseData)
    if not Config.AutoUpdate.AutoDownload then
        if Config.DevMode then
            print('[Quest Diarias] Auto-download desabilitado. Atualização manual necessária.')
        end
        return false
    end
    
    -- Criar backup
    if not CreateBackup() then
        if Config.DevMode then
            print('[Quest Diarias] Falha ao criar backup. Atualização cancelada.')
        end
        return false
    end
    
    -- Aqui você implementaria a lógica de download e instalação
    -- NOTA: Isso requer cuidado especial pois envolve substituir arquivos do recurso ativo
    if Config.DevMode then
        print('[Quest Diarias] Iniciando download da atualização...')
        print('[Quest Diarias] AVISO: Auto-instalação não implementada por segurança')
        print('[Quest Diarias] Por favor, atualize manualmente baixando do GitHub')
    end
    
    return false -- Retorna false por segurança até implementação completa
end

-- Função para inicializar o sistema de auto-update
function Updater.Initialize()
    if not Config.AutoUpdate.Enabled then
        if Config.DevMode then
            print('[Quest Diarias] Sistema de auto-update desabilitado')
        end
        return
    end
    
    if Config.DevMode then
        print('[Quest Diarias] Inicializando sistema de auto-update...')
        print(('[Quest Diarias] Repositório: %s'):format(Config.AutoUpdate.Repository))
        print(('[Quest Diarias] Branch: %s'):format(Config.AutoUpdate.Branch))
        if Config.AutoUpdate.CheckInterval and Config.AutoUpdate.CheckInterval > 0 then
            print(('[Quest Diarias] Intervalo de verificação: %d minutos'):format(Config.AutoUpdate.CheckInterval))
        else
            print('[Quest Diarias] Checagem única no start/restart (verificação periódica desabilitada)')
        end
    end
    
    -- Verificação inicial após 30 segundos
    Citizen.SetTimeout(30000, function()
        CheckForUpdates(function(hasUpdate, latestVersion, releaseData)
            if hasUpdate then
                local message = string.format('[Quest Diarias] Nova versão disponível: %s (atual: %s)', latestVersion, Config.Version)
                if Config.DevMode then
                    print(message)
                end
                NotifyAdmins(message)
                
                if Config.AutoUpdate.AutoDownload then
                    DownloadAndInstall(releaseData)
                end
            else
                if Config.DevMode then
                    print('[Quest Diarias] Sistema atualizado (versão atual: ' .. Config.Version .. ')')
                end
            end
        end)
    end)
    
    -- Verificação periódica (desativada se intervalo <= 0)
    if Config.AutoUpdate.CheckInterval and Config.AutoUpdate.CheckInterval > 0 then
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(Config.AutoUpdate.CheckInterval * 60000) -- Converter minutos para millisegundos
                
                CheckForUpdates(function(hasUpdate, latestVersion, releaseData)
                    if hasUpdate then
                        local message = string.format('[Quest Diarias] Nova versão disponível: %s', latestVersion)
                        if Config.DevMode then
                            print(message)
                        end
                        NotifyAdmins(message)
                        
                        if Config.AutoUpdate.AutoDownload then
                            DownloadAndInstall(releaseData)
                        end
                    end
                end)
            end
        end)
    else
        if Config.DevMode then
            print('[Quest Diarias] Verificação periódica desabilitada (CheckInterval <= 0)')
        end
    end
    
    if Config.DevMode then
        print('[Quest Diarias] Sistema de auto-update inicializado com sucesso!')
    end
end

-- Comando administrativo para verificar atualizações manualmente
RegisterCommand('quest_checkupdate', function(source, args, rawCommand)
    local user = exports.vorp_core:GetUser(source)
    if not user then return end
    
    local character = user.getUsedCharacter
    if not character then return end
    
    if character.group ~= 'admin' then
        TriggerClientEvent('vorp:TipRight', source, 'Você não tem permissão para usar este comando', 3000)
        return
    end
    
    TriggerClientEvent('vorp:TipRight', source, 'Verificando atualizações...', 3000)
    
    CheckForUpdates(function(hasUpdate, latestVersion, releaseData)
        if hasUpdate then
            local message = string.format('Nova versão disponível: %s (atual: %s)', latestVersion, Config.Version)
            TriggerClientEvent('vorp:TipRight', source, message, 8000)
        else
            TriggerClientEvent('vorp:TipRight', source, 'Sistema está atualizado (v' .. Config.Version .. ')', 5000)
        end
    end)
end, false)

-- Comando administrativo para obter informações de atualização
RegisterCommand('quest_update', function(source, args, rawCommand)
    local user = exports.vorp_core:GetUser(source)
    if not user then return end
    
    local character = user.getUsedCharacter
    if not character then return end
    
    if character.group ~= 'admin' then
        TriggerClientEvent('vorp:TipRight', source, 'Você não tem permissão para usar este comando', 3000)
        return
    end
    
    local info = string.format(
        'Quest Diárias Auto-Update Info:\n' ..
        '• Versão atual: %s\n' ..
        '• Repositório: %s\n' ..
        '• Auto-update: %s\n' ..
        '• Auto-download: %s\n' ..
        '• Backup automático: %s',
        Config.Version,
        Config.AutoUpdate.Repository,
        Config.AutoUpdate.Enabled and 'Ativado' or 'Desativado',
        Config.AutoUpdate.AutoDownload and 'Ativado' or 'Desativado',
        Config.AutoUpdate.BackupBeforeUpdate and 'Ativado' or 'Desativado'
    )
    
    TriggerClientEvent('vorp:TipRight', source, info, 10000)
end, false)

return Updater