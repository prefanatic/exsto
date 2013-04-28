-- Exsto
-- Player Pickup

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Player Pickup",
	ID = "player-pickup",
	Desc = "A plugin that allows picking up other players!",
	Owner = "Prefanatic",
} )

exsto.CreateFlag( "playerpickup", "Allows users to pick up other players with the phys gun." )

function PLUGIN:PhysgunPickup( ply, ent )

	if ent == ply then return false end
	
	if ent:IsPlayer() and ply:IsAllowed( "playerpickup", ent ) then
	
		--ent:Freeze( true )
		ent:SetMoveType( MOVETYPE_NOCLIP )
		
		return true
		
	end
		
end

function PLUGIN:PhysgunDrop( ply, ent )
	if ent:IsPlayer() then
		ent:SetMoveType(MOVETYPE_WALK)
		--ent:Freeze(false)
	end
end

PLUGIN:Register()