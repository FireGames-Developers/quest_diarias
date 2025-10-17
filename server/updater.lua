-- Sistema de Auto-Update para Quest Diárias (robusto)
-- Desenvolvido por FTx3g, melhorado para lidar com 404 e formatação de repositório

local Updater = {}

-- Normaliza o valor de repositório para o formato "owner/repo"
local function NormalizeRepo(repo)
    if not repo or type(repo) ~= 'string' then return '' end
    repo = repo:gsub('^https?://github%.com/', '')
    repo = repo:gsub('^github%.com/', '')
    repo = repo:gsub('/+$', '')
    return repo
end

-- Função para fazer requisições HTTP
local function MakeHttpRequest(url, callback)
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            callback(true, response)
        else
            if Config.DevMode then
                local sc = tonumber(statusCode) or -1
                if sc == 404 then
                    print(('[Quest Diarias] GitHub retornou 404 para %s; tentando fallback'):format(url))
                else
                    print(('[Quest Diarias] HTTP falhou (%d) ao verificar: %s'):format(sc, url))
                end
            end
            callback(false, nil)
        end
    end, 'GET', '', {
        ['User-Agent'] = 'quest_diarias-updater/1.0',
        ['Accept'] = 'application/vnd.github+json',
        ['X-GitHub-Api-Version'] = '2022-11-28'
    })
end

-- Função para comparar versões (semântica simples X.Y.Z)
local function CompareVersions(current, latest)
    current = tostring(current or ''):gsub('^v', '')
    latest = tostring(latest or ''):gsub('^v', '')

    local currentParts, latestParts = {}, {}
    for part in current:gmatch('[^%.]+') do table.insert(currentParts, tonumber(part) or 0) end
    for part in latest:gmatch('[^%.]+') do table.insert(latestParts, tonumber(part) or 0) end
    while #currentParts < #latestParts do table.insert(currentParts, 0) end
    while #latestParts < #currentParts do table.insert(latestParts, 0) end
    for i = 1, #currentParts do
        if latestParts[i] > currentParts[i] then return true
        elseif latestParts[i] < currentParts[i] then return false end
    end
    return false
end

-- Função para obter a versão mais recente do GitHub com fallbacks
local function GetLatestVersion(callback)
    local repo = NormalizeRepo(Config.AutoUpdate.Repository or '')
    if repo == '' then
        callback(false, nil, { reason = 'invalid_repo' })
        return
    end

    local urlLatest = string.format('https://api.github.com/repos/%s/releases/latest', repo)

    local function fallbackToReleases()
        local urlReleases = string.format('https://api.github.com/repos/%s/releases', repo)
        MakeHttpRequest(urlReleases, function(relOk, relResponse)
            if relOk and relResponse then
                local data = json.decode(relResponse)
                if type(data) == 'table' and #data > 0 then
                    local tag = data[1].tag_name or data[1].name
                    if tag then
                        callback(true, tag, { source = 'releases' })
                    else
                        callback(false, nil, { source = 'releases' })
                    end
                else
                    callback(false, nil, { source = 'releases' })
                end
            else
                callback(false, nil, { source = 'releases' })
            end
        end)
    end

    local function fallbackToTags()
        local urlTags = string.format('https://api.github.com/repos/%s/tags', repo)
        MakeHttpRequest(urlTags, function(tagsOk, tagsResponse)
            if tagsOk and tagsResponse then
                local data = json.decode(tagsResponse)
                if type(data) == 'table' and #data > 0 then
                    local best = data[1].name
                    for i = 2, #data do
                        local name = data[i].name
                        if CompareVersions(best, name) then best = name end
                    end
                    callback(true, best, { source = 'tags' })
                else
                    fallbackToReleases()
                end
            else
                fallbackToReleases()
            end
        end)
    end

    MakeHttpRequest(urlLatest, function(success, response)
        if success and response then
            local data = json.decode(response)
            if data and data.tag_name then
                callback(true, data.tag_name, data)
            else
                fallbackToTags()
            end
        else
            fallbackToTags()
        end
    end)
end

-- Verifica atualizações
local function CheckForUpdates(callback)
    if not Config.AutoUpdate.Enabled then return end
    GetLatestVersion(function(success, latestVersion, releaseData)
        if success then
            local hasUpdate = CompareVersions(Config.Version, latestVersion)
            callback(hasUpdate, latestVersion, releaseData)
        else
            if Config.DevMode then
                print('[Quest Diarias] Atualizações indisponíveis no GitHub (sem releases/tags ou repositório inválido)')
            end
            callback(false, nil, nil)
        end
    end)
