-- Exsto

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Point Shop",
	ID = "pshop",
	Desc = "Point shop system",
	Owner = "Prefanatic",
} )

if SERVER then

	PLUGIN.Objects = {
		["STEAMID"] = {
			["Hats"] = {};
			["Trails"] = {};
			["Data"] = {};
		};
	}
	PLUGIN.Possible = {
		["Hats"] = {
			"models/Combine_Helicopter/helicopter_bomb01.mdl";
			"models/props_junk/TrafficCone001a.mdl";
			"models/props_junk/sawblade001a.mdl";
			"models/props_wasteland/light_spotlight01_lamp.mdl";
			"models/props_c17/clock01.mdl";
			"models/props_c17/streetsign004e.mdl";
			"models/props_lab/monitor02.mdl";
			"models/props_lab/monitor01b.mdl";
			"models/props_c17/tv_monitor01.mdl";
			};
		["Trails"] = {};
	}
	exsto.PointsDB = FEL.CreateDatabase( "exsto_plugin_points" )
		exsto.PointsDB:ConstructColumns( {
			SteamID = "VARCHAR(50):primary:not_null";
			Points = "INTEGER:not_null";
			Owned = "TEXT";
		} )
		
	function PLUGIN:SavePlayerData( ply )
		exsto.PointsDB:AddRow( {
			SteamID = ply:SteamID();
			Points = ply:GetPoints();
			Owned = von.serialize( self:GetPlayerOwned( ply ) );
		} )
	end
	
	function PLUGIN:GetPlayerOwned( ply )
		return self.Objects[ ply:SteamID() ]
	end
	
	function PLUGIN:CreatePlayerData( ply, sid )
		ply:SetPoints( 0 );
		self.Objects[ sid ] = {};
		self:SavePlayerData( ply )
	end			
	
	function PLUGIN:ExInitSpawn( ply, sid, uid )
	
		-- Check and see if they're in our system yet.
		local points, owned = exsto.PointsDB:GetData( sid, "Points, Owned" )
		
		-- If they don't have a db row with us, create them one
		if type( points ) == "nil" then 
			points, owned = 0, ""
			self:CreatePlayerData( ply, sid ) 
		end

		-- Bring all their saved data up to the plugin.
		ply:SetPoints( points )
		self.Objects[ sid ] = von.deserialize( owned )
		
	end
	
	function PLUGIN:PlayerDisconnected( ply )
		exsto.PointsDB:AddRow( {
			SteamID = ply:SteamID(); 
			Points = ply:GetPoints();
			Owned = von.serialize( self.Objects[ ply:SteamID() ] or {} );
		} )
	end
	
	function PLUGIN:ShutDown()
		for _, ply in ipairs( player.GetAll() ) do
			self:PlayerDisconnected( ply )
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
	PLUGIN:RequestQuickmenuSlot( "gettotaltime" )
	
end

-- Meta funcions
local meta = FindMetaTable( "Player" )

function meta:SetPoints( points )
	self:SetNWInt( "ExPoints", points )
end

function meta:GetPoints()
	return self:GetNWInt( "ExPoints" )
end

PLUGIN:Register()