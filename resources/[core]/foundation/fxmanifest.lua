fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'foundation'
description 'Server foundation: player lifecycle and persistence'
version '0.1.0'

shared_scripts {
    'shared/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/player.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'oxmysql'
}
