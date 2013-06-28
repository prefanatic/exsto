-- Prefan Access Controller
-- Grave Death Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Worms Graves",
	ID = "grave-death",
	Desc = "A plugin that creates graves when you die!",
	Owner = "Prefanatic",
} )

function PLUGIN:Init()

	self.Enabled = exsto.CreateVariable( "ExGraveEnabled",
		"Enabled",
		0,
		"Determines if graves fall on player deaths."
	)
	self.Enabled:SetCategory( "Graves" )
	self.Enabled:SetBoolean()

	self.Style = exsto.CreateVariable( "ExGraveStyle",
		"Style",
		"leaveonspawn",
		"How the grave leaves after falling.\n - 'fade' : Fades on leave.\n - 'sink' : Sinks into the ground.\n - 'leaveonspawn' : Stays until the user spawns."
	)
	self.Style:SetCategory( "Graves" )
	self.Style:SetPossible( "fade", "sink", "leaveonspawn" )
	
	self.SinkRate = exsto.CreateVariable( "ExGraveSinkRate",
		"Sink Rate",
		5,
		"Sets how long the graves should wait until they sink, if 'sink' is set."
	)
	self.SinkRate:SetCategory( "Graves" )
	self.SinkRate:SetUnit( "Time (seconds)" )
	
	local function parse( old, new )
		local f = string.Explode( ":", new )
		if f[ 1 ] == "file" then -- We're a file ;D
			local data = file.Read( f[ 2 ], "DATA" )
			self.RandomDeathMessages = string.Explode( "\n", data )
			self:Debug( "Loaded messages from file.", 1 )
		else -- Assume HTTP.
			http.Fetch( new, function( contents )
				self.RandomDeathMessages = string.Explode( "\n", contents )
				self:Debug( "Loaded messages from HTTP.", 1 )
			end )
		end
	end
	
	self.Messages = exsto.CreateVariable( "ExGraveMessageLocation",
		"Message Location",
		"http://dl.dropbox.com/u/717734/Exsto/DO%20NOT%20DELETE/deathmessages.txt",
		"Where the graves messages are located.  Can be HTTP or a file.  If a file, type file: before the location, like file:gravedeath.txt if located in the data folder."
	)
	self.Messages:SetCategory( "Graves" )
	self.Messages:SetCallback( parse )
	
	self.RandomDeathMessages = { "He couldn't load the death messages file." }
	
	function self.ExGamemodeFound() parse( nil, self.Messages:GetValue() ) end
	
end

function PLUGIN:PlayerSpawn( ply )
	if ply.HasGrave then
		if ply.HasGrave:IsValid() then
			ply.HasGrave:Remove() 
			ply.HasGrave = nil
		end
	end
	
	if ply.GraveData then
		if ply.GraveData.Text:IsValid() then ply.GraveData.Text:Remove() end
		if ply.GraveData.Ent:IsValid() then ply.GraveData.Ent:Remove() end
		if ply.GraveData.Message:IsValid() then ply.GraveData.Message:Remove() end
		
		ply.GraveData = nil
	end
end

