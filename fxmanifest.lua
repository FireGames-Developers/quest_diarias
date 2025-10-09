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
    'oxmysql'
}

client_scripts {
    'config.lua',
    'modules/*.lua',
    'client/*.lua'
}

server_scripts {
    'config.lua',
    'server/init.lua',
    'server/database.lua',
    'server/updater.lua',
    'server/*.lua'
}