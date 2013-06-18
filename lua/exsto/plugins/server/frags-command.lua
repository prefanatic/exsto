--Created for Exsto by Shank - http://steamcommunity.com/nicatronTg

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	ID = "exsto-deathsfrags",
	Name = "Frag and Death editor",
	Disc = "Change a player's frags and deaths!",
	Owner = "Shank",
})

if !SERVER then return end

function PLUGIN.Frags(self, ply, target, frags)
	target:SetFrags(frags)
	return {
		Activator = ply,
		Player = target,
		Wording = " set the kills of ",
		Secondary = " to "..frags
	}
end

function PLUGIN.Deaths(self, ply, target, deaths)
	target:SetDeaths(deaths)
	return {
		Activator = ply,
		Player = target,
		Wording = " set the deaths of ",
		Secondary = " to "..deaths
	}
end

PLUGIN:AddCommand( "setfrags", {
	Call = PLUGIN.Frags,
	Desc = "Allows a player to set someone's frags",
	Console = { "setfrags", },
	Chat = { "!setfrags" },
	ReturnOrder = "Target-Kills",
	Optional = { Kills = 0 },
	Args = {Target="PLAYER", Kills="NUMBER"},
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "setfrags", "Set Kills", {
	Kills = {
		{ Display = "1 kill", Data = 1 },
		{ Display = "2 kills", Data = 2 },
		{ Display = "5 kills", Data = 5 },
		{ Display = "10 kills", Data = 10 },
	},
} )
	
PLUGIN:AddCommand( "setdeaths", {
	Call = PLUGIN.Deaths,
	Desc = "Allows a player to set someone's deaths",
	Console = { "exsto_setdeaths", },
	Chat = { "!setdeaths" },
	ReturnOrder = "Target-DeathCount",
	Optional = { DeathCount = 0 },
	Args = {Target="PLAYER", DeathCount="NUMBER"},
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "setdeaths", "Set Deaths", {
	DeathCount = {
		{ Display = "1 death", Data = 1 },
		{ Display = "2 deaths", Data = 2 },
		{ Display = "5 deaths", Data = 5 },
		{ Display = "10 deaths", Data = 10 },
	},
} )

PLUGIN:Register()