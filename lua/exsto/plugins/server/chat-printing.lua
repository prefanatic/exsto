-- Prefan Access Controller
-- ULX Style Printing

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Chat Printing Extras",
	ID = "chat-printing",
	Desc = "A plugin that contains a bunch of ULX style printing.",
	Owner = "Prefanatic",
} )

function PLUGIN:ChatNotify( ply, text )
	for k,v in pairs( player.GetAll() ) do
		exsto.Print( exsto_CHAT_NOLOGO, v, text )
	end
end
PLUGIN:AddCommand( "chatnotify", {
	Call = PLUGIN.ChatNotify,
	Desc = "Allows users to talk to do a chat notify on all players.",
	Console = { "chatnotify" },
	Chat = { "@@" },
	ReturnOrder = "Text",
	Args = { Text = "STRING" },
	Optional = { },
	Category = "Chat",
})

function PLUGIN:ChatNotify2( ply, text )
	for _, ply in ipairs( player.GetAll() ) do
		ply:PrintMessage( HUD_PRINTCENTER, text )
	end
end
PLUGIN:AddCommand( "chatnotify2", {
	Call = PLUGIN.ChatNotify2,
	Desc = "Allows users to talk to do a chat notify on all players (Middle of the screen).",
	Console = { "centernotify" },
	Chat = { "@@@" },
	ReturnOrder = "Text",
	Args = { Text = "STRING" },
	Optional = { },
	Category = "Chat",
})

function PLUGIN:AdminSay( ply, text )
	for k,v in pairs( player.GetAll() ) do
		if v:IsAdmin() or v:IsSuperAdmin() then
			v:Print( exsto_CHAT_NOLOGO, COLOR.NAME, "(ADMIN) ", ply, COLOR.NORM, ": " .. text )
		end
	end
end
PLUGIN:AddCommand( "adminsay", {
	Call = PLUGIN.AdminSay,
	Desc = "Allows users to talk to admins privately.",
	Console = { "adminsay" },
	Chat = { "@", "!admin", "!a" },
	ReturnOrder = "Text",
	Args = { Text = "STRING" },
	Optional = { },
	Category = "Chat",
})

PLUGIN:AddCommand( "ownersay", {
	Call = PLUGIN.OwnerSay,
	Desc = "Allows owners to talk to other owners privately.",
	Console = { "ownersay" },
	Chat = { "!owner", "!o" },
	ReturnOrder = "Text",
	Args = { Text = "STRING" },
	Optional = { },
	Category = "Chat",
})

PLUGIN:Register()
