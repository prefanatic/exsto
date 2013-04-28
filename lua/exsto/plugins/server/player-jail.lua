-- Prefan Access Controller
-- Jail

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Jail",
	ID = "jail",
	Desc = "A plugin that adds the !jail command.",
	Owner = "Prefanatic",
} )

function PLUGIN:Init()

	self.Model1 = Model( "models/props_c17/fence01b.mdl" )
	self.Model2 = Model( "models/props_c17/fence02b.mdl" )
	self.WallPositions = {
		{ pos = Vector( 35, 0, 60 ), ang = Angle( 0, 0, 0 ), mdl = self.Model2 },
		{ pos = Vector( -35, 0, 60 ), ang = Angle( 0, 0, 0 ), mdl = self.Model2 },
		{ pos = Vector( 0, 35, 60 ), ang = Angle( 0, 90, 0 ), mdl = self.Model2 },
		{ pos = Vector( 0, -35, 60 ), ang = Angle( 0, 90, 0 ), mdl = self.Model2 },
		{ pos = Vector( 0, 0, 110 ), ang = Angle( 90, 0, 0 ), mdl = self.Model1 },
		{ pos = Vector( 0, 0, -5 ), ang = Angle( 90, 0, 0 ), mdl = self.Model1 },
	}
	
	self.JailedLeavers = {}
	
end

function PLUGIN:PlayerNoClip( ply )
	if ply:Jailed() then return false end
end

function PLUGIN:CanTool( ply, tr, tool )
	if tr.Entity.IsJailWall then return false end
	if ply:Jailed() then return false end
end

function PLUGIN:CanProperty( ply, property, ent )
	if ent.IsJailWall then return false end
	if ply:Jailed() then return false end
end

function PLUGIN:PlayerGiveSWEP( ply )
	if ply:Jailed() then return false end
end

function PLUGIN:PlayerSpawnProp( ply )
	if ply:Jailed() then return false end
end

function PLUGIN:PlayerSpawnSENT( ply )
	if ply:Jailed() then return false end
end

function PLUGIN:PlayerSpawnVehicle( ply )
	if ply:Jailed() then return false end
end

function PLUGIN:PlayerSpawnNPC( ply )
	if ply:Jailed() then return false end
end

function PLUGIN:PlayerSpawnEffect( ply )
	if ply:Jailed() then return false end
end

function PLUGIN:PlayerSpawnRagdoll( ply )
	if ply:Jailed() then return false end
end

function PLUGIN:PlayerUse( ply )
	if ply:Jailed() then return false end
end

function PLUGIN:PlayerSpawn( ply )
	if ply:Jailed() then
		ply:MoveToJail()
		timer.Create( "stripSweps"..ply:EntIndex(), 0.1, 1, exsto.Registry.Player.Player.StripWeapons, ply )
	end
end

function PLUGIN:PlayerDisconnected( ply )
	if ply:Jailed() then
		table.insert( self.JailedLeavers, { SteamID = ply:SteamID(), JailPos = ply.JailedPos, OldWeapons = ply.Weapons, Time = ply.JailTime } ) --JailWalls = ply.JailWalls, 
		ply:RemoveJail()
	end
end

function PLUGIN:PlayerInitialSpawn( ply )
	-- PrintTable( self.JailedLeavers )
	for _, obj in ipairs( self.JailedLeavers ) do
		if ply:SteamID() == obj.SteamID then
			-- ply.IsJailed = true
			print(obj.Time)
			
			timer.Simple(0.1,function()
				ply:SetPos(obj.JailPos)
				ply:CreateJail(obj.Time)
				exsto.Print(exsto_CHAT_ALL,COLOR.NAME,ply,COLOR.NORM," previously jailed, rejailing for ",COLOR.NAME,tostring(obj.Time),COLOR.NORM," seconds.")
			end )
			
			-- ply:CreateJail()
			ply.Weapons = obj.OldWeapons
			-- ply:StripWeapons()
			
			-- ply.JailWalls = obj.JailWalls
			
			table.remove( self.JailedLeavers, _ )
			break
		end
	end
end

function PLUGIN:PhysgunPickup( ply, ent )
	if ent.IsJailWall then return false end
