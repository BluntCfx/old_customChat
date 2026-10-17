fx_version 'cerulean'
game 'gta5'
name "custom_chat"
description "custom_chat"
author "OldMoney"
version "1.0.0"

shared_scripts {
	'shared/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}

ui_page 'ui/dist/index.html'

files {
	'ui/dist/index.html',
	'ui/dist/assets/*.*'
}

exports {
	'addSuggestion',
	'removeSuggestion'
}
