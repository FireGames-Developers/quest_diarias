fx_version 'cerulean'
game 'rdr3' -- RedM

rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."

author 'FTx'
description 'Loja do Ilegal'
lua54 'yes'
version '1.0.0'

dependency 'vorp_menu'

shared_scripts {
    'config.lua'
}

client_scripts {
	'client/*.lua',
}

server_scripts {
	'server/*.lua',
}