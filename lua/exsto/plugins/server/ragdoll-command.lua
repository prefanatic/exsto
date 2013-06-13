-- Exsto
-- Ragdoll Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Ragdoll Plugin",
	ID = "ragdoll",
	Desc = "A plugin that allows ragdolling players.",
	Owner = "Prefanatic",
} )

function PLUGIN:ExCommandCalled( id, plug, caller, ... )
	local arg = {...}
	if type( arg[1] ) == "Player" and arg[1].ExRagdolled then
		if id == "jail" or id == "rocket" or id == "slay" or id == "slap" then return false, { COLOR.NAME, args[1]:Nick(), COLOR.NORM, " is ", COLOR.NAME, "ragdolled!" } end
		if id == "kick" or id == "ban" then if ply.ExRagdoll and ply.ExRagdoll:IsValid() then ply.ExRagdoll:Remove() end end
	end
end

function PLUGIN:CanPlayerSuicide( ply )
	if ply.ExRagdolled then return false end
end

function PLUGIN:PlayerDisconnected( ply )
	if ply.ExRagdoll and ply.ExRagdoll:IsValid() then ply.ExRagdoll:Remove() end
end

function PLUGIN:PlayerSpawn( ply )
	if ply.ExRagdolled then
		if ply.ExRagdoll and ply.ExRagdoll:IsValid() then
			ply.ExRagdoll:Remove()
		end
		
		ply:UnSpectate()
		for _, wep in ipairs( ply.ExRagdoll_Weps ) do
			if wep and wep:IsValid() then
				ply:Give( wep:GetClass() )
			end
		end
		ply:SetParent()
		ply.ExRagdolled = false
	end
end

function PLUGIN:Ragdoll( self, ply )

	if !ply.ExRagdolled then
		ply.ExRagdolled = true
		ply.ExRagdoll_Angle = ply:GetAngles()
		
		ply.ExRagdoll_Weps = ply:GetWeapons()
		ply:StripWeapons()
		
		local vel = ply:GetVelocity()
		local doll = ents.Create( "prop_ragdoll" )
			doll:SetModel( ply:GetModel() )
			doll:SetPos( ply:GetPos() )
			doll:SetAngles( ply:GetAngles() )
			doll:Spawn()
			doll:Activate()
			
			for I = 1, 14 do
				doll:GetPhysicsObjectNum( I ):SetVelocity( vel )
			end
			
		ply.ExRagdoll = doll
		ply:SpectateEntity( doll )
		ply:Spectate( OBS_MODE_CHASE )
		ply:SetParent( doll )
		
		return {
			Activator = self,
			Player = ply,
			Wording = " has ragdolled "
		}
	else
		ply.ExRagdolled = false
		
		ply:UnSpectate()
		for _, wep in ipairs( ply.ExRagdoll_Weps ) do
			if wep and wep:IsValid() then
				ply:Give( wep:GetClass() )
			end
		end
		ply:SetParent()
		ply:Spawn()
		ply:SetPos( ply.ExRagdoll:GetPos() )
		ply:SetVelocity( ply.ExRagdoll:GetVelocity() )
		ply:SetEyeAngles( Angle( 0, ply.ExRagdoll:GetAngles().yaw, 0 ) )
		
		if ply.ExRagdoll and ply.ExRagdoll:IsValid() then ply.ExRagdoll:Remove() end
	
		return {
			Activator = self,
			Player = ply,
			Wording = " has unragdolled "
		}
	end
end
PLUGIN:AddCommand( "ragdoll", {
	Call = PLUGIN.Ragdoll,
	Desc = "Allows users to ragdoll players.",
	Console = { "ragdoll", "unragdoll", },
	Chat = { "!ragdoll", "!unragdoll" },
	ReturnOrder = "Victim",
	Args = { Victim = "PLAYER" },
	Category = "Fun"
})
PLUGIN:RequestQuickmenuSlot( "ragdoll", "Ragdoll" )

PLUGIN:Register()
