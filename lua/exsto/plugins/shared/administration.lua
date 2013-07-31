-- Exsto 
-- Administration Plugin 

local PLUGIN = exsto.CreatePlugin() 

PLUGIN:SetInfo({ 
	 Name = "Administration", 
	 ID = "administration", 
	 Desc = "A plugin that monitors kicking and banning of players.", 
	 Owner = "Prefanatic", 
	 Experimental = false, 
} ) 

if SERVER then 

	util.AddNetworkString( "ExRecBan" )
	util.AddNetworkString( "ExRecBanRemove" )
	util.AddNetworkString( "ExRequestBans" )
	util.AddNetworkString( "ExUnbanPlayer" )
	util.AddNetworkString( "ExUpdateBanLen" )
	
	
	local function setRefresh( old, val )
		if !exsto.BanDB then return false, "Ban table doesn't exist!" end
		
		exsto.BanDB:SetRefreshRate( val * 60 )
	end

	function PLUGIN:Init() 
		exsto.CreateFlag( "banlist", "Allows users to access the ban list." )
		exsto.CreateFlag( "banlistdetails", "Allows users to see the details of a ban in the ban page." )
		
		self.BanRefreshRate = exsto.CreateVariable( "ExBanRefreshRate",
			"Ban Refresh Rate",
			3,
			"How often bans should be refreshed."
		)
		self.BanRefreshRate:SetCallback( setRefresh )
		self.BanRefreshRate:SetCategory( "Administration" )
		self.BanRefreshRate:SetUnit( "Time (minutes)" )
		
		self.OldPlayers = {}
		exsto.BanDB = FEL.CreateDatabase( "exsto_data_bans" )
			exsto.BanDB:SetDisplayName( "Bans" )
			exsto.BanDB:ConstructColumns( {
				Name = "TEXT:not_null";
				SteamID = "VARCHAR(50):primary:not_null";
				Length = "INTEGER:not_null";
				Reason = "TEXT";
				BannedBy = "TEXT:not_null";
				BannerID = "VARCHAR(50)";
				BannedAt = "INTEGER:not_null";
			} )
			exsto.BanDB:SetRefreshRate( self.BanRefreshRate:GetValue() * 60 )
			
		-- Setup our "gatekeeper"  Its sad the module died :(
		gameevent.Listen( "player_connect" )
		gameevent.Listen( "player_disconnect" )
	end 
	function PLUGIN:ExUpdateBanLen( reader )
		return reader:ReadSender():IsAllowed( "banlist" )
	end
	function PLUGIN:UpdateBanLength( reader )
		local ply = reader:ReadSender()
		local id = reader:ReadString()
		local val = reader:ReadShort()
		
		self:Debug( "Updating ban length for '" .. id .. "' to value '" .. val .. "' by player '" .. ply:Nick() .. "'", 1 )
		
		exsto.BanDB:AddRow( {
			SteamID = id;
			Length = val;
		} )
	end
	PLUGIN:CreateReader( "ExUpdateBanLen", PLUGIN.UpdateBanLength )
	
	function PLUGIN:ExUnbanPlayer( reader )
		return reader:ReadSender():IsAllowed( "banlist" ) and reader:ReadSender():IsAllowed( "unban" )
	end
	
	function PLUGIN:MenuUnbanPlayer( reader )
		local ply = reader:ReadSender()
		local steamid = reader:ReadString()
		
		self:Debug( "Unbanning player '" .. steamid .. "' triggered by '" .. ply:GetName() .. "'", 1 )
		self:UnBan( ply, steamid )
	end
	PLUGIN:CreateReader( "ExUnbanPlayer", PLUGIN.MenuUnbanPlayer )
	
	function PLUGIN:Drop( uid, reason )
		game.ConsoleCommand( string.format( "kickid %d %s\n", uid, reason:gsub( ";|\n", "" ) ) ) -- Taken from Map in a box - http://facepunch.com/showthread.php?t=695636&p=38514535&viewfull=1#post38514535
	end
	
	local function callHook( data )
		hook.Call( "ExPlayerConnect", nil, data )
	end
	
	function PLUGIN:player_connect( data )
		if game.SinglePlayer() then return end -- Don't bother.  Theres only going to be one person on, and thats the host.
		if !data.networkid then return end
		
		exsto.BanDB:GetRow( data.networkid, function( q, d )
			if not d then callHook( data ) return end
			local bannedAt, banLen, banReason = tonumber( d.BannedAt ), tonumber( d.Length ), d.Reason

			-- If hes perma banned, designated by length == 0
			if banLen == 0 then self:Drop( data.userid, "You are perma-banned!" ) return end
			
			banLen = banLen * 60;

			local timeleft = exsto.NiceTime( ( ( banLen + bannedAt ) - os.time() ) / 60 ) 
			
			-- Make sure we remove his ban if it has expired.
			if banLen + bannedAt <= os.time() then exsto.BanDB:DropRow( data.networkid ) self:ResendBans() callHook( data ) return end
			if timeleft and banReason then self:Drop( data.userid, "BANNED! Time left: " .. timeleft .. " - Reason: " .. banReason ) return end
			
			-- Call our after-ban hook
			callHook( data )
		end )
	
	end
	PLUGIN:SetHookPriority( "player_connect", 1 )
	
	function PLUGIN:player_disconnect( data )
		--PrintTable( data )
	end
	
	function PLUGIN:Kick( owner, ply, reason ) 
		self:Drop( ply:UserID(), reason )
		return { 
			Activator = owner, 
			Player = ply, 
			Wording = " has kicked ", 
			Secondary = " with reason: " .. reason 
		}
	end 
	PLUGIN:AddCommand( "kick", { 
		Call = PLUGIN.Kick, 
		Desc = "Allows users to kick players.", 
		Console = { "kick" }, 
		Chat = { "!kick" }, 
		ReturnOrder = "Victim-Reason", 
		Args = {Victim = "PLAYER", Reason = "STRING"}, 
		Optional = {Reason = "Kicked by [self]"}, 
		Category = "Administration", 
		DisallowCaller = true, 
	}) 
	PLUGIN:RequestQuickmenuSlot( "kick", "Kick", { 
		Reason = { 
			{ Display = "General Asshat" }, 
			{ Display = "Breaking the rules." }, 
			{ Display = "Minge" }, 
			{ Display = "We hate you." }, 
		}, 
	} ) 

	function PLUGIN:PlayerDisconnected( ply ) 
		self.OldPlayers[ ply:SteamID() ] = ply:Nick()
	end 

	function PLUGIN:BanID( owner, id, len, reason ) 
		if type( id ) == "Player" then 
			return self:Ban( owner, id, len, reason ) 
		end 

		if !string.match( id, "STEAM_[0-5]:[0-9]:[0-9]+" ) then
			return { owner, COLOR.NAME, "Invalid SteamID.", COLOR.NORM, "A normal SteamID looks like this, ", COLOR.NAME, "STEAM_0:1:123456" }
		end
		
		-- Check and see if we can grab any information we might have from this man.
		local name = self.OldPlayers[ id ] or id
		
		-- Save his stuff yo.		
		exsto.BanDB:AddRow( {
			Name = name;
			SteamID = id;
			Reason = reason;
			Length = len;
			BannedBy = owner:Name() or "Console";
			BannedAt = os.time();
			BannerID = owner:SteamID() or "Console";
		} )
		
		self:ResendBans()

		return {
			Activator = owner,
			Object = name,
			Wording = " has banned ",
			Secondary = " for " .. exsto.NiceTime( len ) .. " with reason: " .. reason 
		}

	end 
	PLUGIN:AddCommand( "banid", { 
		Call = PLUGIN.BanID, 
		Desc = "Allows users to ban players via SteamID.", 
		Console = { "banid" }, 
		Chat = { "!banid" }, 
		ReturnOrder = "SteamID-Length-Reason", 
		Args = {SteamID = "STRING", Length = "NUMBER", Reason = "STRING"}, 
		Optional = {SteamID = "", Length = 0, Reason = "Banned by [self]"}, 
		Category = "Administration", 
	}) 

	function PLUGIN:Ban( owner, ply, len, reason ) 
		local nick = ply:Nick()
		
		-- Quick hack to allow non-exsto things to use this.
		local ownerNick, ownerID = "Console", "Console"
		if IsValid( owner ) and type( owner ) == "Player" then
			ownerNick = owner:Nick()
			ownerID = owner:SteamID()
		end
		
		if game.SinglePlayer() then return { exsto_CHAT, COLOR.NORM, "You can't ban yourself in a ", COLOR.NAME, "single player", COLOR.NORM, " game." } end
		if ply:IsListenServerHost() then return { exsto_CHAT, COLOR.NORM, "You can't ban the ", COLOR.NAME, "listen server host", COLOR.NORM, "." } end
		
		-- Save his stuff yo.		
		exsto.BanDB:AddRow( {
			Name = ply:Nick();
			SteamID = ply:SteamID();
			Reason = reason;
			Length = len;
			BannedBy = ownerNick;
			BannedAt = os.time();
			BannerID = ownerID;
		} )
		
		self:Drop( ply:UserID(), reason )
		
		self:ResendBans()

		return { 
			Activator = owner, 
			Player = nick, 
			Wording = " has banned ", 
			Secondary = " for " .. exsto.NiceTime( len ) .. " with reason: " .. reason 
		} 

	end 
	PLUGIN:AddCommand( "ban", { 
		Call = PLUGIN.Ban, 
		Desc = "Allows users to ban players.", 
		Console = { "ban" }, 
		Chat = { "!ban" }, 
		ReturnOrder = "Victim-Length-Reason", 
		Args = {Victim = "ONEPLAYER", Length = "NUMBER", Reason = "STRING"}, 
		Optional = {Length = 0, Reason = "Banned by [self]"}, 
		Category = "Administration", 
		DisallowCaller = true, 
	}) 
	PLUGIN:RequestQuickmenuSlot( "ban", "Ban", { 
		Length = { 
			{ Display = "Forever", Data = 0 }, 
			{ Display = "5 minutes", Data = 5 }, 
			{ Display = "10 minutes", Data = 10 }, 
			{ Display = "30 minutes", Data = 30 }, 
			{ Display = "One hour", Data = "h:1" }, 
			{ Display = "Five hours", Data = "h:5" }, 
			{ Display = "One day", Data = "d:1" }, 
			{ Display = "Two days", Data = "d:2" }, 
			{ Display = "One week", Data = "w:1" }, 
		}, 
		Reason = { 
			{ Display = "General Asshat" }, 
			{ Display = "Breaking the rules." }, 
			{ Display = "Minge" }, 
			{ Display = "We hate you." }, 
		}, 
	} ) 

	function PLUGIN:UnBan( owner, steamid ) 
	
		-- Load up our ban database for reference.
		exsto.BanDB:GetAll( function( q, data )
			if not data or table.Count( data ) == 0 then
				owner:Print( exsto_CHAT, COLOR.NAME, steamid, COLOR.NORM, " is not banned!" )
				return
			end
	
			local dataUsed = false
			if !string.match( steamid, "STEAM_[0-5]:[0-9]:[0-9]+" ) and steamid != "BOT" then
				-- We don't have a match.  Try checking our ban list for his name like this.
				for _, ban in ipairs( data ) do
					if ban.Name:lower() == steamid:lower() then
						-- We found a name of a player; unban him like this.
						dataUsed = true
						steamid = ban.SteamID
						break
					end
				end
				
				-- Check our match again
				if !string.match( steamid, "STEAM_[0-5]:[0-9]:[0-9]+" ) and steamid != "BOT" then
					owner:Print( exsto_CHAT, COLOR.NORM, "That is an invalid ", COLOR.NAME, "SteamID!", COLOR.NORM, "  A normal SteamID looks like this, ", COLOR.NAME, "STEAM_0:1:123456" )
					return
				end
			end
			
			-- Check to see if this ban actually exists.
			local found = false
			for _, ban in ipairs( data ) do
				if ban.SteamID == steamid then found = true break end
			end
			
			if !found then
				owner:Print( exsto_CHAT, COLOR.NAME, steamid, COLOR.NORM, " is not banned!" )
				return
			end
			
			game.ConsoleCommand( "removeid " .. steamid .. ";writeid\n" ) -- Do this regardless.
			
			local name = "Unknown"
			for _, data in ipairs( data ) do 
				if data.SteamID == steamid then
					name = data.Name
				end 
			end 
			
			exsto.BanDB:DropRow( steamid, function( q, d ) 
				self:ResendBans()
				exsto.Print( exsto_CHAT_ALL, COLOR.NAME, owner:Nick(), COLOR.NORM, " has unbanned ", COLOR.NAME, steamid .. " (" .. name .. ")" )
			end )
		end )

	end 
		PLUGIN:AddCommand( "unban", { 
		Call = PLUGIN.UnBan, 
		Desc = "Allows users to unban players.", 
		Console = { "unban" }, 
		ReturnOrder = "SteamID", 
		Chat = { "!unban" }, 
		Args = {SteamID = "STRING"}, 
		Category = "Administration", 
	}) 
	 
	 function PLUGIN:Lookup( owner, data )
			 
			 local SearchType = ((string.Left(data,6) == "STEAM_") and "SteamID" or (string.Left(data,1,1) == "%" and "Group" or "Name"))
			 if SearchType == "SteamID" then data = string.upper( data )
			 elseif SearchType == "Group" then data = string.lower(string.sub(data,2))
			 end
			 
			 local users = exsto.UserDB:GetAll()
			
			local fply = {}
			 for _, user in ipairs( users ) do 
				if SearchType == "SteamID" then
					if user.SteamID == data then 
						fply = {user}
					end
				elseif SearchType == "Group" then
					if user.Rank == data then
						table.insert(fply,user)
					end
				else
					if string.lower(user.Name) == string.lower(data) then
						fply = {user}
						break
					elseif string.find(string.lower(user.Name),string.lower(data)) then
						table.insert(fply,user)
					end						
				end
			 end
			if table.Count(fply) == 0 then
				return { owner,COLOR.NORM,"No player found under the "..SearchType,COLOR.NAME," "..data,COLOR.NORM,"." }
			end
			for i,ply in pairs( fply ) do
				
				local LastTime, UserTime = exsto.TimeDB:GetData( ply.SteamID, "Last, Time" )
				
				local info = {
					{"\n  ~ Lookup table for "..ply.Name.." ~"},
					{"SteamID:     "..ply.SteamID},
					{"Rank:        "..ply.Rank},
					{"Last Joined: "..os.date( "%c", LastTime )},
					{"Total Time : "..timeToString(UserTime)}
				}

				local BanInfo = exsto.BanDB:Query( "SELECT BannedAt, Length, Reason FROM exsto_data_bans WHERE SteamID = " .. exsto.BanDB:Escape(ply.SteamID) .. ";" ) 
				if BanInfo then
					BInfo = BanInfo[1]
					table.insert(info,{" ~User is banned"})
					table.insert(info,{"Banned at: "..os.date("%c",BInfo.BannedAt)})
					table.insert(info,{"Banned to: "..(tonumber(BInfo.Length) > 0 and os.date("%c",BInfo.BannedAt + BInfo.Length) or "Permanent")})
					table.insert(info,{"Reason :   "..(BInfo.Reason or "No reason.")})
				end
				 
				for v,k in ipairs(info) do
					if owner:EntIndex() == 0 then owner:Print(exsto_CHAT,unpack(info[v]))
					else owner:Print(exsto_CLIENT,unpack(info[v])) end
				end
			end
			
			Cnt = table.Count(fply)
			local Str = ""
			for j,k in pairs (fply) do
				Str = Str.. k.Name..(fply[j+1] and ", " or "")
			end
			RColor = (Cnt == 1) and exsto.GetRankColor(fply[1].Rank) or COLOR.NAME
			 return { owner,COLOR.NORM,"Player"..(Cnt>1 and "s" or "")..": ",RColor,Str,COLOR.NORM," looked up, check console for info." }
			  
	 end 
	 --[[PLUGIN:AddCommand( "lookup", { 
			 Call = PLUGIN.Lookup, 
			 Desc = "Allows users to lookup a player's info.", 
			 Console = { "lookup" }, 
			 ReturnOrder = "FindWith", 
			 Chat = { "!lookup" }, 
			 Args = { FindWith = "STRING" }, 
			 Category = "Administration", 
	 })
	PLUGIN:RequestQuickmenuSlot( "lookup", "Lookup Info" )]]

	-- Hobo's thing.
	function timeToString(time)
		local ttime = time or 0
		local s = ttime % 60
		ttime = math.floor(ttime / 60)
		local m = ttime % 60
		ttime = math.floor(ttime / 60)
		local h = ttime % 24
		ttime = math.floor( ttime / 24 )
		local d = ttime % 7
		local w = math.floor(ttime / 7)
		local str = ""
		str = (w>0 and w.." week(s) " or "")..(d>0 and d.." day(s) " or "")
		
		return string.format( str.."%02i hour(s) %02i minute(s) %02i second(s)", h, m, s )
	end	  
	
	function PLUGIN:ResendBans( data )
		local function h( d )
			if not d then return end
			local plys = player.GetAll()
			for _, data in pairs( d ) do
				self:SendBan( data, plys )
			end
		end
		
		if data then h( d ) return end
		exsto.BanDB:GetAll( function( q, d ) h( d ) end )
	end
	
	function PLUGIN:SendBan( tbl, ply )
		local sender = exsto.CreateSender( "ExRecBan", ply )
			sender:AddString( tbl.SteamID )
			sender:AddString( tbl.Name )
			sender:AddString( tbl.Reason )
			sender:AddString( tbl.BannedBy )
			sender:AddShort( tbl.Length )
			sender:AddLong( tbl.BannedAt )
			sender:AddString( tbl.BannerID )
		sender:Send()
	end

	function PLUGIN:RequestBans( reader ) 
		ply = reader:ReadSender()
		exsto.BanDB:GetAll( function( q, d )
			print( table.Count( d ) ) 
			if not d then return end
			for k,v in pairs( d ) do 
				self:SendBan( v, ply )
			end 
		end )
	end 
	PLUGIN:CreateReader( "ExRequestBans", PLUGIN.RequestBans )

elseif CLIENT then 

	local function invalidate()
		local pnl = PLUGIN.Page.Content
		if !pnl then PLUGIN:Error( "Oh no!  Attempted to access invalid page contents." ) return end
		
		pnl.List:SetDirty( true )
		pnl.List:InvalidateLayout( true )
		
		pnl.List:SizeToContents()
		
		pnl.Cat:InvalidateLayout( true )
	end
	
	local function addBan( tbl )
		local pnl = PLUGIN.Page.Content
		if !pnl then return end -- We haven't opened the page yet.  No matter!
		
		local time = os.date( "%c", tbl.BannedAt + tbl.Length*60 )
		if tbl.Length == 0 then time = "permanent" end 
		
		local line = pnl.List:AddRow( { tbl.Name, time }, tbl )
		
		invalidate()
	end
	
	local function refreshList()
		local pnl = PLUGIN.Page.Content
		if !pnl then PLUGIN:Error( "Attempted to access invalid page!" ) return end
		
		pnl.List:Clear()
		for id, tbl in pairs( PLUGIN.Bans ) do
			addBan( tbl );
		end
		invalidate()

	end
	
	local function redBanRemove( reader )
		local id = reader:ReadString();
		
		PLUGIN.Bans[ id ] = nil;
		refreshList();
	end
	exsto.CreateReader( "ExRecBanRemove", recBanRemove )
		
	local function recBanAdd( reader )
		local tbl = {
			SteamID = reader:ReadString();
			Name = reader:ReadString();
			Reason = reader:ReadString();
			BannedBy = reader:ReadString();
			Length = reader:ReadShort();
			BannedAt = reader:ReadLong();
			BannerID = reader:ReadString();
		}
		PLUGIN.Bans[ tbl.SteamID ] = tbl;
		
		addBan( tbl );
	end
	exsto.CreateReader( "ExRecBan", recBanAdd )
	
	local function onRowSelected( lst, disp, data, line )
		PLUGIN.WorkingBan = data
		exsto.Menu.EnableBackButton()
		
		exsto.Menu.OpenPage( PLUGIN.Details )
	end
	
	local function banInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Bans" )

		pnl.List = vgui.Create( "ExListView", pnl.Cat )
			pnl.List:DockMargin( 4, 0, 4, 0 )
			pnl.List:Dock( TOP )
			pnl.List:DisableScrollbar()
			pnl.List:AddColumn( "" )
			pnl.List:AddColumn( "" )
			pnl.List.OnMouseWheeled = nil
			pnl.List:SetHideHeaders( true )
			pnl.List:SetQuickList()
			
			pnl.List.LineSelected = onRowSelected
			
		-- This needs to be run after a list has been filled with contents.
		invalidate()
	end
	
	local function onShowtime( pnl )
		-- Lets get our ban data
		pnl.Content.List:Clear()
		exsto.CreateSender( "ExRequestBans" ):Send()
	end
	
	local function banDetailsInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Details" )
		pnl.Cat:DockPadding( 4, 4, 4, 4 )
		
		local steamid = pnl.Cat:CreateTitle( "SteamID" )
		local steamidhelp = pnl.Cat:CreateHelp( "Click on the SteamID below to copy it to your clipboard!" )
		
		pnl.SteamIDEntry = vgui.Create( "DTextEntry", pnl.Cat )
			pnl.SteamIDEntry:Dock( TOP )
			pnl.SteamIDEntry:SetTall( 40 )
			pnl.SteamIDEntry:SetFont( "ExGenericText16" )
			--pnl.SteamIDEntry:SetEditable( false )
			pnl.SteamIDEntry.OnMousePressed = function( e, code ) if code == MOUSE_LEFT then SetClipboardText( e:GetValue() ) end end
			
		pnl.Cat:CreateSpacer();
		
		local reason = pnl.Cat:CreateTitle( "Reason" )
		
		pnl.Reason = pnl.Cat:CreateHelp( "%REASON" )
		
		local h = pnl.Cat:CreateHelp( "Slide below to change ban length." )

		pnl.Length = vgui.Create( "ExNumberChoice", pnl.Cat )
			pnl.Length:Dock( TOP )
			pnl.Length:SetValue( 0 )
			pnl.Length:SetMin( 0 )
			pnl.Length:SetMax( 24 * 60 )
			pnl.Length:SetTall( 40 )
			pnl.Length:Text( "Length (min)" )
			pnl.Length.OnValueSet = function( s, v )
				local sender = exsto.CreateSender( "ExUpdateBanLen" )
					sender:AddString( pnl.SteamIDEntry:GetValue() )
					sender:AddShort( v )
				sender:Send()
			end 
			
		pnl.Cat:CreateSpacer();
		
		local bannedby = pnl.Cat:CreateTitle( "Banned By" )
		
		pnl.BannedBy = pnl.Cat:CreateHelp( "%BANNER" )

		pnl.BannedBySteamIDEntry = vgui.Create( "DTextEntry", pnl.Cat )
			pnl.BannedBySteamIDEntry:Dock( TOP )
			pnl.BannedBySteamIDEntry:SetTall( 40 )
			pnl.BannedBySteamIDEntry:SetFont( "ExGenericText16" )
			--pnl.BannedBySteamIDEntry:SetEditable( false )
			pnl.BannedBySteamIDEntry.OnMousePressed = function( e, code ) if code == MOUSE_LEFT then SetClipboardText( e:GetValue() ) end end
			
		pnl.Cat:CreateSpacer();
		
		local bannedAt = pnl.Cat:CreateTitle( "Banned At" )
		
		pnl.BannedAt = pnl.Cat:CreateHelp( "%BANNEDAT" )
			
		pnl.Cat:CreateSpacer();
		
		pnl.Unban = vgui.Create( "ExQuickButton", pnl.Cat )
			pnl.Unban:Text( "Unban Player" )
			pnl.Unban:SetEvil()
			pnl.Unban:SetTall( 40 )
			pnl.Unban:Dock( TOP )
			pnl.Unban.OnClick = function( b )
				local sender = exsto.CreateSender( "ExUnbanPlayer" )
					sender:AddString( PLUGIN.WorkingBan.SteamID )
				sender:Send()
				
				exsto.Menu.OpenPage( PLUGIN.Page )
			end
	end
	
	local function backFunction( obj )
		exsto.Menu.OpenPage( PLUGIN.Page )
		exsto.Menu.DisableBackButton()
		
		PLUGIN.WorkingBan = nil
	end
	
	local function detailOnShowtime( obj )
		if !PLUGIN.WorkingBan then obj:Error( "Unable to load details." ) end
		local pnl = obj.Content
		local tbl = PLUGIN.WorkingBan
		
		pnl.Cat.Header:SetText( tbl.Name )
		pnl.SteamIDEntry:SetText( tbl.SteamID )
		pnl.Reason:SetText( tbl.Reason )
		pnl.Length:SetValue( tbl.Length )
		pnl.BannedBy:SetText( tbl.BannedBy )
		pnl.BannedBySteamIDEntry:SetText( tbl.BannerID )
		
		local date = os.date( "%m-%d-%y", tbl.BannedAt )
		local time = tostring( os.date( "%H:%M:%S", tbl.BannedAt ) )
	
		pnl.BannedAt:SetText( date .. " " .. time )
	end
	
	function PLUGIN:Init()
		self.Bans = {};
		self.Page = exsto.Menu.CreatePage( "banlist", banInit )
			self.Page:SetTitle( "Bans" )
			self.Page:SetSearchable( true )
			self.Page:SetIcon( "exsto/ban.png" )
			self.Page:OnShowtime( onShowtime )
		self.Details = exsto.Menu.CreatePage( "banlistdetails", banDetailsInit )
			self.Details:SetTitle( "Details" )
			self.Details:SetUnaccessable()
			self.Details:SetBackFunction( backFunction )
			self.Details:OnShowtime( detailOnShowtime )
			
	end

end 

PLUGIN:Register() 
