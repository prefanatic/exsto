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

	util.AddNetworkString( "ExRecBans" )
	
	PLUGIN:AddVariable( {
		Pretty = "FEL --> Ban Refresh Rate";
		Dirty = "fel.banrefreshrate";
		Default = 3 * 60;
		Description = "Changes how often FEL should refresh the ban table.  Defaults at 3 minutes.  Value is in seconds, not minutes.";
		OnChange = PLUGIN.RefreshRateChanged;
	} )
	
	function PLUGIN.RefreshRateChanged( val )
		if !exsto.BanDB then return false, "Ban table doesn't exist!" end
		
		exsto.BanDB:SetRefreshRate( val )
	end

	function PLUGIN:Init() 
		exsto.CreateFlag( "banlist", "Allows users to access the ban list." )
		
		self.OldPlayers = {}
		exsto.BanDB = FEL.CreateDatabase( "exsto_data_bans" )
			exsto.BanDB:ConstructColumns( {
				Name = "TEXT:not_null";
				SteamID = "VARCHAR(50):primary:not_null";
				Length = "INTEGER:not_null";
				Reason = "TEXT";
				BannedBy = "TEXT:not_null";
				BannerID = "VARCHAR(50)";
				BannedAt = "INTEGER:not_null";
			} )
			exsto.BanDB:SetRefreshRate( exsto.GetValue( "fel.banrefreshrate" ) )
			
		-- Setup our "gatekeeper"  Its sad the module died :(
		gameevent.Listen( "player_connect" )
		gameevent.Listen( "player_disconnect" )
	end 
	
	function PLUGIN:Drop( uid, reason )
		game.ConsoleCommand( string.format( "kickid %d %s\n", uid, reason:gsub( ";|\n", "" ) ) ) -- Taken from Map in a box - http://facepunch.com/showthread.php?t=695636&p=38514535&viewfull=1#post38514535
	end
	
	function PLUGIN:player_connect( data )
		if !data.networkid then return end
		
		local bannedAt, banLen, banReason = exsto.BanDB:GetData( data.networkid, "BannedAt, Length, Reason" )
		if !bannedAt or !banLen or !banReason then return end

		-- If hes perma banned, designated by length == 0
		if banLen == 0 then self:Drop( data.userid, "You are perma-banned!" ) return end
		
		banLen = banLen * 60
		
		local timeleft = string.ToMinutesSeconds( ( banLen + bannedAt ) - os.time() ) 
		
		-- Make sure we remove his ban if it has expired.
		if banLen + bannedAt <= os.time() then exsto.BanDB:DropRow( steam ) self:ResendToAll() return end
		if timeleft and banReason then self:Drop( data.userid, "BANNED! Time left: " .. timeleft .. " - Reason: " .. banReason ) return end
		
		-- Call our after-ban hook
		hook.Call( "ExPlayerConnect", nil, data )
	
	end
	
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
		
		self:ResendToAll()
		
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
		Args = {SteamID = "STRING", Length = "TIME", Reason = "STRING"}, 
		Optional = {SteamID = "", Length = 0, Reason = "Banned by [self]"}, 
		Category = "Administration", 
	}) 

	function PLUGIN:Ban( owner, ply, len, reason ) 
		local nick = ply:Nick()
		
		-- Quick hack to allow non-exsto things to use this.
		local ownerNick, ownerID = "Console", "Console"
		if owner and owner:IsValid() then
			ownerNick = owner:Nick()
			ownerID = owner:SteamID()
		end
		
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

		self:ResendToAll() 

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
		Args = {Victim = "PLAYER", Length = "TIME", Reason = "STRING"}, 
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
	
		local dataUsed = false
		if !string.match( steamid, "STEAM_[0-5]:[0-9]:[0-9]+" ) then
			-- We don't have a match.  Try checking our ban list for his name like this.
			for _, ban in ipairs( exsto.BanDB:GetAll() ) do
				if ban.Name == steamid then
					-- We found a name of a player; unban him like this.
					dataUsed = true
					steamid = ban.SteamID
					break
				end
			end
			
			-- Check our match again
			if !string.match( steamid, "STEAM_[0-5]:[0-9]:[0-9]+" ) then
				return { owner, COLOR.NORM, "That is an invalid ", COLOR.NAME, "SteamID!", COLOR.NORM, "A normal SteamID looks like this, ", COLOR.NAME, "STEAM_0:1:123456" }
			end
		end
		
		-- Check to see if this ban actually exists.
		local found = false
		for _, ban in ipairs( exsto.BanDB:GetAll() ) do
			if ban.SteamID == steamid then found = true break end
		end
		
		if !found then
			return { owner, COLOR.NAME, steamid, COLOR.NORM, " is not banned!" }
		end
		
		game.ConsoleCommand( "removeid " .. steamid .. ";writeid\n" ) -- Do this regardless.
		
		local name = "Unknown"
		for _, data in ipairs( exsto.BanDB:GetAll() ) do 
			if data.SteamID == steamid then
				name = data.Name
			end 
		end 
		
		exsto.BanDB:DropRow( steamid )
		self:ResendToAll() 

		return { 
			Activator = owner, 
			Player = steamid .. " (" .. name .. ")",
			Wording = " has unbanned ", 
		} 

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
	 PLUGIN:AddCommand( "lookup", { 
			 Call = PLUGIN.Lookup, 
			 Desc = "Allows users to lookup a player's info.", 
			 Console = { "lookup" }, 
			 ReturnOrder = "FindWith", 
			 Chat = { "!lookup" }, 
			 Args = { FindWith = "STRING" }, 
			 Category = "Administration", 
	 })
	PLUGIN:RequestQuickmenuSlot( "lookup", "Lookup Info" )

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
		str = (w>0 and w.." week(s) " or "")..(d>0 and d.."day(s) " or "")
		
		return string.format( str.."%02i hour(s) %02i minute(s) %02i second(s)", h, m, s )
	end	  
	function PLUGIN:ResendToAll() 
		self.RequestBans( player.GetAll() )
	end 

	function PLUGIN.RequestBans( ply ) 
		for k,v in pairs( exsto.BanDB:GetAll() ) do 
			local sender = exsto.CreateSender( "ExRecBans", ply )
				sender:AddString( v.SteamID )
				sender:AddString( v.Name )
				sender:AddString( v.Reason )
				sender:AddString( v.BannedBy )
				sender:AddShort( v.Length )
				sender:AddLong( v.BannedAt )
				sender:AddString( v.BannerID )
				sender:Send()
		end 
		exsto.CreateSender( "ExSaveBans", ply ):Send()
	end 
	concommand.Add( "_ResendBans", PLUGIN.RequestBans ) 

