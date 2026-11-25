fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'foundation'
description 'Server foundation: player lifecycle, accounts and characters'
version '0.2.0'

shared_scripts {
    'shared/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/player.lua',
    'server/characters.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'oxmysql'
}
