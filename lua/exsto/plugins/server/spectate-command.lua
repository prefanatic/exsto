-- Exsto
-- Spectate Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Spectate",
	ID = "spectate",
	Desc = "A plugin that allows spectating other players!",
	Owner = "Prefanatic",
} )

function PLUGIN:KeyPress( ply, key )
	if ply.Spectating and key == IN_JUMP then
		ply:UnSpectate()
		ply:KillSilent()
		ply:Spawn()
		ply:SetPos( ply.StartSpectatePos )
		
		for k,v in pairs( ply.Weapons ) do
			ply:Give( tostring( v ) )
		end		

		ply.Spectating = false
		return { ply, COLOR.NORM, "You have stopped ", COLOR.NAME, "specatating", COLOR.NORM, "!" }
	end
end

function PLUGIN:UnSpectate( owner )
	if not owner.Spectating then
		owner:Print( exsto_CHAT, COLOR.NORM, "You are not spectating ", COLOR.NAME, "anyone." )
		return
	end
	
	owner:UnSpectate()
	owner:KillSilent()
	owner:Spawn()
	owner:SetPos( owner.StartSpectatePos )
	
	for k,v in pairs( owner.Weapons ) do
		owner:Give( tostring( v ) )
	end		

	owner.Spectating = false
	return { owner, COLOR.NORM, "You have stopped ", COLOR.NAME, "specatating", COLOR.NORM, "!" }
end
PLUGIN:AddCommand( "unspectate", {
	Call = PLUGIN.UnSpectate,
	Desc = "Allows users to unspectate a person.",
	Console = { "unspectate", "unspec" },
	Chat = { "!unspec", "!unspectate" },
	Category = "Administration",
})
PLUGIN:RequestQuickmenuSlot( "unspectate", "Unspectate" )

function PLUGIN:Spectate( owner, ply )

	if owner.Spectating then
		owner:Print( exsto_CHAT, COLOR.NORM, "You are already spectating." )
		return
	end
	if ply.Spectating then return { owner, COLOR.NAME, ply:Nick(), COLOR.NORM, " is currently not availible for spectate!" } end
	
	owner.Weapons = {}
	
	for k,v in pairs( owner:GetWeapons() ) do
		table.insert( owner.Weapons, v:GetClass() )
	end
	
	owner:StripWeapons()
	
	owner.Spectating = true
	owner.StartSpectatePos = owner:GetPos()
	
	owner:Spectate( OBS_MODE_CHASE )
	owner:SpectateEntity( ply )
	
	return { owner, COLOR.NORM, "You are now spectating ", COLOR.NAME, ply:Nick(), COLOR.NORM, "!" }
	
end
PLUGIN:AddCommand( "spectate", {
	Call = PLUGIN.Spectate,
	Desc = "Allows users to spectate a person.",
	Console = { "spectate", "spec" },
	Chat = { "!spec", "!spectate" },
	Arguments = {
		{ Name = "Victim", Type = COMMAND_PLAYER };
	};
	Category = "Administration",
})
PLUGIN:RequestQuickmenuSlot( "spectate", "Spectate" )

PLUGIN:Register()
