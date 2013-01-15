-- Exsto
-- Slap Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Slap",
	ID = "slap",
	Desc = "Bitch Slap Dat Foo",
	Owner = "Prefanatic and Schuyler",
} )

local function Slap( ply, damage )
	ply:SetMoveType(MOVETYPE_WALK)
	if !ply:Alive() then timer.Create( "exsto_WhipDelay"..ply:Nick(), 0.1, 1, function() end ) return end
	local xspeed = math.random( -500, 500 )
	local yspeed = math.random( -500, 500 ) 
	local zspeed = math.random( -500, 500 )
	ply:SetVelocity( Vector( xspeed, yspeed, zspeed ) )
	ply:SetHealth( ply:Health() - damage )

	if ply:InVehicle() then ply:ExitVehicle() end 
	if ply:Health() <= 0 then ply:Kill() end
	ply:EmitSound( "player/pl_fallpain3.wav", 100, 100 )
end

function PLUGIN:Slap( owner, ply, damage, duration, delay )
	
	if duration == 1 then
		Slap( ply, damage )
		return {
			Activator = owner,
			Player = ply,
			Wording = " has slapped ",
		}
	elseif duration > 1 then	
		timer.Create( "exsto_WhipDelay"..ply:Nick(), delay, duration, function() Slap( ply, damage ) end )
		return {
			Activator = owner,
			Player = ply,
			Wording = " is whipping ",
			Secondary = " " .. duration .. " times",
		}
	end
	
end
PLUGIN:AddCommand( "slap", {
	Call = PLUGIN.Slap,
	Desc = "Allows users to slap other players.",
	Console = { "slap" },
	Chat = { "!slap", "!whip" },
	ReturnOrder = "Victim-Damage-Duration-Delay",
	Args = {Victim = "PLAYER", Damage = "NUMBER", Duration = "NUMBER", Delay = "NUMBER"},
	Optional = {Damage = 10, Duration = 1, Delay = 0.7},
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "slap", "Slap", {
	Damage = {
		{ Display = "1 health", Data = 1 },
		{ Display = "10 health", Data = 10 },
		{ Display = "50 health", Data = 50 },
		{ Display = "100 health", Data = 100 },
		{ Display = "200 health", Data = 200 },
	},
	Duration = {
		{ Display = "1 time", Data = 1 },
		{ Display = "5 times", Data = 5 },
		{ Display = "10 times", Data = 10 },
		{ Display = "50 times", Data = 50 },
		{ Display = "100 times", Data = 100 },
	},
	Delay = {
		{ Display = "1 half of a second", Data = 0.5 },
		{ Display = "Default", Data = 0.7 },
		{ Display = "1 second interval", Data = 1 },
		{ Display = "5 second interval", Data = 5 },
	},
} )

PLUGIN:Register()
