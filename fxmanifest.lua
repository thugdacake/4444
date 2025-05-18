fx_version 'cerulean'
game 'gta5'

name 'Tokyo Box'
description 'Um player de música estilo Spotify para servidores FiveM QBCore com tema galáxia'
author 'Tokyo Box Team'
version '1.0.0'

-- Scripts
client_scripts {
    'config.lua',
    'client/main.lua',
    'client/nui.lua',
    'client/player.lua'
}

server_scripts {
    'config.lua',
    'server/main.lua',
    'server/database.lua',
    'server/songs.lua'
}

-- UI
ui_page 'ui/index.html'

-- Arquivos para download
files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/components/player.js',
    'ui/components/playlist.js',
    'ui/components/search.js',
    'ui/assets/**/*'
}

-- Dependências
dependencies {
    'qb-core',
    'xsound'
}

-- Exportações
exports {
    'IsTokyoBoxOpen',
    'GetCurrentTrack',
    'GetCurrentPlaylist',
    'IsPlayerVIP',
    'GetBluetoothStatus',
    'ToggleBluetoothStatus',
    'GetAudioRange',
    'SetAudioRange'
}