-- Prefan Access Controller
-- Color'or Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Color Changer",
	ID = "color",
	Desc = "A plugin that allows changing color of players!",
	Owner = "Prefanatic",
} )

function PLUGIN:UnColor( caller, ply )
	if not ply._OldColor then
		caller:Print( exsto_CHAT, COLOR.NAME, ply:Nick(), COLOR.NORM, " has not been set a color before." )
		return
	end
	
	ply:SetPlayerColor( ply._OldColor )
	ply._OldColor = nil
	return { COLOR.NAME, caller:Nick(), COLOR.NORM, " has restored ", COLOR.NAME, ply:Nick(), COLOR.NORM, "'s color." }
end
PLUGIN:AddCommand( "uncolor", {
	Call = PLUGIN.UnColor,
	Desc = "Allows users to remove previously set colors on players.",
	Console = { "uncolor" },
	Chat = { "!uncolor" },
	Arguments = {
		{ Name = "Victim", Type = COMMAND_PLAYER };
	};
	Category = "Fun"
})
PLUGIN:RequestQuickmenuSlot( "uncolor", "Uncolor" )

function PLUGIN:Color( self, ply, r, g, b )
	
	if not ply._OldColor then -- We only want to do this once, so we grab the first color he "spawns" with.
		ply._OldColor = ply:GetPlayerColor()
	end
	ply:SetPlayerColor( Vector(r, g, b) )
	
	return {
		Activator = self,
		Player = ply,
		Wording = " has colored ",
		Secondary = " with " .. r .. ", " .. g .. ", " .. b 
	}
	
end
PLUGIN:AddCommand( "color", {
	Call = PLUGIN.Color,
	Desc = "Allows users to color players.",
	Console = { "color" },
	Chat = { "!color" },
	Arguments = {
		{ Name = "Victim", Type = COMMAND_PLAYER };
		{ Name = "Red", Type = COMMAND_NUMER, Optional = 255 };
		{ Name = "Green", Type = COMMAND_NUMBER, Optional = 255 };
		{ Name = "Blue", Type = COMMAND_NUMBER, Optional = 255 };
	};
	Category = "Fun"
})
PLUGIN:RequestQuickmenuSlot( "color", "Color", {
		Red = {
			{ Display = "50" },
			{ Display = "100" },
			{ Display = "150" },
			{ Display = "200" },
			{ Display = "255" },
		},
		Green = {
			{ Display = "50" },
			{ Display = "100" },
			{ Display = "150" },
			{ Display = "200" },
			{ Display = "255" },
		},
		Blue = {
			{ Display = "50" },
			{ Display = "100" },
			{ Display = "150" },
			{ Display = "200" },
			{ Display = "255" },
		},
	} )

PLUGIN:Register()