elseif CLIENT then 

	PLUGIN.Recieved = false

	local function receive( reader )
		if !PLUGIN.Bans then PLUGIN.Bans = {} end
		local steamid = reader:ReadString()
		PLUGIN.Bans[ steamid ] = {
			SteamID = steamid,
			Name = reader:ReadString(),
			Reason = reader:ReadString(),
			BannedBy = reader:ReadString(),
			Length = reader:ReadShort(),
			BannedAt = reader:ReadLong(),
			BannerID = reader:ReadString(),
		}
	end
	exsto.CreateReader( "ExRecBans", receive )
	
	local function save()
		PLUGIN.Recieved = true
		if PLUGIN.Panel then
			PLUGIN.Panel:EndLoad() 
			if PLUGIN.List and PLUGIN.List:IsValid() then
				PLUGIN.List:Update()
			else
				PLUGIN:Build( PLUGIN.Panel )
			end
		end
	end
	exsto.CreateReader( "ExSaveBans", save )
	
	function PLUGIN:ReloadList( panel ) 
		if !self.List then return end 
		if !panel then return end

		panel:PushLoad()
		self.Bans = nil 
		self.Recieved = false
		RunConsoleCommand( "_ResendBans" ) 
	end 

	function PLUGIN:GetSelected( column ) 
		if self.List:GetSelected()[1] then 
			return self.List:GetSelected()[1]:GetValue( column or 1 ) 
		end 
	end 	

	function PLUGIN:Build( panel ) 
		self.List = exsto.CreateListView( 10, 10, panel:GetWide() - 20, panel:GetTall() - 60, panel ) 
		self.List:AddColumn( "Player" ) 
		self.List:AddColumn( "SteamID" ) 
		self.List:AddColumn( "Reason" ) 
		self.List:AddColumn( "Banned By" )
		self.List:AddColumn( "Banner ID" )
		self.List:AddColumn( "Unban Date" ) 

		self.List.Update = function() 
			self.List:Clear() 
			if type( self.Bans ) == "table" then
				for _, data in pairs( self.Bans ) do 
					print( data.BannedAt, data.Length )
					local time = os.date( "%c", data.BannedAt + data.Length*60 )
					if data.Length == 0 then time = "permanent" end 

					self.List:AddLine( data.Name, data.SteamID, data.Reason, data.BannedBy, data.BannerID, time ) 
				end 
			end
		end 
		self.List:Update() 

		self.unbanButton = exsto.CreateButton( ( (panel:GetWide() / 2) - ( 74 / 2 ) ) + 50, panel:GetTall() - 40, 74, 27, "Remove", panel ) 
		self.unbanButton.OnClick = function( button ) 
			local id = self:GetSelected( 2 ) 
			if id then 
				RunConsoleCommand( "exsto", "unban", tostring( id ) ) 
				self:ReloadList( panel ) 
			else
				panel:PushGeneric( "Please select a ban to remove." )
			end
		end 
		self.unbanButton:SetStyle( "positive" ) 

		self.refreshButton = exsto.CreateButton( ( (panel:GetWide() / 2) - ( 74 / 2 ) ) - 50, panel:GetTall() - 40, 74, 27, "Refresh", panel ) 
		self.refreshButton.OnClick = function( button ) 
			self:ReloadList( panel ) 
		end      
	end 

	Menu:CreatePage({ 
		Title = "Ban List", 
		Short = "banlist", 
	},      function( panel )
		if !PLUGIN.Recieved then
			panel:PushLoad()
			RunConsoleCommand( "_ResendBans" ) 
		else
			PLUGIN:Build( panel ) 
		end
		PLUGIN.Panel = panel
	end 
	) 

end 

PLUGIN:Register() 
