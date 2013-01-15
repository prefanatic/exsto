
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

function PLUGIN:Freeze( self, ply )

	if ply:IsFrozen() then
		ply.NoSuicide = false
		ply:Freeze( false )
		return {
			Activator = self,
			Player = ply,
			Wording = " has unfrozen ",
		}
	else
		ply.NoSuicide = true
		ply:Freeze( true )
		return {
			Activator = self,
			Player = ply,
			Wording = " has frozen ",
		}
	end
	
end
PLUGIN:AddCommand( "freeze", {
	Call = PLUGIN.Freeze,
	Desc = "Allows users to freeze other players.",
	Console = { "freeze" },
	Chat = { "!freeze", "!unfreeze" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "freeze" )

PLUGIN:Register()