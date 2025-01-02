fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'A enhanced exp system for every Framework with support to use VORP skills'

lua54 'yes'

author 'RedM-Brewery - LandminenTester'

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

shared_scripts {
    '@jo_libs/init.lua',
    'config.lua'

}

dependencies { 
    'jo_libs'
}

version '1.0'

jo_libs {
    'framework',    
    'database',
}
