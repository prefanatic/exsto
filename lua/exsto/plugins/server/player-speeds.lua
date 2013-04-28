--Created for Exsto by Shank - http://steamcommunity.com/nicatronTg

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	ID = "exsto-speed",
	Name = "Speed",
	Disc = "Set a player's run and walk speed, with the addition of jump power!",
	Owner = "Shank",
})

if !SERVER then return end

function PLUGIN.RunSpeed(self, ply, target, speed)
	local newspeed = math.Clamp(speed, 1, 10000000000000000000)
	target:SetRunSpeed(newspeed)
	
	return {
		Activator = ply,
		Player = target,
		Wording = " has changed the run speed of ",
		Secondary = " to "..newspeed
	}
end

function PLUGIN.WalkSpeed(self, ply, target, speed)
	local newspeed = math.Clamp(speed, 1, 10000000000000000000)
	target:SetWalkSpeed(newspeed)
	
	return {
		Activator = ply,
		Player = target,
		Wording = " has changed the walk speed of ",
		Secondary = " to "..newspeed
	}
end

function PLUGIN.JumpPower(self, ply, target, power)
	local newpower = math.Clamp(power, 1, 2000)
	target:SetJumpPower(newpower)
	
	return {
		Activator = ply,
		Player = target,
		Wording = " has changed the jump power for ",
		Secondary = " to "..newpower
	}
end
PLUGIN:AddCommand( "runspeed", {
	Call = PLUGIN.RunSpeed,
	Desc = "Allows users to change player's run speed.",
	Console = { "runspeed" },
	Chat = { "!runspeed" },
	ReturnOrder = "Target-Power",
	Optional = { Power = 500 },
	Args = { Target = "PLAYER", Power = "NUMBER" },
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "runspeed", "Run Speed", {
	Power = {
		{ Display = "200 units", Data = 200 },
		{ Display = "250 units", Data = 250 },
		{ Display = "500 units", Data = 500 },
		{ Display = "750 units", Data = 750 },
		{ Display = "1000 units", Data = 1000 },
	},
} )

PLUGIN:AddCommand( "walkspeed", {
	Call = PLUGIN.WalkSpeed,
	Desc = "Allows users to change player's walk speed.",
	Console = { "walkspeed" },
	Chat = { "!walkspeed" },
	Optional = { Power = 250 },
	ReturnOrder = "Target-Power",
	Args = { Target = "PLAYER", Power = "NUMBER" },
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "walkspeed", "Walk Speed", {
	Power = {
		{ Display = "200 units", Data = 200 },
		{ Display = "250 units", Data = 250 },
		{ Display = "500 units", Data = 500 },
		{ Display = "750 units", Data = 750 },
		{ Display = "1000 units", Data = 1000 },
	},
} )

PLUGIN:AddCommand( "jumppower", {
	Call = PLUGIN.JumpPower,
	Desc = "Allows users to change player's jump power.",
	Console = { "jumppower" },
	Chat = { "!jumppower" },
	Optional = { Power = 100 },
	ReturnOrder = "Target-Power",
	Args = { Target = "PLAYER", Power = "NUMBER" },
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "jumppower", "Jump Height", {
	Power = {
		{ Display = "200 units", Data = 200 },
		{ Display = "250 units", Data = 250 },
		{ Display = "500 units", Data = 500 },
		{ Display = "750 units", Data = 750 },
		{ Display = "1000 units", Data = 1000 },
	},
} )

PLUGIN:Register()