local function BuildWormsMessage( ent, ply )

	if !ply.GraveData then
		local text = ents.Create( "3dtext" )
			text:SetPos( ent:GetPos() + Vector( 0, 0, ( ent.Height / 2 ) + 13 ) )
			text:SetAngles( Angle( 0, 0, 0 ) )
			text:Spawn()
			text:SetPlaceObject( ent )
			text:SetText( "Here lies " .. ply:Nick() )
			text:SetScale( 0.05 )
			
		local message = ents.Create( "3dtext" )
			message:SetPos( ent:GetPos() + Vector( 0, 0, ( ent.Height / 2 ) + 6 ) )
			message:SetAngles( Angle( 0, 0, 0 ) )
			message:Spawn()
			message:SetPlaceObject( ent )
			message:SetText( PLUGIN.RandomDeathMessages[math.random( 1, #PLUGIN.RandomDeathMessages )]  )
			message:SetScale( 0.05 )
			
		
		ply.GraveData = { Text = text, Ent = ent, Message = message }
	end
	hook.Remove( "Think", tostring( ent ) .. "THINK" )
	
end

local function Sink( ent )

	if ent.FallenTime + tonumber( PLUGIN.SinkRate:GetValue() ) < CurTime() then
		
		local pos = ent:GetPos()
		local to = ent.HitPos.z - ( ent.Height )
		
		local dist = pos.z - to
		local speed = dist / 20
		
		
		if pos.z < to then
		
			hook.Remove( "Think", tostring( ent ) .. "THINK" )
			
			ent:Remove()
			
		else
		
			ent:SetPos( Vector( pos.x, pos.y, pos.z - speed ) )
		
		end
		
	end
	
end

local function Fade( ent )

	local r, g, b, a = ent:GetColor()
	local alpha = a - 1

	if alpha <= 1 then
	
		hook.Remove( "Think", tostring( ent ) .. "THINK" )
		
		ent:Remove()
		
	else

		ent:SetColor( r, g, b, alpha )
		
	end
	
end

function PLUGIN:PlayerDisconnected( ply )
	if ply.HasGrave then
		if ply.HasGrave:IsValid() then
			ply.HasGrave:Remove() 
			ply.HasGrave = nil
		end
	end
	
	if ply.GraveData then
		if ply.GraveData.Text:IsValid() then ply.GraveData.Text:Remove() end
		if ply.GraveData.Ent:IsValid() then ply.GraveData.Ent:Remove() end
		if ply.GraveData.Message:IsValid() then ply.GraveData.Message:Remove() end
		
		ply.GraveData = nil
	end
end

function PLUGIN:PlayerDeath( victim, _, killer )

	if self.Enabled:GetValue() == 0 then return end
	if victim.HasGrave then return end
	
	local opos = victim:GetPos()
	local trace = {}
		trace.start = opos
		trace.endpos = opos - Vector( 0, 0, 5000 )
		
	local hitpos = util.TraceLine( trace ).HitPos
	local spos = opos + Vector( 0, 0, 2000 )
	
	local start = CurTime()
	local nextr = 0
	
	local ent = ents.Create( "prop_physics" )
	
		ent:SetModel( "models/props_c17/gravestone00" .. math.random( 1, 4 ) .. "a.mdl" )
	
		ent:Spawn()
		ent:Activate()
		
		ent:PhysicsInit( SOLID_NONE )
		ent:SetMoveType( MOVETYPE_NONE )
		ent:SetSolid( SOLID_NONE )
		
		ent:SetPos( spos )
		
		ent.MinZ = ent:OBBMins().z
		ent.MaxZ = ent:OBBMaxs().z
		ent.Height = ( ent.MinZ * -1 ) + ent.MaxZ
		
	victim.HasGrave = ent
		
	local function entThink()
		if ent and ent:IsValid() then
		
			local dist = hitpos:Distance( ent:GetPos() )
			local speed = dist / 30
			
			if not ent.Fallen then
			
				if dist < ( ent.MinZ * -1 ) then
					
					ent:EmitSound( "physics/concrete/boulder_impact_hard" .. math.random( 1, 4 ) .. ".wav" )
					
					ent.Fallen = true
					ent.FallenTime = CurTime()
					ent.HitPos = ent:GetPos()
					
					--[[
					local effect = EffectData()
						effect:SetOrigin( ent:GetPos() )
						effect:SetStart( ent:GetPos() )
						effect:SetMagnitude( 10 )
					
					util.Effect( "grave_fall", effect )]]
					
				else
					
					ent:SetPos( ent:GetPos() - Vector( 0, 0, 1 * speed ) )
					
				end
				
			elseif ent.Fallen then

				if self.Style:GetValue() == "fade" then Fade( ent ) end
				if self.Style:GetValue() == "sink" then Sink( ent ) end
				if self.Style:GetValue() == "leaveonspawn" then BuildWormsMessage( ent, victim ) end
				
			end
			
		else
			hook.Remove( "Think", tostring( ent ) .. "THINK" )
			return
		end
		
	end
	hook.Add( "Think", tostring( ent ) .. "THINK", entThink )
	
end
 
PLUGIN:Register()