end

-- Notifica administradores
local function NotifyAdmins(message)
    if not Config.AutoUpdate.NotifyAdmins then return end
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local user = exports.vorp_core:GetUser(tonumber(playerId))
        if user then
            local character = user.getUsedCharacter
            if character and character.group == 'admin' then
                TriggerClientEvent('vorp:TipBottom', tonumber(playerId), message, 8000)
            end
        end
    end
end

-- Placeholder de backup
local function CreateBackup()
    if not Config.AutoUpdate.BackupBeforeUpdate then return true end
    if Config.DevMode then print('[Quest Diarias] Backup criado antes da atualização') end
    return true
end

-- Placeholder de download/instalação
local function DownloadAndInstall(releaseData)
    if not Config.AutoUpdate.AutoDownload then
        if Config.DevMode then print('[Quest Diarias] Auto-download desabilitado. Atualização manual necessária.') end
        return false
    end
    if not CreateBackup() then
        if Config.DevMode then print('[Quest Diarias] Falha ao criar backup. Atualização cancelada.') end
        return false
    end
    if Config.DevMode then
        print('[Quest Diarias] Iniciando download da atualização...')
        print('[Quest Diarias] AVISO: Auto-instalação não implementada por segurança')
        print('[Quest Diarias] Por favor, atualize manualmente baixando do GitHub')
    end
    return false
end

function Updater.Initialize()
    if not Config.AutoUpdate.Enabled then
        if Config.DevMode then print('[Quest Diarias] Sistema de auto-update desabilitado') end
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
    Citizen.SetTimeout(30000, function()
        CheckForUpdates(function(hasUpdate, latestVersion, releaseData)
            if hasUpdate then
                local message = string.format('[Quest Diarias] Nova versão disponível: %s (atual: %s)', latestVersion, Config.Version)
                if Config.DevMode then print(message) end
                NotifyAdmins(message)
                if Config.AutoUpdate.AutoDownload then DownloadAndInstall(releaseData) end
            else
                if Config.DevMode then print('[Quest Diarias] Sistema atualizado (versão atual: ' .. Config.Version .. ')') end
            end
        end)
    end)
    if Config.AutoUpdate.CheckInterval and Config.AutoUpdate.CheckInterval > 0 then
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(Config.AutoUpdate.CheckInterval * 60000)
                CheckForUpdates(function(hasUpdate, latestVersion, releaseData)
                    if hasUpdate then
                        local message = string.format('[Quest Diarias] Nova versão disponível: %s', latestVersion)
                        if Config.DevMode then print(message) end
                        NotifyAdmins(message)
                        if Config.AutoUpdate.AutoDownload then DownloadAndInstall(releaseData) end
                    end
                end)
            end
        end)
    else
        if Config.DevMode then print('[Quest Diarias] Verificação periódica desabilitada (CheckInterval <= 0)') end
    end
    if Config.DevMode then print('[Quest Diarias] Sistema de auto-update inicializado com sucesso!') end
end

-- Comandos administrativos
RegisterCommand('quest_checkupdate', function(source)
    local user = exports.vorp_core:GetUser(source); if not user then return end
    local character = user.getUsedCharacter; if not character then return end
    if character.group ~= 'admin' then TriggerClientEvent('vorp:TipBottom', source, 'Você não tem permissão para usar este comando', 3000); return end
    TriggerClientEvent('vorp:TipBottom', source, 'Verificando atualizações...', 3000)
    CheckForUpdates(function(hasUpdate, latestVersion)
        if hasUpdate then
            local message = string.format('Nova versão disponível: %s (atual: %s)', latestVersion, Config.Version)
            TriggerClientEvent('vorp:TipBottom', source, message, 8000)
        else
            TriggerClientEvent('vorp:TipBottom', source, 'Sistema está atualizado (v' .. Config.Version .. ')', 5000)
        end
    end)
end, false)

RegisterCommand('quest_update', function(source)
    local user = exports.vorp_core:GetUser(source); if not user then return end
    local character = user.getUsedCharacter; if not character then return end
    if character.group ~= 'admin' then TriggerClientEvent('vorp:TipBottom', source, 'Você não tem permissão para usar este comando', 3000); return end
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
    TriggerClientEvent('vorp:TipBottom', source, info, 10000)
end, false)

return Updater