-- Prefan Access Controller
-- Goto and Bring

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Weapon Stripping Functions",
	ID = "weapon-strip",
	Desc = "A plugin that contains weapon related functions!",
	Owner = "Prefanatic",
} )

function PLUGIN:Return( self, victim )
	
	if !victim.OldWeapons then
		return {
			self, COLOR.NAME, victim:Nick(), COLOR.NORM, " does not have any weapons to return!"
		}
	end
	
	for k,v in pairs( victim.OldWeapons ) do
		victim:Give( v )
	end
	
	victim.OldWeapons = nil

	return {
		Activator = self,
		Player = victim,
		Wording = " has given weapons back to "
	}
end
PLUGIN:AddCommand( "returnweps", {
	Call = PLUGIN.Return,
	Desc = "Allows users to return players their weapons.",
	Console = { "return" },
	Chat = { "!return" },
	ReturnOrder = "Victim",
	Args = { Victim = "PLAYER" },
	Optional = { },
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "returnweps", "Return Weapons" )

function PLUGIN:Give( self, victim, weapon )
	if string.find( weapon, "npc", 1, true ) then
		return { self, COLOR.NORM, "You cannot give yourself ", COLOR.NAME, "npcs", COLOR.NORM, "!" }
	end
	
	victim:Give( weapon )
	
	return { COLOR.NAME, self:Nick(), COLOR.NORM, " has given ", COLOR.NAME, victim:Nick(), COLOR.NORM, " a " .. weapon }
end
PLUGIN:AddCommand( "give", {
	Call = PLUGIN.Give,
	Desc = "Allows users to give weapons.",
	Console = { "give" },
	Chat = { "!give" },
	ReturnOrder = "Victim-Weapon",
	Args = { Victim = "PLAYER", Weapon = "STRING" },
	Optional = { },
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "give", "Give", {
	Weapon = {
		{ Display = "AK-47", Data = "weapon_ak47" },
		{ Display = "Deagle", Data = "weapon_deagle" },
		{ Display = "FiveSeven", Data = "weapon_fiveseven" },
		{ Display = "Glock", Data = "weapon_glock" },
		{ Display = "M4", Data = "weapon_m4" },
		{ Display = "MP5", Data = "weapon_mp5" },
		{ Display = "Para", Data = "weapon_para" },
		{ Display = "PumpShotgun", Data = "weapon_pumpshotgun" },
		{ Display = "TMP", Data = "weapon_tmp" },
		{ Display = "Mac10", Data = "weapon_mac10" },
	},
} )

function PLUGIN:Strip( self, victim )
	victim.OldWeapons = {}
	
	for k,v in pairs( victim:GetWeapons() ) do
		table.insert( victim.OldWeapons, v:GetClass() )
	end
	
	victim:StripWeapons()
	
	return {
		Activator = self,
		Player = victim,
		Wording = " has taken all weapons from "
	}
end
PLUGIN:AddCommand( "stripweps", {
	Call = PLUGIN.Strip,
	Desc = "Allows users to strip players of weapons.",
	Console = { "strip" },
	Chat = { "!strip" },
	ReturnOrder = "Victim",
	Args = { Victim = "PLAYER" },
	Optional = { },
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "stripweps", "Strip Weapons" )

PLUGIN:Register()