-- Exsto
-- Time plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Time Monitor",
	ID = "time",
	Desc = "A plugin that keeps track of player time.",
	Owner = "Prefanatic",
	CleanUnload = true,
} )

if SERVER then

	function PLUGIN:Init()
		self.NextThink = CurTime() + (5*60)
		self.DB = FEL.CreateDatabase( "exsto_plugin_time" )
			self.DB:SetDisplayName( "Time Log" )
			self.DB:ConstructColumns( {
				Player = "TEXT";
				SteamID = "VARCHAR(50):primary:not_null";
				Time = "INTEGER:not_null";
				Last = "INTEGER:not_null";
				Online = "INTEGER";
				LastSessionTime = "INTEGER";
			} )
			
		-- Meta funcions
		local meta = FindMetaTable( "Player" )

		function meta:SetJoinTime( time )
			self:SetNWInt( "Time_Join", time )
		end

		function meta:GetJoinTime( time )
			return self:GetNWInt( "Time_Join" )
		end

		function meta:SetFixedTime( time )
			self:SetNWInt( "Time_Fixed", time )
		end

		function meta:GetFixedTime()
			return self:GetNWInt( "Time_Fixed" )
		end

		function meta:GetSessionTime()
			return CurTime() - self:GetJoinTime()
		end

		function meta:GetTotalTime()
			return self:GetFixedTime() + self:GetSessionTime()
		end
		
		function meta:GetLastTime()
			return self:GetNWInt( "ExLastTime" )
		end
		
		function meta:SetLastTime( n )
			self:SetNWInt( "ExLastTime", n )
		end

	end
	
	function PLUGIN:OnUnload()
		local meta = FindMetaTable( "Player" )
		
		meta.SetJoinTime = nil
		meta.SetFixedTime = nil
		meta.GetFixedTime = nil
		meta.GetSessionTime = nil
		meta.GetTotalTime = nil
		meta.GetLastTime = nil
		meta.SetLastTime = nil
	end
	
	function PLUGIN:Save( ply, time, online, session, new )
		self.DB:AddRow( {
			Player = ply:Nick();
			SteamID = ply:SteamID();
			Time = time;
			Last = os.time();
			Online = online;
			LastSessionTime = session;
		} )
	end
	
	function PLUGIN:ExPlayerAuthed( ply )	
		self.DB:GetRow( ply:SteamID(), function( q, d )			
			ply:SetJoinTime( CurTime() )
			
			if not d then
				self:Save( ply, 0, 1, 0, true )
				ply:SetFixedTime( 0 )
				return
			end
			
			local time, last = d.Time, d.Last
			self:Debug( "Time for '" .. ply:Nick() .. "' is '" .. tostring( time ) .. "' last '" .. tostring( last ) .. "'", 1 )
			
			ply:SetFixedTime( time )
			ply:SetLastTime( last )
		end )
	end
	
	function PLUGIN:ExInitSpawn( ply, sid )
		if ply:GetFixedTime() == 0 then
			ply:Print( exsto_CHAT, COLOR.NORM, "Welcome ", COLOR.NAME, ply:Nick(), COLOR.NORM, ".  It seems this is your first time here, have fun!" )
			return
		end
		
		ply:Print( exsto_CHAT, COLOR.NORM, "Welcome back ", COLOR.NAME, ply:Nick(), COLOR.NORM, "!" )
		ply:Print( exsto_CHAT, COLOR.NORM, "You last visited ", COLOR.NAME, os.date( "%A (%x) at %I:%M %p", ply:GetLastTime() ) )
	end
	
	function PLUGIN:PlayerDisconnected( ply )
		self:Save( ply, ply:GetTotalTime(), 0, ply:GetSessionTime() );
	end
	
	function PLUGIN:ShutDown()
		for _, ply in ipairs( player.GetAll() ) do
			self:PlayerDisconnected( ply )
		end
	end
	
	function PLUGIN:Think()
		if CurTime() > self.NextThink then
			self.NextThink = CurTime() + ( 5*60 )
			for _, ply in ipairs( player.GetAll() ) do
				self:Save( ply, ply:GetTotalTime(), 1, ply:GetSessionTime() )
			end
		end
	end

	function PLUGIN:GetPlayerTotal( ply, victim )
		if !victim then return { ply, COLOR.NAME, "Invalid player!" } end
		
		return { ply, COLOR.NAME, victim:Nick(), COLOR.NORM, " has been on this server for ", COLOR.NAME, timeToString(victim:GetTotalTime() ) }
	end
	PLUGIN:AddCommand( "gettotaltime", {
		Call = PLUGIN.GetPlayerTotal,
		Desc = "Allows users to see the total time of a user's time in a server.",
		Console = { "totaltime" },
		Chat = { "!totaltime" },
		ReturnOrder = "Victim",
		Args = { Victim = "PLAYER" },
		Optional = { Victim = nil },
		Category = "Time",
	})
	PLUGIN:RequestQuickmenuSlot( "gettotaltime", "Time Played" )
	
end

PLUGIN:Register()
