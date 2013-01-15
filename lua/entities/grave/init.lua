
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( 'shared.lua' )

function ENT:Initialize()

	self:SetModel( "models/props_c17/gravestone00" .. math.random( 1, 4 ) .. "a.mdl" )
	self:PhysicsInit( SOLID_NONE )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	
end

function ENT:SpawnFunction( ply, tr )

	local ent = ents.Create( "grave" )
		ent:SetPos( tr.HitPos + Vector( 0, 0, 50 ) )
		ent:Spawn()
		
		return ent
		
end