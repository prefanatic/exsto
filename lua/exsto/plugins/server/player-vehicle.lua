--Exsto Vehicle commands

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Vehicle Plugins",
	ID = "vechiles",
	Desc = "A plugin that allows entering and exiting vehicles through commands.",
	Owner = "Hobo",
})

function PLUGIN:Enter( owner, ply )
	if !owner:EntIndex() then
		Msg("You cannot force a player into a vehicle through console.")
		return
	end
	
    Vehicle = owner:GetEyeTrace().Entity
	if Vehicle:IsVehicle() then
		ply:EnterVehicle(Vehicle)
	else
		return { owner,COLOR.NORM,"You're not aiming at a vehicle" }
	end
	return { COLOR.NAME,owner,COLOR.NORM," put ",COLOR.NAME,ply:Nick(),COLOR.NORM," in a vehicle!" }
end		
PLUGIN:AddCommand( "enter", {
	Call = PLUGIN.Enter,
	Desc = "Forces a player into a vehicle",
	Console = { "enter" },
	Chat = { "!enter" },
    ReturnOrder = "Player",
    Args = { Player = "PLAYER" },
	Category = "Fun",
})

function PLUGIN:Exit( owner, ply )
    if ply:InVehicle() then
		ply:ExitVehicle()
	else
		return { owner,COLOR.NAME,ply:Nick(),COLOR.NORM," is not in a vehicle." }
	end
	return { COLOR.NAME,owner,COLOR.NORM," kicked ",COLOR.NAME,ply:Nick(),COLOR.NORM," out of a vehicle!" }
end		
PLUGIN:AddCommand( "exit", {
	Call = PLUGIN.Exit,
	Desc = "Forces a player out of a vehicle",
	Console = { "exit" },
	Chat = { "!exit" },
    ReturnOrder = "Player",
    Args = { Player = "PLAYER" },
	Category = "Fun",
})

PLUGIN:Register()