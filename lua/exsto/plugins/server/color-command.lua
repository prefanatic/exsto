-- Prefan Access Controller
-- Color'or Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Color Changer",
	ID = "color",
	Desc = "A plugin that allows changing color of players!",
	Owner = "Prefanatic",
} )

function PLUGIN:Color( self, ply, r, g, b )

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
	Desc = "Allows users to color people and make pink babies.",
	Console = { "color" },
	Chat = { "!color" },
	ReturnOrder = "Victim-Red-Green-Blue",
	Args = {Victim = "PLAYER", Red = "NUMBER", Green = "NUMBER", Blue = "NUMBER"},
	Optional = {Red = 255, Green = 255, Blue = 255},
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
