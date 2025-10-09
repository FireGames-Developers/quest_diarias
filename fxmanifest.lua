fx_version 'cerulean'
game 'rdr3' -- RedM

rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."

author 'FTx3g'
description 'Sistema de Missões Diárias'
lua54 'yes'
version '2.0.0'

dependencies {
    'vorp_core',
    'vorp_menu',
    'oxmysql'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'modules/*.lua',
    'client/*.lua'
}

server_scripts {
    'server/init.lua',
    'server/*.lua'
}