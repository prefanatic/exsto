-- Exsto
-- Time plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Time Monitor",
	ID = "time",
	Desc = "A plugin that keeps track of player time.",
	Owner = "Prefanatic",
} )

if SERVER then

	exsto.TimeDB = FEL.CreateDatabase( "exsto_plugin_time" )
		exsto.TimeDB:SetDisplayName( "Time Log" )
		exsto.TimeDB:ConstructColumns( {
			Player = "TEXT";
			SteamID = "VARCHAR(50):primary:not_null";
			Time = "INTEGER:not_null";
			Last = "INTEGER:not_null";
			Online = "INTEGER";
			LastSessionTime = "INTEGER";
		} )
	
	function PLUGIN:ExInitSpawn( ply, sid, uid )

		local nick = ply:Nick()
		
		local time, last = exsto.TimeDB:GetData( sid, "Time, Last" )

		if type( time ) == "nil" then
			
			exsto.TimeDB:AddRow( {
				Player = nick;
				SteamID = sid; 
				Time = 0;
				Last = os.time();
				Online = 1;
				LastSessionTime = 0;
			} )
			
			ply:SetFixedTime( 0 )
			
			timer.Simple( 1, function()
				exsto.Print( exsto_CHAT, ply, COLOR.NORM, "Welcome ", COLOR.NAME, nick, COLOR.NORM, ".  It seems this is your first time here, have fun!" )
			end )
			
		else
		
			ply:SetFixedTime( time )
			timer.Simple( 1, function()
				exsto.Print( exsto_CHAT, ply, COLOR.NORM, "Welcome back ", COLOR.NAME, nick, COLOR.NORM, "!" )
				exsto.Print( exsto_CHAT, ply, COLOR.NORM, "You last visited ", COLOR.RED, os.date( "%c", last ) )
			end )
			
		end
		
		ply:SetJoinTime( CurTime() )
		
		-- We want to update our 'last' field, as per request from MystX
		exsto.TimeDB:AddRow( {
			Player = nick;
			SteamID = sid; 
			Time = time;
			Last = os.time();
			Online = 1;
			LastSessionTime = 0;
		} )
		
	end
	
	function PLUGIN:PlayerDisconnected( ply )
		exsto.TimeDB:AddRow( {
			Player = ply:Nick();
			SteamID = ply:SteamID(); 
			Time = ply:GetTotalTime();
			Last = os.time();
			Online = 0;
			LastSessionTime = ply:GetSessionTime();
		} )
	end
	
	function PLUGIN:ShutDown()
		for _, ply in ipairs( player.GetAll() ) do
			self:PlayerDisconnected( ply )
		end
	end
	
	function PLUGIN.Interval()
		for _, ply in pairs( player.GetAll() ) do
			exsto.TimeDB:AddRow( {
				Player = ply:Nick();
				SteamID = ply:SteamID(); 
				Time = ply:GetTotalTime();
				Last = os.time();
				Online = 1;
				LastSessionTime = ply:GetSessionTime();
			} )
		end
	end
	timer.Create( "Time_IntervalSave", 60 * 5, 0, PLUGIN.Interval )
	
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

PLUGIN:Register()