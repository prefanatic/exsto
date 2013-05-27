-- Prefan Access Controller
-- Rocket Man Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Rocket Man",
	ID = "rocket-man",
	Desc = "A plugin that allows rocketing and igniting of players.",
	Owner = "Prefanatic",
} )

function PLUGIN:Init()
	self.Rocketeers = {}
end

function PLUGIN:Ignite( owner, ply, duration, radius )
	ply:Ignite( duration, radius )
	
	return {
		Activator = owner,
		Player = ply,
		Wording = " has ignited ",
	}
end
PLUGIN:AddCommand( "ignite", {
	Call = PLUGIN.Ignite,
	Desc = "Allows users to ignite other players.",
	Console = { "ignite" },
	Chat = { "!ignite", "!fire" },
	ReturnOrder = "Victim-Duration-Radius",
	Args = {Victim = "PLAYER", Duration = "NUMBER", Radius = "NUMBER"},
	Optional = {Duration = 10, Radius = 50},
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "ignite", "Ignite", {
	Duration = {
		{ Display = "Instant", Data = 0 },
		{ Display = "5 seconds", Data = 5 },
		{ Display = "10 seconds", Data = 10 },
		{ Display = "20 seconds", Data = 20 },
		{ Display = "30 seconds", Data = 30 },
		{ Display = "1 minute", Data = 60 },
	},
	Radius = {
		{ Display = "5 units", Data = 5 },
		{ Display = "5 units", Data = 5 },
		{ Display = "10 units", Data = 10 },
		{ Display = "20 units", Data = 20 },
		{ Display = "30 units", Data = 30 },
		{ Display = "60 units", Data = 60 },
	}
} )

function PLUGIN:PlayerNoClip( ply )
	if ply.IsRocket then return false end
end

function exsto.Registry.Player:RocketExplode()
	self.Stage = 3
	local explode = ents.Create( "env_explosion" )
		explode:SetPos( self:GetPos() )
		explode:SetOwner( self )
		explode:Spawn()
		explode:Fire( "Explode", 0, 0 )
		
	self:StopParticles()
	self:KillSilent()
	self.IsRocket = false
	
	for _, ply in ipairs( PLUGIN.Rocketeers ) do
		if ply.Player == self then
			ply.Text:Remove()
			table.remove( PLUGIN.Rocketeers, _ )
			break
		end
	end

end

function exsto.Registry.Player:RocketPrep()
	if self:InVehicle() then self:ExitVehicle() end
	self:SetMoveType(MOVETYPE_WALK)  -- We want him to actually move.
	-- Set his pos just high enough so we can smooth launch.
	self:SetVelocity( Vector( 0, 0, 0 ) )
	self:EmitSound( "buttons/button1.wav" )
	self:SetPos( self:GetPos() + Vector( 0, 0, 60 ) )
	ParticleEffectAttach( "fire_medium_01", PATTACH_ABSORIGIN_FOLLOW, self, 0 )
	ParticleEffectAttach( "embers_medium_01", PATTACH_ABSORIGIN_FOLLOW, self, 0 )
	timer.Create( "ExRocket" .. self:EntIndex(), 6, 1, function() self:RocketExplode() end )
end

--[[ Stages
	1 = Waiting
	2 = Launching
	3 = Done
]]

function PLUGIN:Think()
	for _, ply in pairs( self.Rocketeers ) do
		
		if ply.Stage == 1 then
			if ply.NextRocketTick <= CurTime() then
				ply.NextRocketTick = CurTime() + 1
				
				if ply.Delay <= 0 then
					ply.NextRocketTick = CurTime() - 1
					
					ply.Player:RocketPrep()
					ply.Stage = 2
				else
					if ply.Player:Health() <= 0 then
						print( "DEAD" )
						ply.Player.IsRocket = false
						ply.Text:Remove()
						table.remove( self.Rocketeers, _ )
						return
					end
					ply.Delay = ply.Delay - 1
					ply.Text:SetText( "Liftoff in " .. ply.Delay )
					ply.Player:EmitSound( "buttons/blip1.wav" )
				end
			end
		elseif ply.Stage == 2 then -- We are flying!
			if ply.NextRocketTick <= CurTime() then
				ply.NextRocketTick = CurTime() + 0.1
				ply.Player:SetVelocity( ply.RandomLaunchVec )
				ply.RandomLaunchVec.z = ply.RandomLaunchVec.z + 3
				ply.NumberTicksSinceLaunch = ply.NumberTicksSinceLaunch + 1
				
				-- If we hit something, stop
				if ply.Player:GetVelocity().z <= 60 and ply.NumberTicksSinceLaunch >= 20 or ply.Player:Health() <= 0 then 
					timer.Destroy( "ExRocket" .. ply.Player:EntIndex() )
					ply.Player:RocketExplode()
				end
			end
		end
		
	end
end

function PLUGIN:RocketMan( owner, ply, delay )
	local text = ents.Create( "3dtext" )
		text:SetPos( ply:GetPos() + Vector( 0, 0, 80 ) )
		text:SetAngles( Angle( 0, 0, 0 ) )
		text:Spawn()
		text:SetPlaceObject( ply )
		text:SetText( "Liftoff in " .. delay )
		text:SetScale( 0.1 )
		text:SetParent( ply )
		
	ply.IsRocket = true
	ply:SetMoveType( MOVETYPE_WALK )
	
	table.insert( self.Rocketeers, {
		Player = ply,
		Stage = 1,
		Text = text,
		Delay = delay,
		NextRocketTick = 0,
		RandomLaunchVec = Vector( 0, 0, 80 ),
		NumberTicksSinceLaunch = 0
	} )
	
	return { COLOR.NAME, owner:Nick(), COLOR.NORM, " has scheduled ", COLOR.NAME, ply:Nick(), COLOR.NORM, " to be launched into space!" }
	
end
PLUGIN:AddCommand( "rocketman", {
	Call = PLUGIN.RocketMan,
	Desc = "Allows users to explode other players.",
	Console = { "rocket" },
	Chat = { "!rocket" },
	ReturnOrder = "Victim-Delay",
	Args = {Victim = "PLAYER", Delay = "NUMBER"},
	Optional = { Delay = 0 },
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "rocketman", "Rocket", {
	Delay = {
		{ Display = "Instant", Data = 0 },
		{ Display = "5 seconds", Data = 5 },
		{ Display = "10 seconds", Data = 10 },
		{ Display = "20 seconds", Data = 20 },
		{ Display = "30 seconds", Data = 30 },
		{ Display = "1 minute", Data = 60 },
	}
} )

PLUGIN:Register()
