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
	local msg = exsto.CreateColoredPrint( text )
	exsto.Print( exsto_CHAT_ALL, COLOR.NAME, ply:Nick(), COLOR.NORM, ": ", unpack( msg ) )
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
	-- Lets do something fancy.
	local advert = exsto.GetPlugin( "adverts" )
	if not advert then
		for _, ply in ipairs( player.GetAll() ) do
			ply:PrintMessage( HUD_PRINTCENTER, text )
		end
		return
	end
	
	local msg = "[c=COLOR,NAME] " .. ply:Nick() .. " [c=COLOR,NORM] : " .. text
	advert:RunAdvert( {
		ID = "chat-printing-notify";
		Display = "chat-printing-notify";
		Contents = exsto.CreateColoredPrint( msg );
		StringContents = msg;
		Location = 3;
		Delay = 0;
		Data = data;
		Enabled = 1;
	} )
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

PLUGIN:Register()
