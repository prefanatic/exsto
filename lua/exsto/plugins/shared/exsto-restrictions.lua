-- Exsto
-- Rank Restrictions

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Restricter",
	ID = "rank-restrictions",
	Desc = "A plugin that gives functionality to rank restrictions.",
	Owner = "Prefanatic",
} )

PLUGIN.Restrictions = {} 
PLUGIN.FileTypes = {
	props = "Props",
	sweps = "Sweps",
	entities = "Entities",
	stools = "Stools",
}

if SERVER then

	function PLUGIN:Init()
	
		util.AddNetworkString( "ExReqRestrict" )
		util.AddNetworkString( "ExReceiveRestriction" )
		util.AddNetworkString( "ExUpdateRestriction" )
		
		self.RankDB = FEL.CreateDatabase( "exsto_restriction_ranks" )
			self.RankDB:SetDisplayName( "Rank Restrictions" )
			self.RankDB:ConstructColumns( {
				ID = "VARCHAR(100):primary:not_null";
				Props = "TEXT";
				Stools = "TEXT";
				Entities = "TEXT";
				Sweps = "TEXT";
			} )
			
		self.PlayerDB = FEL.CreateDatabase( "exsto_restriction_players" )
			self.PlayerDB:SetDisplayName( "Player Restrictions" )
			self.PlayerDB:ConstructColumns( {
				ID = "VARCHAR(50):primary:not_null";
				Props = "TEXT";
				Stools = "TEXT";
				Entities = "TEXT";
				Sweps = "TEXT";
			} )
			
		-- Override GetCount
		local oldCount = exsto.Registry.Player.GetCount
		function exsto.Registry.Player.GetCount( self, ... )
			if self.ExNoLimits and PLUGIN:IsEnabled() then return -1 end
			return oldCount( self, ... )
		end
		
		-- Quality of service on the ranks database.
		local data = self.RankDB:ReadAll()
		for rID, rank in pairs( exsto.Ranks ) do
			local f = false
			for _, d in ipairs( data ) do
				if d.ID == rID then f = true end
			end
			
			if not f then
				self.RankDB:AddRow( {
					ID = rID;
					Props = von.serialize( {} );
					Stools = von.serialize( {} );
					Entities = von.serialize( {} );
					Sweps = von.serialize( {} );
				} )
			end
		end
		
		-- Restriction types
		self.RestrictionTypes = {
			"Sweps",
			"Stools",
			"Props",
			"Entities",
		}
	
	end
	
	function PLUGIN:GetRestrictionType( short )
		return self.RestrictionTypes[ short ]
	end
	function PLUGIN:GetRestrictionList( short )
		if short == 1 then return weapons.GetList()
			elseif short == 2 then return
			elseif short == 3 then return
			elseif short == 4 then return list.Get( "SpawnableEntities" )
		end
	end
	function PLUGIN:ConstructDataSave( short, id, data )
		if short == 1 then return { ID = id, Sweps = data }
			elseif short == 2 then return { ID = id, Stools = data }
			elseif short == 3 then return { ID = id, Props = data }
			elseif short == 4 then return { ID = id, Entities = data }
		end
	end
	
	-- Networking
	function PLUGIN:ExReqRestrict( reader )
		return reader:ReadSender():IsAllowed( "restrictions" )
	end
	function PLUGIN:SendRestrictions( reader )
		local w = reader:ReadShort()
		local t = reader:ReadBool()
		local id = reader:ReadString()
		local ply = reader:ReadSender()
		self:SendRestrictionData( w, t, id, ply )
	end
	PLUGIN:CreateReader( "ExReqRestrict", PLUGIN.SendRestrictions )
	
	function PLUGIN:SendRestrictionData( w, t, id, ply )
		local sender = exsto.CreateSender( "ExReceiveRestriction", ply )
		local lst = self:GetRestrictionList( w )
		local pn = "menu players"
		if type( ply ) == "Player" then pn = ply:Nick() end
		
		local db = self.PlayerDB
		if t then db = self.RankDB end

		self:Debug( "Sending '" .. w .. "' restriction for '" .. id .. "' on player '" .. pn .. "'", 1 )
		
		local data = von.deserialize( db:GetData( id, self:GetRestrictionType( w ) ) or "" )

		sender:AddShort( w )
		sender:AddShort( table.Count( lst ) )
		for _, ent in pairs( lst ) do
			sender:AddString( ent.ClassName )
			
			if data and data[ ent.ClassName ] then
				sender:AddBool( data[ ent.ClassName ] )
			else
				sender:AddBool( false )
			end
		end
		sender:Send()
	end
	
	function PLUGIN:ExUpdateRestriction( reader )
		return reader:ReadSender():IsAllowed( "restrictions" )
	end
	function PLUGIN:UpdateRestriction( reader )
		local w = reader:ReadShort()
		local t = reader:ReadBool()
		local id = reader:ReadString()
		local class = reader:ReadString()
		local enabled = reader:ReadBool()
		local ply = reader:ReadSender()
		local db = self.PlayerDB
		if t then db = self.RankDB end
		
		self:Debug( "Restricting '" .. w .. "' class '" .. class .. "' under identifier '" .. id .. "' as value '" .. tostring( enabled ) .. "'", 1 )
		
		local data = von.deserialize( db:GetData( id, self:GetRestrictionType( w ) ) or "" )
			data[ class ] = enabled;
			
		db:AddRow( self:ConstructDataSave( w, id, von.serialize( data ) ) )
		
		-- Resend
		self:SendRestrictionData( w, t, id, exsto.GetMenuPlayers() )
	end
	PLUGIN:CreateReader( "ExUpdateRestriction", PLUGIN.UpdateRestriction )
	
	function PLUGIN:NoLimits( caller, ply )
		local t = " has enabled limits on "
		if !ply.ExNoLimits then
			ply.ExNoLimits = true
			t = " has disabled limits on "
		else
			ply.ExNoLimits = false
		end
		
		return {
			Activator = caller,
			Player = ply, 
			Wording = t,
		}
	end			
	PLUGIN:AddCommand( "nolimits", {
		Call = PLUGIN.NoLimits,
		Desc = "Allows users to set nolimits on players.",
		Console = { "nolimits" },
		Chat = { "!nolimits" },
		ReturnOrder = "Player",
		Args = { Player = "PLAYER" },
		Category = "Fun",
	})
	PLUGIN:RequestQuickmenuSlot( "nolimits" )
	
	function PLUGIN:ExOnRankCreate( ID )
		if self.Restrictions[ ID ] then return end
		
		self.Restrictions[ ID ] = {
			Rank = ID,
			Props = {},
			Stools = {},
			Entities = {},
			Sweps = {},
		}
					
		self:SaveData( "all", ID )
	end
	
	function PLUGIN:LoadFileRestrictions()
		local load = ""
		for style, format in pairs( self.FileTypes ) do
			for ID, data in pairs( exsto.Ranks ) do
				if file.Exists( "exsto_restrictions/exsto_" .. style .. "_restrict_" .. ID .. ".txt", "DATA" ) then
					load = file.Read( "exsto_restrictions/exsto_" .. style .. "_restrict_" .. ID .. ".txt", "DATA" )
					load = string.Explode( "\n", load )
					
					for k,v in ipairs( load ) do
						table.insert( self.Restrictions[ ID ][format], v )
					end				
					
					self:SaveData( style, ID )
					file.Delete( "exsto_restrictions/exsto_" .. style .. "_restrict_" .. ID .. ".txt", "DATA" )
				end
			end
		end
	end
	
	function PLUGIN:SaveData( type, rank )
	
		local data = self.Restrictions[ rank ]
		local saveData = {}
		
		if type == "all" then
			saveData = {
				Rank = rank,
				Props = von.serialize( data.Props ),
				Stools = von.serialize( data.Stools ),
				Entities = von.serialize( data.Entities ),
				Sweps = von.serialize( data.Sweps ),
			}
			
		elseif type == "props" then
			saveData = {
				Rank = rank,
				Props = von.serialize( data.Props ),
			}
		elseif type == "stools" then
			saveData = {
				Rank = rank,
				Stools = von.serialize( data.Stools ),
			}
		elseif type == "entities" then
			saveData = {
				Rank = rank,
				Entities = von.serialize( data.Entities ),
			}
		elseif type == "sweps" then
			saveData = {
				Rank = rank,
				Sweps = von.serialize( data.Sweps ),
			}
		end
		
		exsto.RestrictDB:AddRow( saveData )

	end
	
	function PLUGIN:CanTool( ply, trace, tool )
		if !self.Restrictions or !self.Restrictions[ ply:GetRank() ] then
			self:Debug( "Unable to access rank restriction table.  Making one for: " .. ply:GetRank(), 1 )
			self:ExOnRankCreate( ply:GetRank() )
			return
		end
		if self.Restrictions[ ply:GetRank() ] and table.HasValue( self.Restrictions[ ply:GetRank() ].Stools, tool ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The tool ", COLOR.NAME, tool, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	
	function PLUGIN:PlayerGiveSWEP( ply, class, wep )
		if !self.Restrictions or !self.Restrictions[ ply:GetRank() ] then
			self:Debug( "Unable to access rank restriction table.  Making one for: " .. ply:GetRank(), 1 )
			self:ExOnRankCreate( ply:GetRank() )
			return
		end
		if self.Restrictions[ ply:GetRank() ] and table.HasValue( self.Restrictions[ ply:GetRank() ].Sweps, class ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The weapon ", COLOR.NAME, class, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	function PLUGIN:PlayerSpawnSWEP( ply, class, wep )
		if !self.Restrictions or !self.Restrictions[ ply:GetRank() ] then
			self:Debug( "Unable to access rank restriction table.  Making one for: " .. ply:GetRank(), 1 )
			self:ExOnRankCreate( ply:GetRank() )
			return
		end
		if self.Restrictions[ ply:GetRank() ] and table.HasValue( self.Restrictions[ ply:GetRank() ].Sweps, class ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The weapon ", COLOR.NAME, class, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	
	function PLUGIN:PlayerSpawnProp( ply, prop )
		if !self.Restrictions or !self.Restrictions[ ply:GetRank() ] then
			self:Debug( "Unable to access rank restriction table.  Making one for: " .. ply:GetRank(), 1 )
			self:ExOnRankCreate( ply:GetRank() )
			return
		end
		if self.Restrictions[ ply:GetRank() ] and table.HasValue( self.Restrictions[ ply:GetRank() ].Props, prop ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The prop ", COLOR.NAME, prop, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	
	function PLUGIN:PlayerSpawnSENT( ply, class )
		if !self.Restrictions or !self.Restrictions[ ply:GetRank() ] then
			self:Debug( "Unable to access rank restriction table.  Making one for: " .. ply:GetRank(), 1 )
			self:ExOnRankCreate( ply:GetRank() )
			return
		end
		if self.Restrictions[ ply:GetRank() ] and table.HasValue( self.Restrictions[ ply:GetRank() ].Entities, class ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The entity ", COLOR.NAME, class, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	
	function PLUGIN:AllowObject( owner, rank, object, data )
		
		if !self.Restrictions[ rank ] then
			local closeRank = exsto.GetClosestString( rank, exsto.Ranks, "ID", owner, "Unknown rank" )
			return
		end

		local tbl = self.Restrictions[ rank ]
		local style = ""
		
		if object == "stools" then 
			tbl = tbl.Stools
			style = "STOOL"
		elseif object == "sweps" then
			tbl = tbl.Sweps
			style = "SWEP"
		elseif object == "props" then
			tbl = tbl.Props
			style = "Prop"
		elseif object == "entities" then
			tbl = tbl.Entities
			style = "Entity"
		end
		
		if !data or data == "" then
			return { owner, COLOR.NORM, "No ", COLOR.NAME, style, COLOR.NORM, " specified!" }
		end
		
		local id = exsto.GetTableID( tbl, data )
		if !id then
			if table.Count( tbl ) == 0 then	
				return { owner, COLOR.NORM, "The " .. style .. " ", COLOR.NAME, data, COLOR.NORM, " doesn't exist in the deny table!" }
			end
			
			exsto.GetClosestString( data, tbl, nil, owner, "Unknown " .. style )
			return
		end
		
		table.remove( tbl, id )
		self:SaveData( object, rank )
		
		return { owner, COLOR.NORM, "Removing " .. style .. " ", COLOR.NAME, data, COLOR.NORM, " from ", COLOR.NAME, rank, COLOR.NORM, " restrictions!" }
	
	end
	
	function PLUGIN:DenyObject( owner, rank, object, data )
	
		if !self.Restrictions[ rank ] then
			local closeRank = exsto.GetClosestString( rank, exsto.Ranks, "ID", owner, "Unknown rank" )
			return
		end
		
		local tbl = self.Restrictions[ rank ]
		local style = ""
		
		if object == "stools" then 
			tbl = tbl.Stools
			style = "STOOL"
		elseif object == "sweps" then
			tbl = tbl.Sweps
			style = "SWEP"
		elseif object == "props" then
			tbl = tbl.Props
			style = "Prop"
		elseif object == "entities" then
			tbl = tbl.Entities
			style = "Entity"
		end
		
		if !data or data == "" then
			return { owner, COLOR.NORM, "No ", COLOR.NAME, style, COLOR.NORM, " specified!" }
		end
		
		table.insert( tbl, data )
		self:SaveData( object, rank )
	
		return { owner, COLOR.NORM, "Inserting " .. style .. " ", COLOR.NAME, data, COLOR.NORM, " into ", COLOR.NAME, rank, COLOR.NORM, " restrictions!" }
		
	end
	
--[[ -----------------------------------
		ENTITIES
     ----------------------------------- ]]
	function PLUGIN:AllowEntity( owner, rank, entity )
		return self:AllowObject( owner, rank, "entities", entity )
	end
	PLUGIN:AddCommand( "allowentity", {
		Call = PLUGIN.AllowEntity,
		Desc = "Allows users to remove disallowed entities from a rank.",
		Console = { "allowentity" },
		Chat = { "!allowentity" },
		ReturnOrder = "Rank-Entity",
		Args = { Rank = "STRING", Entity = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:DenyEntity( owner, rank, entity )
		return self:DenyObject( owner, rank, "entities", entity )
	end
	PLUGIN:AddCommand( "denyentity", {
		Call = PLUGIN.DenyEntity,
		Desc = "Allows users to deny entities to ranks.",
		Console = { "denyentity" },
		Chat = { "!denyentity" },
		ReturnOrder = "Rank-Entity",
		Args = { Rank = "STRING", Entity = "STRING" },
		Category = "Restrictions",
	})
	
--[[ -----------------------------------
		PROPS
     ----------------------------------- ]]
	function PLUGIN:AllowProp( owner, rank, prop )
		if !string.Right( prop, 4 ) == ".mdl" then prop = prop .. ".mdl" end
		return self:AllowObject( owner, rank, "props", prop )
	end
	PLUGIN:AddCommand( "allowprop", {
		Call = PLUGIN.AllowProp,
		Desc = "Allows users to remove disallowed props from a rank.",
		Console = { "allowprop" },
		Chat = { "!allowprop" },
		ReturnOrder = "Rank-Prop",
		Args = { Rank = "STRING", Prop = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:DenyProp( owner, rank, prop )
		if !string.Right( prop, 4 ) == ".mdl" then prop = prop .. ".mdl" end
		return self:DenyObject( owner, rank, "props", prop )
	end
	PLUGIN:AddCommand( "denyprop", {
		Call = PLUGIN.DenyProp,
		Desc = "Allows users to deny props to ranks.",
		Console = { "denyprop" },
		Chat = { "!denyprop" },
		ReturnOrder = "Rank-Prop",
		Args = { Rank = "STRING", Prop = "STRING" },
		Category = "Restrictions",
	})
	
--[[ -----------------------------------
		SWEPS
     ----------------------------------- ]]
	function PLUGIN:AllowSwep( owner, rank, swep )
		return self:AllowObject( owner, rank, "sweps", swep )
	end
	PLUGIN:AddCommand( "allowswep", {
		Call = PLUGIN.AllowSwep,
		Desc = "Allows users to remove disallowed sweps from a rank.",
		Console = { "allowswep" },
		Chat = { "!allowswep" },
		ReturnOrder = "Rank-Swep",
		Args = { Rank = "STRING", Swep = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:DenySwep( owner, rank, swep )
		return self:DenyObject( owner, rank, "sweps", swep )
	end
	PLUGIN:AddCommand( "denyswep", {
		Call = PLUGIN.DenySwep,
		Desc = "Allows users to deny sweps to ranks.",
		Console = { "denyswep" },
		Chat = { "!denyswep" },
		ReturnOrder = "Rank-Swep",
		Args = { Rank = "STRING", Swep = "STRING" },
		Category = "Restrictions",
	})
	
--[[ -----------------------------------
		STOOLS
     ----------------------------------- ]]
	function PLUGIN:AllowStool( owner, rank, stool )
		return self:AllowObject( owner, rank, "stools", stool )
	end
	PLUGIN:AddCommand( "allowstool", {
		Call = PLUGIN.AllowStool,
		Desc = "Allows users to remove disallowed stools from a rank.",
		Console = { "allowstool" },
		Chat = { "!allowstool" },
		ReturnOrder = "Rank-Stool",
		Args = { Rank = "STRING", Stool = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:DenyStool( owner, rank, stool )
		return self:DenyObject( owner, rank, "stools", stool )
	end
	PLUGIN:AddCommand( "denystool", {
		Call = PLUGIN.DenyStool,
		Desc = "Allows users to deny stools to ranks.",
		Console = { "denystool" },
		Chat = { "!denystool" },
		ReturnOrder = "Rank-Stool",
		Args = { Rank = "STRING", Stool = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:PrintRestrictions( owner )
		
		owner:Print( exsto_CLIENT, "--- Rank Restriction Data ---\n" )
		
		for k,v in pairs( self.Restrictions ) do
			owner:Print( exsto_CLIENT_NOLOGO, " Rank: " .. k )
			
			owner:Print( exsto_CLIENT_NOLOGO, "    ** Props: " )
			for _, prop in ipairs( v.Props ) do
				owner:Print( exsto_CLIENT_NOLOGO, "       -- " .. prop )
			end
			
			owner:Print( exsto_CLIENT_NOLOGO, "    ** Entities: " )
			for _, ent in ipairs( v.Entities ) do
				owner:Print( exsto_CLIENT_NOLOGO, "       -- " .. ent )
			end
			
			owner:Print( exsto_CLIENT_NOLOGO, "    ** Sweps: " )
			for _, swep in ipairs( v.Sweps ) do
				owner:Print( exsto_CLIENT_NOLOGO, "       -- " .. swep )
			end
			
			owner:Print( exsto_CLIENT_NOLOGO, "    ** Stools: " )
			for _, stool in ipairs( v.Stools ) do
				owner:Print( exsto_CLIENT_NOLOGO, "       -- " .. stool )
			end
			
			owner:Print( exsto_CLIENT_NOLOGO, "\n" )
		end
		
		owner:Print( exsto_CLIENT, "--- End of Restriction Data Print ---\n" )
		
		return { owner, COLOR.NORM, "All rank restrictions have been printed to your ", COLOR.NAME, "console", COLOR.NORM, "!" }
	
	end
	PLUGIN:AddCommand( "printrestrict", {
		Call = PLUGIN.PrintRestrictions,
		Desc = "Allows users to print rank restrictions.",
		Console = { "restrictions" },
		Chat = { "!restrictions" },
		Args = { },
		Category = "Restrictions",
	})

elseif CLIENT then

	local function invalidate( cat, l )
		l:SetDirty( true )
		l:InvalidateLayout( true )
		
		l:SizeToContents()
		
		cat:InvalidateLayout( true )
	end
	
	local function restrictLineSelected( lst, disp, data, line )
		PLUGIN.WorkingItem = {
			Name = disp[1];
			Data = data;
			Type = type( data ) == "string" and 1 or 0; -- Ranks are 1, players are 0
		}
		
		exsto.Menu.EnableBackButton()
		exsto.Menu.OpenPage( PLUGIN.Select )
	end

	local function restrictInit( pnl )
		
		local rankCat = pnl:CreateCategory( "Ranks" )
		pnl.RankList = vgui.Create( "ExListView", rankCat )
			pnl.RankList:Dock( TOP )
			pnl.RankList:DisableScrollbar()
			pnl.RankList:SetQuickList()
			pnl.RankList:AddColumn( "" )
			pnl.RankList:SetHideHeaders( true )
			pnl.RankList.LineSelected = restrictLineSelected
			pnl.RankList.Populate = function( s, data )
				s:Clear()
				
				for rID, rank in pairs( data ) do					
					s:AddRow( { rank.Name }, rID )
				end
				
				s:SortByColumn( 1 )
				invalidate( rankCat, s )
			end
			
		local playerCat = pnl:CreateCategory( "Players" )
		pnl.PlayerList = vgui.Create( "ExListView", playerCat )
			pnl.PlayerList:Dock( TOP )
			pnl.PlayerList:DisableScrollbar()
			pnl.PlayerList:SetQuickList()
			pnl.PlayerList:AddColumn( "" )
			pnl.PlayerList:SetHideHeaders( true )
			pnl.PlayerList.LineSelected = restrictLineSelected
			pnl.PlayerList.Populate = function( s, data )
				s:Clear()
				
				for _, ply in ipairs( player.GetAll() ) do					
					s:AddRow( { ply:Nick() }, ply:SteamID() )
				end
				
				s:SortByColumn( 1 )
				invalidate( playerCat, s )
			end
			
	end

	local function onRestrictShowtime( obj )
		local pnl = obj.Content
		pnl.RankList:Populate( exsto.Ranks )
		pnl.PlayerList:Populate()
	end
	
	local function selectInit( pnl )
		pnl.Cat = pnl:CreateCategory( "%ITEM" )
		
		pnl.Cat:CreateTitle( "Weapons" )
		pnl.Cat:CreateHelp( "Select SWEPS to restrict to users or ranks." )
		local button = pnl.Cat:CreateButton( "Go" )
			button.OnClick = function( b )
				exsto.Menu.OpenPage( PLUGIN.WeaponPage )
			end
		
		pnl.Cat:CreateSpacer()
		
		pnl.Cat:CreateTitle( "Props" )
		pnl.Cat:CreateHelp( "View a list of all restricted props.  To add a prop, right click on it in the spawn menu." )
		local button = pnl.Cat:CreateButton( "Go" )
			button.OnClick = function( b )
				exsto.Menu.OpenPage( PLUGIN.PropPage )
			end
		
		pnl.Cat:CreateSpacer()
		
		pnl.Cat:CreateTitle( "Tools" )
		pnl.Cat:CreateHelp( "Select STOOLS to restrict to users or ranks." )
		local button = pnl.Cat:CreateButton( "Go" )
			button.OnClick = function( b )
				exsto.Menu.OpenPage( PLUGIN.ToolPage )
			end
		
		pnl.Cat:CreateSpacer()
		
		pnl.Cat:CreateTitle( "Entities" )
		pnl.Cat:CreateHelp( "Select entities to restrict to users or ranks." )
		local button = pnl.Cat:CreateButton( "Go" )
			button.OnClick = function( b )
				exsto.Menu.OpenPage( PLUGIN.ENTPage )
			end
		
		pnl.Cat:InvalidateLayout( true )
	end
	
	local function onSelectShowtime( obj )
		local pnl = obj.Content
		
		pnl.Cat.Header:SetText( PLUGIN.WorkingItem.Name )
	end
	
	-- Reusables
	
	local function lineOver( line )
		surface.SetDrawColor( 255, 255, 255, 255 )
		-- When restricted, 2 == true. So we set red, other wise green.
		if line.Info.Data[ 2 ] then surface.SetMaterial( PLUGIN.Materials.Red ) else surface.SetMaterial( PLUGIN.Materials.Green ) end
		surface.DrawTexturedRect( 5, (line:GetTall() / 2 ) - 3, 8, 8 )
	end
	local function backToSelect( obj )
		exsto.Menu.OpenPage( PLUGIN.Select )
	end
	local function request( w )
		local sender = exsto.CreateSender( "ExReqRestrict" )
			sender:AddShort( w )
			sender:AddBool( PLUGIN.WorkingItem.Type ) -- What type this is
			sender:AddString( PLUGIN.WorkingItem.Data ) -- What we're looking for
		sender:Send()
	end
	local function update( w, data )
		-- Push the change up to the server.
		local sender = exsto.CreateSender( "ExUpdateRestriction" )
			sender:AddShort( w )
			sender:AddBool( PLUGIN.WorkingItem.Type )
			sender:AddString( PLUGIN.WorkingItem.Data )
			sender:AddString( data[ 1 ] )
			sender:AddBool( not data[ 2 ] ) -- This "SHOULD" switch false to true and true to false :)
		sender:Send()
	end
	local function recRestrict( reader )
		local w = reader:ReadShort()
		local pg = PLUGIN.WeaponPage
		if w == 2 then pg = PLUGIN.ToolPage
			elseif w == 3 then pg = PLUGIN.PropPage
			elseif w == 4 then pg = PLUGIN.ENTPage
		end
		
		if not pg:IsActive() then return end
		
		local tbl = {}
		for I = 1, reader:ReadShort() do
			table.insert( tbl, { reader:ReadString(), reader:ReadBool() } ) -- Name, restricted
		end

		pg.Content.List:Populate( tbl )
	end
	exsto.CreateReader( "ExReceiveRestriction", recRestrict )
	
	--[[ -----------------------
		Weapon Restrictions ----
		------------------------ ]]
		
	-- This is literally copy and pasted 3/4 times for the other restrictions.  Fuck making it clean.  I really just want to release exsto now.

	local function weaponInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Weapons" )
		
		pnl.List = vgui.Create( "ExListView", pnl.Cat )
			pnl.List:DockMargin( 4, 0, 4, 0 )
			pnl.List:Dock( TOP )
			pnl.List:DisableScrollbar()
			pnl.List:AddColumn( "" )
			pnl.List:SetHideHeaders( true )
			pnl.List:SetQuickList()
			pnl.List:LinePaintOver( lineOver )
			pnl.List:SetTextInset( 25 )
			pnl.List.Populate = function( o, data )
				o:Clear()
				for I = 1, #data do
					o:AddRow( { data[ I ][ 1 ] }, data[ I ] )
				end
				o:SortByColumn( 1 )
				invalidate( pnl.Cat, o )
			end
			
			pnl.List.LineSelected = function( lst, disp, data, line )
				update( 1, data )
			end
			
		pnl.Cat:InvalidateLayout( true )
	end

	--[[ -----------------------
		ENT Restrictions ----
		------------------------ ]]
	
	local function ENTInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Entities" )
		
		pnl.List = vgui.Create( "ExListView", pnl.Cat )
			pnl.List:DockMargin( 4, 0, 4, 0 )
			pnl.List:Dock( TOP )
			pnl.List:DisableScrollbar()
			pnl.List:AddColumn( "" )
			pnl.List:SetHideHeaders( true )
			pnl.List:SetQuickList()
			pnl.List:LinePaintOver( lineOver )
			pnl.List:SetTextInset( 25 )
			pnl.List.Populate = function( o, data )
				o:Clear()
				for I = 1, #data do
					o:AddRow( { data[ I ][ 1 ] }, data[ I ] )
				end
				o:SortByColumn( 1 )
				invalidate( pnl.Cat, o )
			end
			
			pnl.List.LineSelected = function( lst, disp, data, line )
				update( 4, data )
			end
			
		pnl.Cat:InvalidateLayout( true )
	end

	function PLUGIN:Init()
		self.List = exsto.Menu.CreatePage( "restrictions", restrictInit )
			self.List:SetTitle( "Restrictions" )
			self.List:SetSearchable( true )
			self.List:OnShowtime( onRestrictShowtime )
			self.List:OnSearchTyped( onRestrictTyped )
			
		self.Select = exsto.Menu.CreatePage( "restrictionselect", selectInit )
			self.Select:SetTitle( "Restrictions" )
			self.Select:OnShowtime( onSelectShowtime )
			self.Select:SetUnaccessable()
			self.Select:SetBackFunction( function( obj )
				exsto.Menu.OpenPage( PLUGIN.List )
				exsto.Menu.DisableBackButton()
				
				PLUGIN.WorkingItem = nil
			end )
			
		self.WeaponPage = exsto.Menu.CreatePage( "restrictweapon", weaponInit )
			self.WeaponPage:SetTitle( "Weapons" )
			self.WeaponPage:OnShowtime( function( obj ) request( 1 ) end )
			self.WeaponPage:SetBackFunction( backToSelect )
			self.WeaponPage:SetUnaccessable()
			
		self.ToolPage = exsto.Menu.CreatePage( "restricttool", toolInit )
			self.ToolPage:SetTitle( "Tools" )
			self.ToolPage:OnShowtime( onToolShowtime )
			self.ToolPage:SetBackFunction( backToSelect )
			self.ToolPage:SetUnaccessable()
			
		self.ENTPage = exsto.Menu.CreatePage( "restrictent", ENTInit )
			self.ENTPage:SetTitle( "Entities" )
			self.ENTPage:OnShowtime( function( obj ) request( 4 ) end )
			self.ENTPage:SetBackFunction( backToSelect )
			self.ENTPage:SetUnaccessable()
			
		self.Materials = {
			Red = Material( "exsto/red.png" );
			Green = Material( "exsto/green.png" );
		}
	end
	
	
	
end

PLUGIN:Register()
