-- Exsto
-- Restart Server Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Restart",
	ID = "restart-changelvl",
	Desc = "A plugin that allows restarting of the server, or change map!",
	Owner = "Prefanatic",
} )

if SERVER then

	PLUGIN.MapList = {}
	PLUGIN.MapCateg = {}
	PLUGIN.Gamemodes = {}
	
	// Stolen from lua-users.org
	local function StringDist( s, t )
		local d, sn, tn = {}, #s, #t
		local byte, min = string.byte, math.min
			for i = 0, sn do d[i * tn] = i end
			for j = 0, tn do d[j] = j end
			for i = 1, sn do
				local si = byte(s, i)
				for j = 1, tn do
					d[i*tn+j] = min(d[(i-1)*tn+j]+1, d[i*tn+j-1]+1, d[(i-1)*tn+j-1]+(si == byte(t,j) and 0 or 1))
				end
			end
		return d[#d]
	end

	function PLUGIN:ChangeLevel( owner, map, delay, gm )

		if string.Right( map, 4 ) != ".bsp" then map = map .. ".bsp" end
	
		local mapData = self.MapList[map]
		local data = { Max = 100, Map = "" }
		local dist
		
		if !mapData then
			for k,v in pairs( self.MapList ) do
				k = k:gsub( "%.bsp", "" )
				dist = StringDist( map, k )
				if dist < data.Max then data.Max = dist data.Map = k end
			end
			
			return { owner, COLOR.NORM, "Unknown map ", COLOR.NAME, map:gsub( "%.bsp", "" ), COLOR.NORM, ".  Maybe you want ", COLOR.NAME, data.Map, COLOR.NORM, "?" }
		end
		
		local found = false
		for _, data in ipairs( self.Gamemodes ) do
			if data.Name == gm then found = true break end
		end
		
		if !found and !gm == "current" then
			exsto.GetClosestString( gm, self.Gamemodes, "Name", owner, "Unknown gamemode" )
			return
		end
		
		local run = "changelevel " .. map:gsub( "%.bsp", "" ) .."\n"
		if gm != "current" then
			run = "changegamemode " .. map:gsub( "%.bsp", "" ) .." " .. gm .. "\n"
		end

		timer.Simple( delay, function() game.ConsoleCommand( run ) end )

		return {
			COLOR.NORM, "Changing level to ",
			COLOR.NAME, map:gsub( "%.bsp", "" ) .. "(" .. gm .. ")",
			COLOR.NORM, " in ",
			COLOR.NAME, tostring( delay ),
			COLOR.NORM, " seconds!"
		}
		
	end
	PLUGIN:AddCommand( "changelvl", {
		Call = PLUGIN.ChangeLevel,
		Desc = "Allows users to change the level.",
		Console = { "map", "changelevel" },
		Chat = { "!map", "!changelevel" },
		ReturnOrder = "Map-Delay-Gamemode",
		Args = {Map = "STRING", Delay = "NUMBER", Gamemode = "STRING"},
		Optional = { Map = "gm_flatgrass", Delay = 0, Gamemode = "current" },
		Category = "Administration",
	})

	function PLUGIN:ReloadMap( owner )

		game.ConsoleCommand( "changelevel " .. string.gsub( game.GetMap(), ".bsp", "" ) .. "\n" )
		
	end
	PLUGIN:AddCommand( "reloadmap", {
		Call = PLUGIN.ReloadMap,
		Desc = "Allows users to reload the current level.",
		Console = { "reloadmap" },
		Chat = { "!reloadmap" },
		Args = {},
		Category = "Administration",
	})
	
	function PLUGIN:Init()
	
		exsto.CreateFlag( "mapslist", "Allows users to access the maps list." )
	
		-- Build the map list. (Code copy and pasted from GMOD)
		local MapPatterns = {}
		 
		MapPatterns[ "^de_" ] = "Counter-Strike"
		MapPatterns[ "^cs_" ] = "Counter-Strike"
		MapPatterns[ "^es_" ] = "Counter-Strike"
		 
		MapPatterns[ "^cp_" ] = "Team Fortress 2"
		MapPatterns[ "^ctf_" ] = "Team Fortress 2"
		MapPatterns[ "^tc_" ] = "Team Fortress 2"
		MapPatterns[ "^pl_" ] = "Team Fortress 2"
		MapPatterns[ "^arena_" ] = "Team Fortress 2"
		MapPatterns[ "^koth_" ] = "Team Fortress 2"
		 
		MapPatterns[ "^dod_" ] = "Day Of Defeat"
		 
		MapPatterns[ "^d1_" ] = "Half-Life 2"
		MapPatterns[ "^d2_" ] = "Half-Life 2"
		MapPatterns[ "^d3_" ] = "Half-Life 2"
		MapPatterns[ "credits" ] = "Half-Life 2"
		 
		MapPatterns[ "^ep1_" ] = "Half-Life 2: Episode 1"
		MapPatterns[ "^ep2_" ] = "Half-Life 2: Episode 2"
		MapPatterns[ "^ep3_" ] = "Half-Life 2: Episode 3"
		 
		MapPatterns[ "^escape_" ] = "Portal"
		MapPatterns[ "^testchmb_" ] = "Portal"
		 
		MapPatterns[ "^gm_" ] = "Garry's Mod"
		MapPatterns[ "^ttt_" ] = "Trouble in Terrorist Town"
		 
		MapPatterns[ "^c0a" ] = "Half-Life: Source"
		MapPatterns[ "^c1a" ] = "Half-Life: Source"
		MapPatterns[ "^c2a" ] = "Half-Life: Source"
		MapPatterns[ "^c3a" ] = "Half-Life: Source"
		MapPatterns[ "^c4a" ] = "Half-Life: Source"
		MapPatterns[ "^c5a" ] = "Half-Life: Source"
		MapPatterns[ "^t0a" ] = "Half-Life: Source"
		 
		MapPatterns[ "boot_camp" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "bounce" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "crossfire" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "datacore" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "frenzy" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "rapidcore" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "stalkyard" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "snarkpit" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "subtransit" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "undertow" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "lambda_bunker" ] = "Half-Life: Source Deathmatch"
		 
		MapPatterns[ "dm_" ] = "Half-Life 2 Deathmatch"
		 
		//
		// Load patterns from the gamemodes
		//
		PLUGIN.Gamemodes = engine.GetGamemodes()
		 
		for k, gm in pairs( engine.GetGamemodes() ) do
		 
			   local info = file.Read( gm.name.."/"..gm.name..".txt", "lsv" )
			   local info = util.KeyValuesToTable( info )
			   local Name = info.name or "Unnammed Gamemode"
			   local Patterns = info.mappattern or {}
			  
			   for k, pattern in pairs( Patterns ) do
					 MapPatterns[ pattern ] = Name
			   end
			  
		end
		 
		local IgnoreMaps = { "background", "^test_", "^styleguide", "^devtest" }
		 
		local g_MapList = PLUGIN.MapList
		local g_MapListCategorised = PLUGIN.MapCateg
		 
		for k, v in pairs( file.Find( "maps/*.bsp", "MOD" ) ) do
		 
			   local Ignore = false
			   for _, ignore in pairs( IgnoreMaps ) do
					 if ( string.find( v, ignore ) ) then
						    Ignore = true
					 end
			   end
			  
			   -- Don't add useless maps
			   if ( !Ignore ) then
			  
					 local Mat = nil
					 local Category = "Other"
					 local name = string.gsub( v, ".bsp", "" )
					 local lowername = string.lower( v )
			  
					 Mat = "maps/"..name..".vmt"
					
					 for pattern, category in pairs( MapPatterns ) do
						    if ( string.find( lowername, pattern ) ) then
								  Category = category
						    end
					 end
		 
					 g_MapList[ v ] = { Material = Mat, Name = name, Category = Category }

			   end
		 
		end
		 
		for k, v in pairs( g_MapList ) do
		 
			   g_MapListCategorised[ v.Category ] = g_MapListCategorised[ v.Category ] or {}
			   g_MapListCategorised[ v.Category ][ v.Name ] = v
		 
		end
		
		PLUGIN.MapList = g_MapList
		
	end
	
elseif CLIENT then

end

PLUGIN:Register()
