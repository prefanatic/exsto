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
	
	function SendMaps( ply )
		local curGamemode = string.Explode( "/", GAMEMODE.Folder )
		local sender = exsto.CreateSender( "ExRecMapData", ply )
			sender:AddShort( table.Count( PLUGIN.MapList ) )
			for mapName, mapData in pairs( PLUGIN.MapList ) do
				sender:AddString( mapData.Name )
				sender:AddString( mapData.Material )
				sender:AddString( mapData.Category )
			end
			
			sender:AddShort( table.Count( PLUGIN.Gamemodes ) )
			for _, data in ipairs( PLUGIN.Gamemodes ) do
				sender:AddString( data.name ) 
			end
			
			sender:AddString( curGamemode[#curGamemode] )
		sender:Send()
	end
	concommand.Add( "_GetMapsList", SendMaps )
	
	function PLUGIN:Init()
	
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
			  
			   // Don't add useless maps
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

	function PLUGIN:GrabMapIcon( mapfile, mapIconObj )
		if !self.OnlineMapIcons[ mapfile ] then self:Print( "Unable to find map file in online list: " .. mapfile ) return end
		
		http.Fetch( "http://gmod-map-icons.googlecode.com/svn/trunk/materials/maps/" .. mapfile .. ".vmt", function( body, len, header, httpCode )
			if body == 0 or body:Trim() == "" then
				self:Print( "Unable to receive map icon for: " .. mapfile )
				return
			end
			
		end )
	end

	function PLUGIN:Init()
	
		-- Grab a list of map icons from this nifty SVN I found.  Maybe we can download them! 
		self.MapListReceived = false
		self.OnlineMapIcons = {}
		http.Fetch( "http://gmod-map-icons.googlecode.com/svn/trunk/maplist.txt", function( body, len, header, httpCode )
			if body == 0 or body:Trim() == "" then
				self.MapListReceived = false
				self:Print( "Unable to receive map icon list!  Oh well :(" )
				return
			end
			
			-- Format this baby.
			self.OnlineMapIcons = string.Explode( " ", body )
			for _, mapname in ipairs( self.OnlineMapIcons ) do
				self.OnlineMapIcons[ _ ] = mapname:Trim():lower();
			end
			self.MapListReceived = true
		end )
		
	end

	local function receive( reader )
		if !PLUGIN.Maps then PLUGIN.Maps = {} end
		for I = 1, reader:ReadShort() do
			table.insert( PLUGIN.Maps, {
				Name = reader:ReadString(),
				Material = reader:ReadString(),
				Category = reader:ReadString()
			} )
		end
		
		if !PLUGIN.Categories then PLUGIN.Categories = {} end
		for _, data in ipairs( PLUGIN.Maps ) do
			if !table.HasValue( PLUGIN.Categories, data.Category ) then table.insert( PLUGIN.Categories, data.Category ) end
		end
		
		if !PLUGIN.Gamemodes then PLUGIN.Gamemodes = {} end
		for I = 1, reader:ReadShort() do
			table.insert( PLUGIN.Gamemodes, reader:ReadString() )
		end
		
		PLUGIN.CurrentGamemode = reader:ReadString()

		PLUGIN.Received = true
		if PLUGIN.Panel then
			PLUGIN.Panel:EndLoad()
			PLUGIN:Build( PLUGIN.Panel )
		end
	end
	exsto.CreateReader( "ExRecMapData", receive ) 
	
	function PLUGIN:CreateMapIcon( data )
		if !self.MapIcons then self.MapIcons = {} end
		if self.MapIcons[ data.Name ] and self.MapIcons[ data.Name ]:IsValid() then return self.MapIcons[ data.Name ] end
		
		--print( data.Material )
		
		if file.Exists( "maps/" .. data.Material, "GAME" ) then
			local mat = Material( data.Material )
			--print( mat:GetName() )
			if mat:GetName() == "___error" then
				mat = "maps/noicon"
			else mat = data.Material end
		else
			mat = "maps/noicon"
		end
		
		self.MapIcons[ data.Name ] = vgui.Create( "DImageButton" )
		
		local icon = self.MapIcons[ data.Name ]
			icon:SetMaterial( mat )
			icon:SetSize( 64, 64 )
			icon:SetToolTip( data.Name )
			icon.DoClick = function( icon )
				if icon.LastClick and icon.LastClick + 1 > CurTime() then
					self.Change:OnClick()
					return
				end
				self.SelectedMap = data.Name
				icon.LastClick = CurTime()
			end
			
		return icon
	end
	
	function PLUGIN:Build( panel )
		self.Tabs = panel:RequestTabs()
		self.Secondary = panel:RequestSecondary()
	
		self.MapList = exsto.CreatePanelList( 5, 5, panel:GetWide() - 10, panel:GetTall() - 50, 10, true, true, panel )
			self.MapList:SetVisible( false )
			self.MapList.SetCategory = function( mapList, cat )
				mapList:Clear()
				
				for _, data in ipairs( self.Maps ) do
					if data.Category == cat then
						mapList:AddItem( self:CreateMapIcon( data ) )
					end
				end
			end
			
		self.MapListView = exsto.CreateListView( 5, 5, panel:GetWide() - 10, panel:GetTall() - 50, panel  )
			self.MapListView:AddColumn( "Map" )
			self.MapListView:AddColumn( "Category" )
			local old = self.MapListView.OnClickLine
			self.MapListView.OnClickLine = function( listView, line, ... )
				old( listView, line, ... )
				if line.LastClick and line.LastClick + 1 > CurTime() then
					self.Change:OnClick()
					return
				end
				self.SelectedMap = line:GetValue( 1 )
				line.LastClick = CurTime()
			end
			self.MapListView.Populate = function( listView )
				listView:Clear()
				
				for _, data in ipairs( self.Maps ) do
					listView:AddLine( data.Name, data.Category )
				end
			end
			self.MapListView:Populate()
			self.MapListView:SetVisible( true )
			
		--self.GamemodeLabel = exsto.CreateLabel( "center", 4, "Gamemodes", "ExGenericText18", self.Secondary )
		self.GamemodeList = exsto.CreateComboBox( 5, 8, self.Secondary:GetWide() - 10, self.Secondary:GetTall() - 25, self.Secondary )
			self.GamemodeList:AddColumn( "Gamemodes" )
			self.GamemodeList.Populate = function( gameList )
				gameList:Clear()
				for _, gm in ipairs( self.Gamemodes ) do
					gameList:AddChoice( gm )
				end
				gameList:SelectByName( self.CurrentGamemode )
			end
			self.GamemodeList:Populate()
		
		self.Change = exsto.CreateButton( panel:GetWide() - 80, panel:GetTall() - 40, 70, 27, "Change", panel )
			self.Change.OnClick = function( button )
				if !self.SelectedMap then panel:PushError( "Please select a map before changing level." ) return end
				RunConsoleCommand( "exsto", "changelevel", self.SelectedMap, "5", self.GamemodeList:GetSelectedItem() )
			end
		
		Menu:CreateAnimation( self.MapListView )
		Menu:CreateAnimation( self.MapList )
		
		self.MapListView:FadeOnVisible( true )
		self.MapList:FadeOnVisible( true )
		self.MapListView:SetFadeMul( 3 )
		self.MapList:SetFadeMul( 3 )
			
		self.ListView = exsto.CreateImageButton( 5, panel:GetTall() - 40, 32, 32, "exsto/listviewsel.png", panel )
			self.ListView.DoClick = function( icon )
				self.MapList:SetVisible( false )
				self.MapListView:SetVisible( true )
				self.Tabs:Hide()
				
				icon:SetImage( "exsto/listviewsel.png" )
				self.IconView:SetImage( "exsto/iconview.png" )
			end
			
		self.IconView = exsto.CreateImageButton( 45, panel:GetTall() - 40, 32, 32, "exsto/iconview.png", panel )
			self.IconView.DoClick = function( icon )
				self.MapList:SetVisible( true )
				self.MapListView:SetVisible( false )
				self.Tabs:Show()
				
				icon:SetImage( "exsto/iconviewsel.png" )
				self.ListView:SetImage( "exsto/listview.png" )
			end
			
		for _, cat in SortedPairs( self.Categories, true ) do
			self.Tabs:CreateButton( cat, function() self.MapList:SetCategory( cat ) end )
		end
		self.Tabs:SelectByName( "Garry's Mod" )
	end
	
	Menu:CreatePage( {
		Title = "Maps List",
		Short = "mapslist",
		}, 
		function( panel )
			PLUGIN.Panel = panel
			if !PLUGIN.Received then
				panel:PushLoad()
				RunConsoleCommand( "_GetMapsList" )
			else
				PLUGIN:Build( panel )
			end
		end
	)
end

PLUGIN:Register()
