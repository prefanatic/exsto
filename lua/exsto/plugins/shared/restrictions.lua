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
	
		exsto.CreateFlag( "restrictions", "Allows access to the restrictions menu." )
	
		util.AddNetworkString( "ExReqRestrict" )
		util.AddNetworkString( "ExReceiveRestriction" )
		util.AddNetworkString( "ExUpdateRestriction" )
		
		self.DB = FEL.CreateDatabase( "exsto_restriction" )
			self.DB:SetDisplayName( "Restrictions" )
			self.DB:ConstructColumns( {
				ID = "VARCHAR(100):primary:not_null";
				Props = "TEXT";
				Stools = "TEXT";
				Entities = "TEXT";
				Sweps = "TEXT";
			} )
			
		self.NextCacheUpdate = exsto.CreateVariable( "ExRestrictionUpdate", "Refresh Delay", 30, "How often restrictions should update from the SQL tables.  The shorter the value, the more 'in-sync' restrictions will be with other servers, at the cost of more lag." )
			self.NextCacheUpdate:SetCategory( "Restrictions" )
			self.NextCacheUpdate:SetUnit( "Delay (minutes)" )
			self.NextCacheUpdate:SetMin( 1 )
		self.NextThink = CurTime() + ( self.NextCacheUpdate:GetValue() * 60 )
			
		self.Storage = {}
		
		-- Quality of service on the ranks database.
		self.DB:GetAll( function( q, d )
			for rID, rank in pairs( exsto.Ranks ) do
				local f = false
				for _, r in ipairs( d or {} ) do
					if r.ID == rID then 
						self.Storage[ r.ID ] = {
							Props = self:VonDeserialize( r.Props );
							Stools = self:VonDeserialize( r.Stools );
							Entities = self:VonDeserialize( r.Entities );
							Sweps = self:VonDeserialize( r.Sweps );
						}
						f = true
						break
					end
				end
				
				if not f then
					self.DB:AddRow( {
						ID = rID;
						Props = von.serialize( {} );
						Stools = von.serialize( {} );
						Entities = von.serialize( {} );
						Sweps = von.serialize( {} );
					} )
				end
			end
		end )
		
		-- Restriction types
		self.RestrictionTypes = {
			"Sweps",
			"Stools",
			"Props",
			"Entities",
		}
		
		self.LimitHandler = {}
	
	end
	
	function PLUGIN:RefreshStorage()
		self.DB:GetAll( function( q, d )
			for _, r in ipairs( d ) do
				self.Storage[ r.ID ] = {
					Props = self:VonDeserialize( r.Props );
					Stools = self:VonDeserialize( r.Stools );
					Entities = self:VonDeserialize( r.Entities );
					Sweps = self:VonDeserialize( r.Sweps );
				}
			end
		end )
	end
	
	function PLUGIN:OverrideGetCount()
		self.OldGetCount = exsto.Registry.Player.GetCount
		function exsto.Registry.Player.GetCount( s, ... )
			if s.ExNoLimits and self:IsEnabled() then return -1 end
			if table.HasValue( self.LimitHandler, s:GetRank() ) and self:IsEnabled() then return -1 end
			return self.OldGetCount( s, ... )
		end
		self.FuncTamperSeal = exsto.Registry.Player.GetCount
	end
	
	function PLUGIN:Think()
		if self.FuncTamperSeal != exsto.Registry.Player.GetCount then -- We've been overridden.
			self:Debug( "GetCount has been tampered.  Over-riding.", 1 )
			self:OverrideGetCount()
		end
		
		if CurTime() > self.NextThink then
			self:Debug( "Updating restriction storage.", 1 )
			self:RefreshStorage()
			self.NextThink = CurTime() + ( self.NextCacheUpdate:GetValue() * 60 )
		end
	end
	
	function PLUGIN:GetRestrictionType( short )
		return self.RestrictionTypes[ short ]
	end
	function PLUGIN:GetRestrictionList( short )
		if short == 1 then 
			local lst = table.Copy( list.Get( "Weapon" ) )
				lst[ "gmod_tool" ] = nil
			return lst 
		elseif short == 2 then 
			for _, wep in pairs( weapons.GetList() ) do
				if wep.ClassName == "gmod_tool" then 
					local t = wep.Tool
					for name, tool in pairs( t ) do
						t[ name ].ClassName = name
					end
					return t
				end
			end
		elseif short == 3 then return {}
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
		local id = reader:ReadString()
		local ply = reader:ReadSender()
		self:SendRestrictionData( w, id, ply )
	end
	PLUGIN:CreateReader( "ExReqRestrict", PLUGIN.SendRestrictions )
	
	function PLUGIN:SendPropRestrictionData( data, w, ply, sender )
		sender:AddShort( w )

		sender:AddShort( table.Count( data ) )
		for _, d in pairs( data ) do
			sender:AddString( d.Class )
			sender:AddBool( d.Enabled )
		end
		sender:Send()
	end
	
	function PLUGIN:SendRestrictionData( w, id, ply )
		local sender = exsto.CreateSender( "ExReceiveRestriction", ply )
		local lst = self:GetRestrictionList( w )
		local pn = "menu players"
		if type( ply ) == "Player" then pn = ply:Nick() end

		self:Debug( "Sending '" .. w .. "' restriction for '" .. id .. "' on player '" .. pn .. "'", 1 )
		
		local data = self:GetRestrictionData( id, w )
		if w == 3 then self:SendPropRestrictionData( data, w, ply, sender ) return end
		
		sender:AddShort( w )
		sender:AddShort( table.Count( lst ) )
		for _, ent in pairs( lst ) do
			sender:AddString( ent.ClassName )

			local f
			for _, d in ipairs( data ) do
				if d.Class == ent.ClassName then f = true sender:AddBool( d.Enabled ) break end
			end
			
			if not f then sender:AddBool( false ) end
		end
		sender:Send()
	end
	
	function PLUGIN:ExUpdateRestriction( reader )
		return reader:ReadSender():IsAllowed( "restrictions" )
	end
	function PLUGIN:UpdateRestriction( reader )
		local w = reader:ReadShort()
		local id = reader:ReadString()
		local class = reader:ReadString()
		local enabled = reader:ReadBool()
		local ply = reader:ReadSender()
		
		self:Debug( "Restricting '" .. w .. "' class '" .. class .. "' under identifier '" .. id .. "' as value '" .. tostring( enabled ) .. "'", 1 )


		local data = self:GetRestrictionData( id, w )
		self:UpdateEntry( w, id, data, class, enabled )
	end
	PLUGIN:CreateReader( "ExUpdateRestriction", PLUGIN.UpdateRestriction )
	
	function PLUGIN:UpdateEntry( w, id, data, class, enabled )
		if not self.Storage[ id ] then self.Storage[ id ] = {} end
		if not self.Storage[ id ][ self:GetRestrictionType( w ) ] then self.Storage[ id ][ self:GetRestrictionType( w ) ] = {} end
			
		local f
		for k, d in pairs( data ) do
			if d.Class == class then
				f = true
				self.Storage[ id ][ self:GetRestrictionType( w ) ][ k ].Enabled = enabled
			end
		end
		if not f then
			table.insert( self.Storage[ id ][ self:GetRestrictionType( w ) ], { Class = class, Enabled = enabled } )
		end
			
		self.DB:AddRow( self:ConstructDataSave( w, id, von.serialize( self.Storage[ id ][ self:GetRestrictionType( w ) ] ) ) )
		
		-- Resend
		self:SendRestrictionData( w, id, exsto.GetMenuPlayers() )
	end
	
	function PLUGIN:ExNoLimit( reader )
		return reader:ReadSender():IsAllowed( "restrictions" )
	end
	function PLUGIN:SetNoLimits( reader )
		local id = reader:ReadString()
		
		self:Debug( "Inserting '" .. id .. "' into no limit handler from player '" .. reader:ReadSender() .. "'", 2 )
		
		if string.match( id, "STEAM_[0-5]:[0-9]:[0-9]+" ) then -- Nolimiting a player!
			local ply = exsto.GetPlayerByID( id )
			self:NoLimits( reader:ReadSender(), ply )
			return
		end
		
		-- Now it's a rank, so just insert it I GUESS IF IT DOESNT EXIST.
		if not table.HasValue( self.LimitHandler, id ) then
			table.insert( self.LimitHandler, id )
		end
		
	end
	PLUGIN:CreateReader( "ExNoLimit", PLUGIN.SetNoLimits )
	
	function PLUGIN:VonDeserialize( d )
		if d == nil then d = "" end
		if d == "NULL" then d = "" end
		return von.deserialize( d )
	end
	
	-- NOTE FOR THE FUTURE:  I believe that after saving into a database, either FEL or SQLite/MySQL automagically changes null entries to become NULL strings.
	-- Which then von starts to deserialize because fuck it, and thats why this bug exists.
	function PLUGIN:GetRestrictionData( id, w, c )
		--[[self.DB:GetData( id, self:GetRestrictionType( w ), function( q, data )
			data = data[ self:GetRestrictionType( w ) ] or ""
			
			if data == "NULL" then data = "" end
			c( von.deserialize( data ) )
		end )]]
		
		return self.Storage[ id ] and self.Storage[ id ][ self:GetRestrictionType( w ) ] or {}
	end
	
	function PLUGIN:NoLimitRank( caller, rank )
		if not exsto.Ranks[ rank ] then
			local str = exsto.GetClosestString( rank, exsto.Ranks, "ID" )
			return { caller, COLOR.NORM, "We couldn't find the rank ", COLOR.NAME, rank, COLOR.NORM, ".  Maybe you're looking for ", COLOR.NAME, str, COLOR.NORM, "?" }
		end
		
		if not table.HasValue( self.LimitHandler, rank ) then
			table.insert( self.LimitHandler, rank )
			return { COLOR.NAME, caller, COLOR.NORM, " has disabled limits on the rank ", COLOR.NAME, rank }
		else
			for _, id in ipairs( self.LimitHandler ) do
				if id == rank then table.remove( self.LimitHandler, _ ) break end
			end
			return { COLOR.NAME, caller, COLOR.NORM, " has re-enabled limits on the rank ", COLOR.NAME, rank }
		end
	end
	PLUGIN:AddCommand( "nolimitrank", {
		Call = PLUGIN.NoLimitRank,
		Desc = "Allows users to set nolimits on a rank.",
		Console = { "nolimitrank" },
		Chat = { "!nolimitrank" },
		ReturnOrder = "Rank",
		Args = { Rank = "STRING" },
		Category = "Restrictions",
	})
	
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
		Category = "Restrictions",
	})
	PLUGIN:RequestQuickmenuSlot( "nolimits", "No Limits" )
	
	function PLUGIN:ExOnRankCreate( ID )
		-- TODO
	end
	
	function PLUGIN:Allowed( ply, w, class )
		-- Is the PLAYER allowed?
		local data = self:GetRestrictionData( ply:SteamID(), w )
		for _, d in pairs( data ) do
			if ( d.Class:lower() == class ) and d.Enabled then return false end
		end

		-- If we passed the player, is the RANK allowed?
		local data = self:GetRestrictionData( ply:GetRank(), w )
		for _, d in pairs( data ) do
			if ( d.Class:lower() == class ) and d.Enabled then return false end
		end
	
		return true
	end

	function PLUGIN:CanTool( ply, trace, tool )
		if not self:Allowed( ply, 2, tool ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The tool ", COLOR.NAME, tool, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	
	function PLUGIN:PlayerGiveSWEP( ply, class, wep )
		if not self:Allowed( ply, 1, class ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The weapon ", COLOR.NAME, class, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	function PLUGIN:PlayerSpawnSWEP( ply, class, wep )
		if not self:Allowed( ply, 1, class ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The weapon ", COLOR.NAME, class, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	
	function PLUGIN:PlayerSpawnProp( ply, prop )
		if not self:Allowed( ply, 3, prop:lower() ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The prop ", COLOR.NAME, prop, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	
	function PLUGIN:PlayerSpawnSENT( ply, class )
		if not self:Allowed( ply, 4, class ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The entity ", COLOR.NAME, class, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	
	function PLUGIN:AllowObject( owner, id, object, data, enabled )
		enabled = enabled or false
	
		self:Debug( "Attempting to set the status of '" .. object .. "', identifier '" .. id .. "' class name '" .. data .. "' to '" .. tostring( enabled ) .. "'", 2 )
	
		if not string.match( id, "STEAM_[0-5]:[0-9]:[0-9]+" ) and not exsto.Ranks[ id ] then
			return { owner, COLOR.NAME, "Sorry, ", COLOR.NORM, "we can't find the ID you've requested to restrict.  Please either use a ", COLOR.NAME, "rank ID", COLOR.NORM, " or a ", COLOR.NAME, "SteamID" }
		end

		local tbl = self:GetRestrictionData( id, object )
		local lst = self:GetRestrictionList( object )
		
		if !data or data == "" then
			return { owner, COLOR.NORM, "No ", COLOR.NAME, "restricting class", COLOR.NORM, " specified!" }
		end
		
		-- If we can find it in our table, or its a prop
		if exsto.TableHasMemberValue( lst, "ClassName", data ) or object == 3 then -- We foundddd it!  Restrict
			self:UpdateEntry( object, id, tbl, data, enabled )
			return { owner, COLOR.NAME, data, COLOR.NORM, " is now " .. ( enabled and "restricted." or "unrestricted." ) }
			
		else
			local str = exsto.GetClosestString( data, lst, "ClassName" )
			return { owner, COLOR.NORM, "Unable to find ", COLOR.NAME, data, COLOR.NORM, ".  Are you looking for ", COLOR.NAME, str, COLOR.NORM, "?" }
		end
	
	end
	
	function PLUGIN:DenyObject( owner, id, object, data, enabled )
		return self:AllowObject( owner, id, object, data, true )
	end
	
--[[ -----------------------------------
		ENTITIES
     ----------------------------------- ]]
	function PLUGIN:AllowEntity( owner, id, entity )
		return self:AllowObject( owner, id, 4, entity )
	end
	PLUGIN:AddCommand( "allowentity", {
		Call = PLUGIN.AllowEntity,
		Desc = "Allows users to remove disallowed entities from an id.",
		Console = { "allowentity" },
		Chat = { "!allowentity" },
		ReturnOrder = "ID-Entity",
		Args = { ID = "STRING", Entity = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:DenyEntity( owner, id, entity )
		return self:DenyObject( owner, id, 4, entity )
	end
	PLUGIN:AddCommand( "denyentity", {
		Call = PLUGIN.DenyEntity,
		Desc = "Allows users to deny entities to an id.",
		Console = { "denyentity" },
		Chat = { "!denyentity" },
		ReturnOrder = "ID-Entity",
		Args = { ID = "STRING", Entity = "STRING" },
		Category = "Restrictions",
	})
	
--[[ -----------------------------------
		PROPS
     ----------------------------------- ]]
	function PLUGIN:AllowProp( owner, id, prop )
		if !string.Right( prop, 4 ) == ".mdl" then prop = prop .. ".mdl" end
		return self:AllowObject( owner, id, 3, prop )
	end
	PLUGIN:AddCommand( "allowprop", {
		Call = PLUGIN.AllowProp,
		Desc = "Allows users to remove disallowed props from a rank.",
		Console = { "allowprop" },
		Chat = { "!allowprop" },
		ReturnOrder = "ID-Prop",
		Args = { ID = "STRING", Prop = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:DenyProp( owner, id, prop )
		if !string.Right( prop, 4 ) == ".mdl" then prop = prop .. ".mdl" end
		return self:DenyObject( owner, id, 3, prop )
	end
	PLUGIN:AddCommand( "denyprop", {
		Call = PLUGIN.DenyProp,
		Desc = "Allows users to deny props to ranks.",
		Console = { "denyprop" },
		Chat = { "!denyprop" },
		ReturnOrder = "ID-Prop",
		Args = { ID = "STRING", Prop = "STRING" },
		Category = "Restrictions",
	})
	
--[[ -----------------------------------
		SWEPS
     ----------------------------------- ]]
	function PLUGIN:AllowSwep( owner, id, swep )
		return self:AllowObject( owner, id, 1, swep )
	end
	PLUGIN:AddCommand( "allowswep", {
		Call = PLUGIN.AllowSwep,
		Desc = "Allows users to remove disallowed sweps from a rank.",
		Console = { "allowswep" },
		Chat = { "!allowswep" },
		ReturnOrder = "ID-Swep",
		Args = { ID = "STRING", Swep = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:DenySwep( owner, id, swep )
		return self:DenyObject( owner, id, 1, swep )
	end
	PLUGIN:AddCommand( "denyswep", {
		Call = PLUGIN.DenySwep,
		Desc = "Allows users to deny sweps to ranks.",
		Console = { "denyswep" },
		Chat = { "!denyswep" },
		ReturnOrder = "ID-Swep",
		Args = { ID = "STRING", Swep = "STRING" },
		Category = "Restrictions",
	})
	
--[[ -----------------------------------
		STOOLS
     ----------------------------------- ]]
	function PLUGIN:AllowStool( owner, id, stool )
		return self:AllowObject( owner, id, 2, stool )
	end
	PLUGIN:AddCommand( "allowstool", {
		Call = PLUGIN.AllowStool,
		Desc = "Allows users to remove disallowed stools from a rank.",
		Console = { "allowstool" },
		Chat = { "!allowstool" },
		ReturnOrder = "ID-Stool",
		Args = { ID = "STRING", Stool = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:DenyStool( owner, id, stool )
		return self:DenyObject( owner, id, 2, stool )
	end
	PLUGIN:AddCommand( "denystool", {
		Call = PLUGIN.DenyStool,
		Desc = "Allows users to deny stools to ranks.",
		Console = { "denystool" },
		Chat = { "!denystool" },
		ReturnOrder = "ID-Stool",
		Args = { ID = "STRING", Stool = "STRING" },
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
			Data = data[ 1 ];
			Type = data[ 2 ]; -- Ranks are 1, players are 0
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
			pnl.RankList.Populate = function( s, data, search )
				s:Clear()
				search = search or ""
				
				for rID, rank in pairs( data ) do
					if string.find( rank.Name:lower(), search:lower() ) then
						s:AddRow( { rank.Name }, { rID, 1 } )
					end
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
			pnl.PlayerList.Populate = function( s, search )
				s:Clear()
				search = search or ""
				
				for _, ply in ipairs( player.GetAll() ) do		
					if string.find( ply:Nick():lower(), search:lower() ) then
						s:AddRow( { ply:Nick() }, { ply:SteamID(), 0 } )
					end
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
			sender:AddString( PLUGIN.WorkingItem.Data ) -- What we're looking for
		sender:Send()
	end
	local function update( w, data )
		-- Push the change up to the server.
		local sender = exsto.CreateSender( "ExUpdateRestriction" )
			sender:AddShort( w )
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
			pnl.List.Populate = function( o, data, search )
				o:Clear()
				if not data then data = o._LastData else o._LastData = data end
				search = search or ""
				for I = 1, #data do
					if string.find( data[ I ][ 1 ]:lower(), search:lower() ) then
						o:AddRow( { data[ I ][ 1 ] }, data[ I ] )
					end
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
			pnl.List.Populate = function( o, data, search )
				o:Clear()
				if not data then data = o._LastData else o._LastData = data end
				search = search or ""
				for I = 1, #data do
					if string.find( data[ I ][ 1 ]:lower(), search:lower() ) then
						o:AddRow( { data[ I ][ 1 ] }, data[ I ] )
					end
				end
				o:SortByColumn( 1 )
				invalidate( pnl.Cat, o )
			end
			
			pnl.List.LineSelected = function( lst, disp, data, line )
				update( 4, data )
			end
			
		pnl.Cat:InvalidateLayout( true )
	end
	
	--[[ -----------------------
		Tools! ----
		------------------------ ]]
	
	local function toolInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Tools" )
		
		pnl.List = vgui.Create( "ExListView", pnl.Cat )
			pnl.List:DockMargin( 4, 0, 4, 0 )
			pnl.List:Dock( TOP )
			pnl.List:DisableScrollbar()
			pnl.List:AddColumn( "" )
			pnl.List:SetHideHeaders( true )
			pnl.List:SetQuickList()
			pnl.List:LinePaintOver( lineOver )
			pnl.List:SetTextInset( 25 )
			pnl.List.Populate = function( o, data, search )
				o:Clear()
				if not data then data = o._LastData else o._LastData = data end
				search = search or ""
				for I = 1, #data do
					if string.find( data[ I ][ 1 ]:lower(), search:lower() ) then
						o:AddRow( { data[ I ][ 1 ] }, data[ I ] )
					end
				end
				o:SortByColumn( 1 )
				invalidate( pnl.Cat, o )
			end
			
			pnl.List.LineSelected = function( lst, disp, data, line )
				update( 2, data )
			end
			
		pnl.Cat:InvalidateLayout( true )
	end
	
	--[[ -----------------------
		Props! ----
		------------------------ ]]
		
	local function propInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Props" )
		
		pnl.List = vgui.Create( "ExListView", pnl.Cat )
			pnl.List:DockMargin( 4, 0, 4, 0 )
			pnl.List:Dock( TOP )
			pnl.List:DisableScrollbar()
			pnl.List:AddColumn( "" )
			pnl.List:SetHideHeaders( true )
			pnl.List:SetQuickList()
			pnl.List:LinePaintOver( lineOver )
			pnl.List:SetTextInset( 25 )
			pnl.List.Populate = function( o, data, search )
				o:Clear()
				if not data then data = o._LastData else o._LastData = data end
				search = search or ""
				for I = 1, #data do
					if string.find( data[ I ][ 1 ]:lower(), search:lower() ) then
						o:AddRow( { data[ I ][ 1 ] }, data[ I ] )
					end
				end
				o:SortByColumn( 1 )
				invalidate( pnl.Cat, o )
			end
			
			pnl.List.LineSelected = function( lst, disp, data, line )
				update( 3, data )
			end
			
		pnl.Cat:CreateHelp( "This lists the props currently restricted to the item you're working on.  To restrict the props, go into the spawn menu and right click on the prop." )
			
		pnl.Cat:InvalidateLayout( true )
	end

	function PLUGIN:Init()
		self.List = exsto.Menu.CreatePage( "restrictions", restrictInit )
			self.List:SetFlag( "restrictions" )
			self.List:SetTitle( "Restrictions" )
			self.List:SetSearchable( true )
			self.List:OnShowtime( onRestrictShowtime )
			self.List:SetIcon( "exsto/restriction.png" )
			self.List:OnSearchTyped( function( e ) 
				self.List.Content.RankList:Populate( exsto.Ranks, e:GetValue() )
				self.List.Content.PlayerList:Populate( e:GetValue() )
			end )
			
		self.Select = exsto.Menu.CreatePage( "restrictionselect", selectInit )
			self.Select:SetFlag( "restrictions" )
			self.Select:SetTitle( "Restrictions" )
			self.Select:OnShowtime( onSelectShowtime )
			self.Select:SetUnaccessable()
			self.Select:SetBackFunction( function( obj )
				exsto.Menu.OpenPage( PLUGIN.List )
				exsto.Menu.DisableBackButton()
				
				PLUGIN.WorkingItem = nil
			end )
			
		self.WeaponPage = exsto.Menu.CreatePage( "restrictweapon", weaponInit )
			self.WeaponPage:SetFlag( "restrictions" )
			self.WeaponPage:SetTitle( "Weapons" )
			self.WeaponPage:OnShowtime( function( obj ) request( 1 ) end )
			self.WeaponPage:SetBackFunction( backToSelect )
			self.WeaponPage:OnSearchTyped( function( e ) self.WeaponPage.Content.List:Populate( nil, e:GetValue() ) end )
			self.WeaponPage:SetUnaccessable()
			
		self.ToolPage = exsto.Menu.CreatePage( "restricttool", toolInit )
			self.ToolPage:SetFlag( "restrictions" )
			self.ToolPage:SetTitle( "Tools" )
			self.ToolPage:OnShowtime( function( obj ) request( 2 ) end )
			self.ToolPage:SetBackFunction( backToSelect )
			self.ToolPage:OnSearchTyped( function( e ) self.ToolPage.Content.List:Populate( nil, e:GetValue() ) end )
			self.ToolPage:SetUnaccessable()
			
		self.ENTPage = exsto.Menu.CreatePage( "restrictent", ENTInit )
			self.ENTPage:SetFlag( "restrictions" )
			self.ENTPage:SetTitle( "Entities" )
			self.ENTPage:OnShowtime( function( obj ) request( 4 ) end )
			self.ENTPage:SetBackFunction( backToSelect )
			self.ENTPage:OnSearchTyped( function( e ) self.ENTPage.Content.List:Populate( nil, e:GetValue() ) end )
			self.ENTPage:SetUnaccessable()
			
		self.PropPage = exsto.Menu.CreatePage( "restrictprop", propInit )
			self.PropPage:SetFlag( "restrictions" )
			self.PropPage:SetTitle( "Props" )
			self.PropPage:OnShowtime( function( obj ) request( 3 ) end )
			self.PropPage:SetBackFunction( backToSelect )
			self.PropPage:OnSearchTyped( function( e ) self.PropPage.Content.List:Populate( nil, e:GetValue() ) end )
			self.PropPage:SetUnaccessable()
			
		self.Materials = {
			Red = Material( "exsto/red.png" );
			Green = Material( "exsto/green.png" );
		}
		
		properties.Add( "ExRestrictProp", {
			MenuLabel = "Restrict to...",
			Order = 2001,
			Filter = function( s, ent, ply )
				if not IsValid( ent ) or ent:IsPlayer() then return false end
				return ply:IsAllowed( "restrictions" )
			end,
			
			MenuOpen = function( s, option, ent, tr )
				local sub = option:AddSubMenu()
				
				-- Ranks first, then players
				for rID, rank in pairs( exsto.Ranks ) do
					sub:AddOption( rank.Name, function()
						PLUGIN.WorkingItem = {
							Type = 1,
							Data = rID,
						}
						update( 3, { ent:GetModel(), false } )
					end )
				end
				
				sub:AddSpacer()
				
				for _, ply in ipairs( player.GetAll() ) do
					sub:AddOption( ply:Nick(), function()
						PLUGIN.WorkingItem = {
							Type = 0,
							Data = ply:SteamID(),
						}
						update( 3, { ent:GetModel(), false } )
					end )
				end
			end,
		} )
		
		-- This is going to be some really fancy ass shit right here.  Hold onto your butts.
		self._DermaMenuOption = DMenu.AddOption
		local trigger = 0
		function DMenu.AddOption( d, txt, func )
			print( "HELLO!", txt, trigger )
			if txt == "Edit Icon" then trigger = trigger + 1 end
			if trigger == 1 and txt == "Delete" then 
				local pnl = self._DermaMenuOption( d, txt, func )
				local sub = d:AddSubMenu( "Add to Exsto Restrictions" )
				
				for rID, rank in pairs( exsto.Ranks ) do
					sub:AddOption( rank.Name, function()
						PLUGIN.WorkingItem = {
							Type = 1,
							Data = rID,
						}
						update( 3, { ent:GetModel(), false } )
					end )
				end
				
				sub:AddSpacer()
				
				for _, ply in ipairs( player.GetAll() ) do
					sub:AddOption( ply:Nick(), function()
						PLUGIN.WorkingItem = {
							Type = 0,
							Data = ply:SteamID(),
						}
						update( 3, { ent:GetModel(), false } )
					end )
				end
				trigger = 0
				return
			end		
			
			return self._DermaMenuOption( d, txt, func )
		end
	end
	
	
	
end

PLUGIN:Register()
