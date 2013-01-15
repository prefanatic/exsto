EFFECT.Particles = 40
EFFECT.Mat = "particle/particle_smokegrenade"
EFFECT.Emitter = false

local mat = CreateConVar( "grave_mat", EFFECT.Mat, FCVAR_NOTIFY )

function EFFECT:Init( data )

	--print( "Using effect " .. self.Mat )

	self.Pos = data:GetOrigin()
	
	self.Emitter = ParticleEmitter( self.Pos )
	
	for I = 1, self.Particles do
	
		local particle = self.Emitter:Add( mat:GetString(), self.Pos + VectorRand() * 5 )
		
		particle:SetColor( 255, 255, 255 )
		
		particle:SetStartSize( math.Rand ( 3, 8 ) )
		particle:SetEndSize( 0 )
		
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		
		particle:SetDieTime( math.Rand( 5, 10 ) )
		particle:SetVelocity( VectorRand() * 10 - Vector( 0, 0, 10 ) )
		
		particle:SetBounce( 1 )
		particle:SetGravity( Vector( 0, 0, -10 ) )
		
		particle:SetCollide(true)
		particle:SetCollideCallback(function( particle, pos, norm )
			--print( "weeeehh" )
			local x = math.random( -70, 70 )
			local y = math.random( -70, 70 )
			
			local vel = Vector( x, y, 10 )
			--print( vel )
			particle:SetVelocity( vel )
			particle:SetGravity( Vector( 0, 0, 0 ) )
			particle:SetDieTime( math.Rand( 10, 15 ) )
		end)
		
	end
	
end

function EFFECT:Think()
	
	return true
	
end

function EFFECT:Render()
	
end