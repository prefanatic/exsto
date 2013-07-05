-- Prefan Access Controller
-- Jail

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Jail",
	ID = "jail",
	Desc = "A plugin that adds the !jail command.",
	Owner = "Prefanatic",
	CleanUnload = true;
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
	
	-- Store these meta registries in here, so we don't create them when we don't init.
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
				if IsValid( ent ) then ent:Remove() end
			end
		end
		
		self:JailReturn()

		self.IsJailed = false
	end
	
end

function PLUGIN:OnUnload()
	for _, ply in ipairs( player.GetAll() ) do
		if ply:Jailed() then
			ply:RemoveJail()
		end
	end
	
	-- Clean out our meta registries
	exsto.Registry.Player.RemoveJail = nil
	exsto.Registry.Player.CreateJail = nil
	exsto.Registry.Player.JailReturn = nil
	exsto.Registry.Player.JailStrip = nil
	exsto.Registry.Player.MoveToJail = nil
	exsto.Registry.Player.Jailed = nil
	
end

function PLUGIN:PlayerNoClip( ply )
	if ply:Jailed() then return false end
end
PLUGIN:SetHookPriority( "PlayerNoClip", 1 )

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
		timer.Simple( 0.1, function() ply:StripWeapons() end )
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

function PLUGIN:UnJail( owner, ply, time )
	if not ply.IsJailed then
		owner:Print( exsto_CHAT, COLOR.NAME, ply:Nick(), COLOR.NORM, " is not jailed." )
		return
	end

	ply:RemoveJail()
	exsto.NotifyChat( COLOR.NAME, owner:Nick(), COLOR.NORM, " has unjailed ", COLOR.NAME, ply:Nick() )	
end
PLUGIN:AddCommand( "unjail", {
	Call = PLUGIN.UnJail,
	Desc = "Allows users to remove other users in jail.",
	Console = { "unjail" },
	Chat = { "!unjail" },
	Arguments = {
		{ Name = "Player", Type = COMMAND_PLAYER };
	};
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "unjail", "Unjail")
	
function PLUGIN:Jail( owner, ply, time )
	if ply.IsJailed then
		owner:Print( exsto_CHAT, COLOR.NAME, ply:Nick(), COLOR.NORM, " is already jailed." )
		return
	end

	ply:CreateJail(time)
	if time > 0 then 
		return { exsto_CHAT,COLOR.NAME,owner:Nick(),COLOR.NORM," has jailed ",COLOR.NAME,ply:Nick(),
			COLOR.NORM," for ", COLOR.NAME,tostring(time),COLOR.NORM, " seconds." }
	else
		return { exsto_CHAT,COLOR.NAME,owner:Nick(),COLOR.NORM," has jailed ",COLOR.NAME,ply:Nick(),COLOR.NORM,"!" }		
	end
	
end
PLUGIN:AddCommand( "jail", {
	Call = PLUGIN.Jail,
	Desc = "Allows users to put other users in jail.",
	Console = { "jail" },
	Chat = { "!jail" },
	Arguments = {
		{ Name = "Player", Type = COMMAND_PLAYER };
		{ Name = "Time", Type = COMMAND_NUMBER, Optional = 0 };
	};
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