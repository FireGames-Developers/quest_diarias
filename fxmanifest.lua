fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'FTx3g'
description 'Sistema de Missões Diárias Modular para VORP - v2.0.0 com Auto-Update'
version '2.0.0'

lua54 'yes'

dependencies {
    'vorp_core',
    'vorp_menu',
    'oxmysql',
    'vorp_animations'
}

client_scripts {
    'config.lua',
    'modules/*.lua',
    'client/*.lua',
    'quests/*.lua'
}

server_scripts {
    'config.lua',
    'server/module_loader.lua',
    'server/database.lua',
    'server/updater.lua',
    'server/quest_handler.lua',
    'server/init.lua',
    'server/commands.lua'
}