end

local removeoncommand = function( ply, callargs )
	if callargs[1]:Jailed() then
		callargs[1]:RemoveJail()
	end
end

function exsto.Registry.Player:Jailed()
	return self.IsJailed
end

function exsto.Registry.Player:MoveToJail()
	if self.JailedPos then
		self:SetPos( self.JailedPos )
	end
end

function exsto.Registry.Player:JailStrip()
	self.Weapons = {}
	for k,v in pairs( self:GetWeapons() ) do
		table.insert( self.Weapons, v:GetClass() )
	end
	self:StripWeapons()
end

function exsto.Registry.Player:JailReturn()
	if type( self.Weapons ) == "table" then
		for k,v in pairs( self.Weapons ) do
			self:Give( tostring( v ) )
		end		
	end
end

function exsto.Registry.Player:CreateJail(time)
	self:JailStrip()

	if self:InVehicle() then
		local vehicle = self:GetParent()
		self:ExitVehicle()
		vehicle:Remove()
	end
		
	self:SetMoveType( MOVETYPE_WALK )

	local pos = self:GetPos()
	local ent, text
	self.JailWalls = {}
	for _, item in ipairs( PLUGIN.WallPositions ) do
		ent = ents.Create( "prop_physics" )
			ent:SetModel( item.mdl )
			ent:SetPos( pos + item.pos )
			ent:SetAngles( item.ang )
			ent:Spawn()
			ent:GetPhysicsObject():EnableMotion( false )
			ent:SetMoveType( MOVETYPE_NONE )
			ent.IsJailWall = true
			table.insert( self.JailWalls, ent )
	end
	
	text = ents.Create( "3dtext" )
		text:SetPos( pos + Vector( 35, 0, 60 ) )
		text:SetAngles( Angle( 0, 0, 0 ) )
		text:Spawn()
		text:SetPlaceObject( self.JailWalls[1] )
		text:SetText( self:Nick() .. "'s Jail" )
		text:SetScale( 0.1 )
		table.insert( self.JailWalls, text )
	
	self.IsJailed = true
	self.JailedPos = pos
	
	if time > 0 then timer.Simple(time,function() self:RemoveJail() end) end
	self.JailTime = time
	
end

function exsto.Registry.Player:RemoveJail()
	if self:EntIndex() == 0 then return end
	if type( self.JailWalls ) == "table" then
		for _, ent in ipairs( self.JailWalls ) do
			if ent:IsValid() then ent:Remove() end
		end
	end
	
	self:JailReturn()

	self.IsJailed = false
end
	
function PLUGIN:Jail( owner, ply, time )

	if !ply.IsJailed then
		ply:CreateJail(time)
		if time > 0 then 
			return { exsto_CHAT,COLOR.NAME,owner:Nick(),COLOR.NORM," has jailed ",COLOR.NAME,ply:Nick(),
				COLOR.NORM," for ", COLOR.NAME,tostring(time),COLOR.NORM, " seconds." }
		else
			return { exsto_CHAT,COLOR.NAME,owner:Nick(),COLOR.NORM," has jailed ",COLOR.NAME,ply:Nick(),COLOR.NORM,"!" }		
		end
	else
		ply:RemoveJail()
		return {
			Activator = owner,
			Player = ply,
			Wording = " has un-jailed ",
		}
	end
	
end
PLUGIN:AddCommand( "jail", {
	Call = PLUGIN.Jail,
	Desc = "Allows users to put other users in jail.",
	Console = { "jail", "unjail" },
	Chat = { "!jail", "!unjail" },
	ReturnOrder = "Victim-Time",
	Args = {Victim = "PLAYER", Time = "NUMBER"},
	Optional = { Time = 0 },
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "jail", "Jail", {
	Time = {
		{ Display = "Instant", Data = 0 },
		{ Display = "5 seconds", Data = 5 },
		{ Display = "10 seconds", Data = 10 },
		{ Display = "20 seconds", Data = 20 },
		{ Display = "30 seconds", Data = 30 },
		{ Display = "1 minute", Data = 60 },
		{ Display = "5 minutes", Data = 5*60 },
	}
})

PLUGIN:Register()