-- Prefan Access Controller
-- Health Related Commands

-- FURST PLUGIN TO USE NEW COMMAND SYSTEM

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Health Related Commands",
	ID = "health-items",
	Desc = "A plugin that contains a bunch of health related commands!",
	Owner = "Prefanatic",
} )

function PLUGIN:SetArmor( self, victim, armor )

	victim:SetArmor( math.Clamp( armor, 1, 99998 ) )
	
	return {
		Activator = self,
		Player = victim,
		Wording = " has set the armor of ",
		Secondary = " to " .. armor,
	}
	
end
PLUGIN:AddCommand( "setarmor", {
	Call = PLUGIN.SetArmor,
	Desc = "Allows users to set the armor of players.",
	Console = { "setarmor" },
	Chat = { "!armor" },
	ReturnOrder = "Victim-Armor",
	Args = { Victim = "PLAYER", Armor = "NUMBER" },
	Optional = { Armor = 100 },
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "setarmor", "Set Armor", {
	Armor = {
		{ Display = "50 points", Data = 50 },
		{ Display = "100 points", Data = 100 },
		{ Display = "150 points", Data = 150 },
		{ Display = "200 points", Data = 200 },
	},
} )

function PLUGIN:SetHealth( self, victim, health )

	victim:SetHealth( math.Clamp( health, 1, 99998 ) )
	
	return {
		Activator = self,
		Player = victim,
		Wording = " has set the health of ",
		Secondary = " to " .. health,
	}
	
end
PLUGIN:AddCommand( "sethealth", {
	Call = PLUGIN.SetHealth,
	Desc = "Allows users to set the health of players.",
	Console = { "sethealth" },
	Chat = { "!health" },
	ReturnOrder = "Victim-Health",
	Args = { Victim = "PLAYER", Health = "NUMBER" },
	Optional = { Health = 100 },
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "sethealth", "Set Health", {
	Health = {
		{ Display = "50 points", Data = 50 },
		{ Display = "100 points", Data = 100 },
		{ Display = "150 points", Data = 150 },
		{ Display = "200 points", Data = 200 },
	},
} )

PLUGIN:Register()