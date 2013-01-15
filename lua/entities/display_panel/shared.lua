ENT.Type = "anim"
ENT.Base = "base_entity"

function ENT:Initialize()

	if SERVER then
	
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
		
		local phys = self:GetPhysicsObject()
		
		if phys then
		
			phys:Wake()
			phys:EnableMotion( false )
			
		end
		
	end
	
end

-- Sets correct physics after build
function ENT:SetPhysics()

	if CLIENT then return end
	
	self:SetCollisionGroup( COLLISION_GROUP_NONE )
	
end