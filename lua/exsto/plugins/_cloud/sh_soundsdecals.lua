--Created for Exsto by Shank - http://steamcommunity.com/nicatronTg

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	ID = "exsto-decalsandsounds",
	Name = "Decals and sounds",
	Disc = "Clear decals, stop sounds.",
	Owner = "Shank",
})

if !SERVER then 
usermessage.Hook("exsto_cleardecals", function()
	RunConsoleCommand("r_ClearDecals")
end)

usermessage.Hook("exsto_stopsounds", function()
	RunConsoleCommand("stopsounds")
end)
end

function PLUGIN.ClearDecals(self, ply)
	local rp = RecipientFilter()
	rp:AddAllPlayers()
	umsg.Start("exsto_cleardecals", rp)
	umsg.End()
	
	return {
		Activator = ply,
		Player = "all",
		Wording = " cleared ",
		Secondary = " decals"
	}
end

PLUGIN:AddCommand( "decals", {
	Call = PLUGIN.ClearDecals,
	Desc = "Allows a player to clear all player's decals",
	Console = { "decals", },
	Chat = { "!decals" },
	Args = {},
	Category = "Utilities",
})

function PLUGIN.StopSounds(self, ply)
	local rp = RecipientFilter()
	rp:AddAllPlayers()
	umsg.Start("exsto_stopsounds", rp)
	umsg.End()
	
	return {
		Activator = ply,
		Player = "all",
		Wording = " stopped ",
		Secondary = " sounds"
	}
end

PLUGIN:AddCommand( "stopsounds", {
	Call = PLUGIN.StopSounds,
	Desc = "Allows a player to stop all sounds on the server",
	Console = { "stopsounds", },
	Chat = { "!stopsounds" },
	Args = {},
	Category = "Utilities",
})

PLUGIN:Register()