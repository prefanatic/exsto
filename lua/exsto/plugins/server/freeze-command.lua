
local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Freezer",
	ID = "freeze",
	Desc = "A plugin that allows freezing of other players!",
	Owner = "Prefanatic",
} )

function PLUGIN:CanPlayerSuicide( ply )
	if ply.NoSuicide then return false end
end

function PLUGIN:Freeze( caller, ply )
	if ply:IsFrozen() then
		caller:Print( exsto_CHAT, COLOR.NAME, ply:Nick(), COLOR.NORM, " is already frozen." )
		return
	end
	
	ply.NoSuicide = true
	ply:Freeze( true )
	exsto.NotifyChat( COLOR.NAME, caller:Nick(), COLOR.NORM, " has frozen ", COLOR.NAME, ply:Nick() )
end
PLUGIN:AddCommand( "freeze", {
	Call = PLUGIN.Freeze,
	Desc = "Allows users to freeze other players.",
	Console = { "freeze" },
	Chat = { "!freeze" },
	Arguments = {
		{ Name = "Player", Type = COMMAND_PLAYER };
	};
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "freeze", "Freeze" )

function PLUGIN:UnFreeze( caller, ply )
	if not ply:IsFrozen() then
		caller:Print( exsto_CHAT, COLOR.NAME, ply:Nick(), COLOR.NORM, " is not frozen." )
		return
	end
	
	ply.NoSuicide = false
	ply:Freeze( false )
	exsto.NotifyChat( COLOR.NAME, caller:Nick(), COLOR.NORM, " has unfrozen ", COLOR.NAME, ply:Nick() )
end
PLUGIN:AddCommand( "unfreeze", {
	Call = PLUGIN.UnFreeze,
	Desc = "Allows users to unfreeze other players.",
	Console = { "unfreeze" },
	Chat = { "!unfreeze" },
	Arguments = {
		{ Name = "Player", Type = COMMAND_PLAYER };
	};
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "unfreeze", "Unfreeze" )

PLUGIN:Register()