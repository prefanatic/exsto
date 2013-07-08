--[[
	Exsto
	Copyright (C) 2013  Prefanatic

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local start = SysTime()

exsto.Debug( "aLoader --> Initializing.", 2 );
exsto.aLoader = {
	Loaded = {};
	Processing = {};
	Errors = {};
};

-- Heres our database.
exsto.Debug( "aLoader --> Constructing exsto_data_ranks", 3 );
exsto.RankDB = FEL.CreateDatabase( "exsto_data_ranks" );
	exsto.RankDB:SetDisplayName( "Ranks" )
	exsto.RankDB:ConstructColumns( {
		Name = "TEXT:not_null"; 				-- Used as a nice display ID.
		Description = "TEXT";   				-- Description, obviously.
		ID = "VARCHAR(100):primary:not_null";	-- Exsto ID.
		Parent = "VARCHAR(100):not_null";		-- Parental rank; used to derive flags.
		FlagsAllow = "TEXT";					-- Flags allowed for this rank.
		FlagsDeny = "TEXT";						-- Flags denied for this rank.
		Color = "TEXT";							-- Color of the rank
		Immunity = "INTEGER";					-- Immunity, we go from 0 as the highest and onward.
	} )
	exsto.RankDB.CacheUpdated = function()
		exsto.aLoader.Initialize()
		exsto.SendRanks( player.GetAll() )
	end
	
-- And our user database.
exsto.Debug( "aLoader --> Constructing exsto_data_users", 3 );
exsto.UserDB = FEL.CreateDatabase( "exsto_data_users" );
	exsto.UserDB:SetDisplayName( "Users" )
	exsto.UserDB:ConstructColumns( {
		SteamID = "VARCHAR(50):primary:not_null";	-- SteamID of the player
		Name = "TEXT:not_null";						-- Display name of the player
		Rank = "VARCHAR(100):not_null";				-- Rank of the player in ExstoID
		FlagsAllow = "TEXT";						-- Flags allowed for the player
		FlagsDeny = "TEXT";							-- Flags denied for the player
		ServerOwner = "BOOLEAN";					-- Declares if the user is the owner.
	} )
	
-- Variables to designate how rank errors should be handled
exsto.aLoader.ErrorHandle = exsto.CreateVariable( "ExRankErrorHandle", 
	"Rank Error Handling", 
	"auto", 
	"Designates how Exsto shall handle errors in ranks.\n - 'auto' : Automatically tries to recover ranks by removing broken data.\n - 'restore' : Restores default ranks temporarily.\n - 'delrestore' : Restores ranks and saves them.  Backups old rank data to .txt"
)
exsto.aLoader.ErrorHandle:SetPossible( "auto", "restore", "delrestore" )
exsto.aLoader.ErrorHandle:SetCategory( "Exsto General" )

-- Hardcoded flags
--exsto.CreateFlag( "quickmenu", "Allows access to the quickmenu." )
--exsto.CreateFlag( "pagelist", "Allows access to the listing of pages in the menu." )
	
--[[ -----------------------------------
	Function: exsto.aLoader.CreateDefaults()
	Description: Pushes the default rank set from sh_tables to FEL to be saved.
	Used: Only when default ranks don't exist.  Check when loading the rank table.
	----------------------------------- ]]
function exsto.aLoader.CreateDefaults()
	exsto.Debug( "aLoader --> Saving Exsto shipped ranks.", 2 )
	for id, data in pairs( exsto.DefaultRanks ) do
		exsto.Debug( "aLoader --> Saving rank: " .. id, 3 )
		exsto.RankDB:AddRow( data )
	end
end

--[[ -----------------------------------
	Function: exsto.aLoader.LoadRanks()
	Description: Loads the rank table into the aLoader.Loaded table to be processed.
	Used: During initialization.  Shouldn't be called after that.
	----------------------------------- ]]
function exsto.aLoader.LoadRanks()
	exsto.Debug( "aLoader --> Loading saved ranks.", 2 )
	exsto.RankDB:GetAll( function( q, d )
		-- Check to see if defaults need to be saved.
		if not d or table.Count( d ) == 0 then exsto.aLoader.CreateDefaults() d = exsto.DefaultRanks end
		
		for _, data in ipairs( d ) do
			exsto.Debug( "aLoader --> Pushing data to load process: " .. data.ID, 3 )
			
			-- Quality check
			local succF, err = pcall( von.deserialize, data.FlagsAllow )
			if not succF then
				exsto.Debug( "aLoader --> Failed to load flags for '" .. data.ID .. "'", 1 )
				exsto.aLoader.Error( data.ID, ALOADER_VON_FAILURE_FLAGS )
			end
			local succC, err = pcall( von.deserialize, data.Color )
			if not succC then
				exsto.Debug( "aLoader --> Failed to load color for '" .. data.ID .. "'", 1 )
				exsto.aLoader.Error( data.ID, ALOADER_VON_FAILURE_COLOR )
			end
			
			exsto.aLoader.Loaded[ data.ID ] = {
				Name = data.Name;
				Description = data.Description;
				ID = data.ID;
				Parent = data.Parent;
				FlagsAllow = succF and von.deserialize( data.FlagsAllow ) or nil;
				Immunity = tonumber( data.Immunity ) or nil;
				Color = succC and von.deserialize( data.Color ) or nil;
			}
		end
		
		exsto.aLoader.Process()
		exsto.aLoader.QualityCheck()
		exsto.SendRanks( player.GetAll() )

		exsto.Debug( "aLoader --> End main core sequence.", 2 )
		
		hook.Call( "ExRanksLoaded" )

	end )
end

--[[ -----------------------------------
	Function: exsto.aLoader.RankProcessed( IDENTIFIER:string )
	Description: Checks if a rank has already been injected into Exsto
	Used: Any time a rank needs to be checked if previously injected.
	----------------------------------- ]]
function exsto.aLoader.RankProcessed( id )
	exsto.Debug( "aLoader --> Checking of rank is loaded: " .. id, 3 )
	return exsto.aLoader.Processing[ id ] or false
end

--[[ -----------------------------------
	Function: exsto.aLoader.GrabLoadInfo( IDENTIFIER:string )
	Description: Returns the load information from an ID
	Used: Any time data is requested.
	----------------------------------- ]]
function exsto.aLoader.GrabLoadInfo( id )
	return exsto.aLoader.Loaded[ id ]
end

--[[ -----------------------------------
	Function: exsto.aLoader.CheckParent( IDENTIFIER_PROCESSING:string, IDENTIFIER_PARENT:string )
	Description: Makes sure a parent can be accessed and loaded safely.
	Used: Any time a parent check is required.  Normally during the segmentation of ranks.
	----------------------------------- ]]
function exsto.aLoader.CheckParent( id, parent )
	exsto.Debug( "aLoader --> Checking the parent: " .. parent .. " from " .. id, 2 )
	local checked, current, tmp = { }, parent, nil
	for I = 1, 10 do
		exsto.Debug( "aLoader --> Down " .. I .. " levels, checking: " .. ( current or "nothing" ), 3 )
		if current == "NONE" then return true end -- End if we don't need a parent.
		if id == current then exsto.aLoader.Error( current, ALOADER_SELF_PARENT ) return false end -- End if we parent off of ourselves.
		if !exsto.aLoader.Loaded[ current ] then exsto.aLoader.Error( id, ALOADER_INVALID_PARENT ) return false end -- End if our parent doesn't exist.
		if table.HasValue( checked, current ) then exsto.aLoader.Error( id, ALOADER_ENDLESS ) return false end -- We've already checked.  This would lead us into an inf.loop.
	
		table.insert( checked, current )
		current = exsto.aLoader.Loaded[ current ].Parent
	end
	exsto.Debug( "aLoader --> Parent check success on: " .. parent, 2 )
	return true
end

--[[ -----------------------------------
	Function: exsto.aLoader.ManageFlagInherit( CURRENT:table, MERGE:table )
	Description: Merges flags from MERGE to CURRENT
	Used: During SegmentRank.  Shouldnt' be called elsewhere.
	----------------------------------- ]]
function exsto.aLoader.ManageFlagInherit( current, merge )
	exsto.Debug( "aLoader --> MergeHandler --> Begin merge.", 3 )
	for key, value in pairs( merge ) do
		exsto.Debug( "aLoader --> MergeHandler --> Checking value: " .. value, 3 )
		if !table.HasValue( current, value ) then
			exsto.Debug( "aLoader --> MergeHandler --> Merging non-existant value: " .. value, 3 )
			table.insert( current, value )
		end
	end
end

--[[ -----------------------------------
	Function: exsto.aLoader.SegmentRank( IDENTIFIER:string, RANK_DATA:table )
	Description: Loads a specific rank.  Handles parenting protection and flag derive
	Used: Any time a rank needs to be loaded.  Originally called from Process()
	----------------------------------- ]]
function exsto.aLoader.SegmentRank( id, data )
	exsto.Debug( "aLoader --> Segmenting rank: " .. id, 2 )
	if exsto.aLoader.RankProcessed( id ) then exsto.Debug( "aLoader --> Rank already processed, skip: " .. id, 2 ) return end
	exsto.aLoader.Processing[ id ] = data; -- Simple thing to do.
	exsto.aLoader.Processing[ id ].Inherit = {}

	exsto.Debug( "aLoader --> Checking if rank has parent: " .. id .. ", " .. ( data.Parent or "none" ), 3 )
	if data.Parent and data.Parent != "NONE" then
		exsto.Debug( "aLoader --> Parent exists, processing and cycling down.", 3 )
		-- First check to see if the parent can be loaded.
		if !exsto.aLoader.CheckParent( id, data.Parent ) then exsto.Debug( "aLoader --> CheckParent returned false, Exsto will not parent this rank.", 2 ) return end
		
		-- Load his parent.  This "SHOULD" send aLoader into a loop all the way down to the last parent to load, then cycle back up.
		exsto.Debug( "aLoader --> Cycling down to segment parent: " .. data.Parent, 3 )
		exsto.aLoader.SegmentRank( data.Parent, exsto.aLoader.GrabLoadInfo( data.Parent ) )
		
		-- Check to see if our flags made it in.
		if not exsto.aLoader.Processing[ data.Parent ].FlagsAllow then exsto.Debug( "aLoader --> Caught invalid flag table.  Removing.", 2 ) return end
		
		exsto.Debug( "aLoader --> Cycling up to merge flag tables from: " .. data.Parent .. " to " .. id, 3 )
		
		exsto.aLoader.ManageFlagInherit( exsto.aLoader.Processing[ id ].Inherit, exsto.aLoader.Processing[ data.Parent ].FlagsAllow )
	end
end

function exsto.aLoader.Error( id, reason )
	exsto.aLoader.Errors[ id ] = exsto.aLoader.Errors[ id ] or {}
	exsto.aLoader.Errors[ id ] = reason 
	
	hook.Call( "ExRankError", nil, id, reason )
end

--[[ -----------------------------------
	Function: exsto.aLoader.Process()
	Description: Processes the ranks in aLoader.Loaded.
	Used: During initialization.  Shouldn't be called after that.
	----------------------------------- ]]
function exsto.aLoader.Process()
	exsto.Debug( "aLoader --> Begin process of rank data.", 2 )
	for id, data in pairs( exsto.aLoader.Loaded ) do
		exsto.aLoader.SegmentRank( id, data )
	end
end

--[[ -----------------------------------
	Function: exsto.aLoader.QualityCheck()
	Description: Finalizes and checks to make sure ranks loaded properly.
	Used: During initialization.  Shouldn't be called after that.
	----------------------------------- ]]
function exsto.aLoader.QualityCheck()
	local mgStyle = exsto.aLoader.ErrorHandle:GetValue()
	
	-- If we're missing any critical elements to our data, replace it with default-standard ones.
	for id, data in pairs( exsto.aLoader.Processing ) do
		if !data.Immunity then exsto.aLoader.Processing[ id ].Immunity = 10 end
	end
	
	if table.Count( exsto.aLoader.Errors ) > 0 then
		exsto.ErrorNoHalt( "aLoader --> Error loading ranks.  Handling." )
		
		-- We ONLY want to run this on startup.
		if !exsto.aLoader.Backup then -- This will tell us if we're starting up.
			if mgStyle == "auto" then -- Try and recover.  Lets look at our errors and see what we can do.
				exsto.Debug( "aLoader --> Automatically trying to handle rank errors.", 1 )
				local rank;
				for id, err in pairs( exsto.aLoader.Errors ) do
					rank = exsto.aLoader.Processing[ id ];
					
					-- Our parent errors.  Just set the actual parent to NONE and try loading again.
					if err == ALOADER_SELF_PARENT or err == ALOADER_INVALID_PARENT or err == ALOADER_ENDLESS then
						exsto.Debug( "aLoader --> Errors found in '" .. id .. "' with parent '" .. rank.Parent .."'.  Solving with derive replacement 'NONE'", 1 )
						exsto.RankDB:AddRow( {
							ID = id;
							Parent = "NONE";
						} )
					elseif err == ALOADER_VON_FAILURE_COLOR then
						exsto.Debug( "aLoader --> Errors found in '" .. id .. "' with color.  Replacing with white.", 1 )
						exsto.RankDB:AddRow( {
							ID = id;
							Color = von.serialize( Color( 255, 255, 255, 255 ) );
						} )
					elseif err == ALOADER_VON_FAILURE_FLAGS then
						exsto.Debug( "aLoader --> Errors found in '" .. id .. "' with flags.  Replacing with empty table.", 1 )
						exsto.RankDB:AddRow( {
							ID = id;
							FlagsAllow = von.serialize( {} );
						} )
					end
				end
				
				-- Throw aLoader back into initialization.
				exsto.Debug( "aLoader --> Throwing aLoader back into process.", 1 )
				exsto.aLoader.Initialize();
				return
			end
		else -- We're reloading.  Just recopy in the old rank database.
			exsto.Debug( "aLoader --> Copying in old rank backup.", 1 )
			exsto.Ranks = table.Copy( exsto.aLoader.Backup );
		end
	else
		exsto.Debug( "aLoader --> Quality check passed.", 1 )
		exsto.Ranks = table.Copy( exsto.aLoader.Processing )
	end

end

--[[ -----------------------------------
	Function: exsto.aLoader.Initialize()
	Description: Winds up aLoader to process and manage ranks.
	Used: Any time required, it starts aLoader.
	----------------------------------- ]]
function exsto.aLoader.Initialize()
	exsto.Debug( "aLoader --> Begin main core init sequence.", 2 )
	
	-- Backup old data if we're reinit.
	if exsto.Ranks and table.Count( exsto.Ranks ) >= 1 then
		exsto.aLoader.Backup = table.Copy( exsto.Ranks )
	end
	
	-- Create our holders
	exsto.Ranks = {}
	exsto.aLoader.Loaded = {}
	exsto.aLoader.Processing = {}
	exsto.aLoader.Errors = {}
	
	-- Inject our srv_owner rank.  Needs to be done before anything is loaded in case of load failure.
	exsto.aLoader.Processing[ "srv_owner" ] = {
		FlagsAllow = {},
		Inherit = {},
		Immunity = -1,
		ID = "srv_owner",
		Color = Color( 60, 200, 124, 200 ),
		Name = "Server Owner",
		Parent = "NONE",
		Description = "Owner of the server.",
	}
	
	exsto.aLoader.LoadRanks() -- Load ranks now needs to throw the rest of us into production, because we load threaded now.
end
exsto.aLoader.Initialize()

--[[ -----------------------------------
	Function: exsto.SetAccess()
	Description: Sets a player's rank.
	Used: Any time required; called normally through commands.
	----------------------------------- ]]
function exsto.SetAccess( ply, user, id )
	local rank = exsto.Ranks[id] -- Check and see if we're working on ID's
	
	if !rank then
		-- Now check if we're matching any name of a rank.
		for _i, data in pairs( exsto.Ranks ) do
			if string.lower( data.Name ) == id then rank = data end
		end
	end
	
	-- If we still don't have a rank.
	if !rank then
		local closeRank = exsto.GetClosestString( id, exsto.Ranks, "ID", ply, "Unknown rank" )
		return
	end
	
	local SelfIm = ply:EntIndex() > 0 and tonumber(exsto.Ranks[ply:GetRank()].Immunity) or -1
	local RankIm  = tonumber(rank.Immunity)
	
	if SelfIm > RankIm then return { ply,COLOR.NORM,"You cannot set yourself a higher rank" } end
	
	user:SetRank( rank.ID )
	
	return { COLOR.NAME, ply:Nick(), COLOR.NORM, " has set ", COLOR.NAME, user:Nick(), COLOR.NORM, "'s rank to ", COLOR.NAME, rank.Name }
	
end
exsto.AddChatCommand( "rank", {
	Call = exsto.SetAccess,
	Desc = "Sets a user access",
	Console = { "rank" },
	Chat = { "!rank" },
	ReturnOrder = "Victim-Rank",
	Args = {Victim = "PLAYER", Rank = "STRING"},
	Optional = { },
	Category = "Administration",
	DisallowOwner = true,
})
exsto.SetQuickmenuSlot( "rank", "Rank", { } )

--[[ -----------------------------------
	Function: exsto.SetAccessID()
	Description: Sets a SteamID's rank.
	Used: Any time required; called normally through commands.
	----------------------------------- ]]
function exsto.SetAccessID( caller, sid, id )
		
	local rank = exsto.Ranks[id]
	if !rank then
		local closeRank = exsto.GetClosestString( id, exsto.Ranks, "ID", caller, "Unknown rank" )
		return
	end
	
	if !string.match( sid, "STEAM_[0-5]:[0-9]:[0-9]+" ) then
		return { owner, COLOR.NAME, "Invalid SteamID.", COLOR.NORM, "A normal SteamID looks like this, ", COLOR.NAME, "STEAM_0:1:123456" }
	end
	
	local ply = exsto.GetPlayerByID( sid )
	if not IsValid( ply ) then
		
		-- Take a look at our user database, see if we can access them.
		local db = exsto.UserDB:ReadAll()
		for _, data in pairs( db ) do
			if data.SteamID == sid then
				
				-- We've found them.  Update their entry and go.
				exsto.UserDB:AddRow( {
					SteamID = sid;
					Rank = rank.ID;
				} )
				
				exsto.Print( exsto_CHAT_ALL, COLOR.NAME, caller:Nick(), COLOR.NORM, " has set ", COLOR.NAME, data.Name .. " (" .. sid .. ")", COLOR.NORM, "'s rank to ", COLOR.NAME, rank.Name )
				return
			end
		end
		
		-- We've made it through the loop and couldn't find anything.  We should insert the ID into our user table and go from there.
		exsto.UserDB:AddRow( {
			SteamID = sid;
			Rank = rank.ID;
			Name = "Unknown";
		} )
		
		exsto.Print( exsto_CHAT_ALL, COLOR.NAME, caller:Nick(), COLOR.NORM, " has set (", COLOR.NAME, sid, COLOR.NORM, ")'s rank to ", COLOR.NAME, rank.Name )
		return
	
	else -- The player is valid, set rank like we would normally.
		return exsto.SetAccess( caller, ply, id )
	end
	
end
exsto.AddChatCommand( "rankid", {
	Call = exsto.SetAccessID,
	Desc = "Sets a user access",
	Console = { "rankid" },
	Chat = { "!rankid" },
	ReturnOrder = "SteamID-Rank",
	Args = {SteamID = "STRING", Rank = "STRING"},
	Optional = { },
	Category = "Administration",
	DisallowOwner = true,
})

--[[ -----------------------------------
	Function: exsto.PrintRank
	Description: Prints a users rank
	----------------------------------- ]]
function exsto.PrintRank( ply, victim )
	local rank = victim:GetNWString( "ExRankHidden" )
	if rank == "" then rank = victim:GetRank() end
	exsto.Print( exsto_CHAT, ply, COLOR.NAME, victim:Name(), COLOR.NORM, " is a ", COLOR.NAME, rank, COLOR.NORM, "!" )
end
exsto.AddChatCommand( "getrank", {
	Call = exsto.PrintRank,
	Desc = "Gets the players rank",
	Console = { "getrank" },
	Chat = { "!getrank" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
	Optional = {Victim = nil},
	Category = "Administration",
})

--[[ -----------------------------------
	Function: exsto.AddUsersOnJoin
	Description: Monitors on join, and prints any relevant information to the chat.
	----------------------------------- ]]
function exsto.AddUsersOnJoin( ply, steamid, uniqueid )
	local rank = ply:GetRank()
	
	if !rank then
		-- Its his first time here!  Welcome him to the beautiful environment of Exsto.
		ply:Print( exsto_CHAT, COLOR.NORM, "Hello!  This server is proudly running ", COLOR.NAME, "Exsto", COLOR.NORM, "!  For more information, visit the !menu" )
	end
	
	-- Warn about development version
	if exsto.VERSION == EX_DEVELOPMENT then
		ply:Print( exsto_CHAT, COLOR.NAME, "Warning! ", COLOR.NORM, "This server is running a developmental build of ", COLOR.NAME, "Exsto", COLOR.NORM, ".  Please be aware that bugs may present themselves." )
	end

	if !game.IsDedicated() then
		if ply:IsListenServerHost() and not rank then
			ply:SetNWString( "rank", "srv_owner" )
		elseif ply:IsListenServerHost() and ply:GetRank() != "srv_owner" then
			-- If hes the host, but has a different rank, we need to give him the option to re-set as superadmin.
			ply:Print( exsto_CHAT, COLOR.NORM, "Exsto seems to have noticed you are the host of this listen server, yet your rank isnt owner!" )
			ply:Print( exsto_CHAT, COLOR.NORM, "If you want to reset your rank to owner, run this chat command. ", COLOR.NAME, "!updateowner" )
		end
	else
		-- We are running a dedicated server, and someone joined.  Lets check to see if there are any admins.
		exsto.AdminCheck( ply )
	end

end
hook.Add( "ExInitSpawn", "exsto_AddUsersOnJoin", exsto.AddUsersOnJoin )

--[[ -----------------------------------
	Function: exsto.UpdateOwnerRank
	Description: Updates a player to owner if enough info is given.
	----------------------------------- ]]
function exsto.UpdateOwnerRank( self )
	if !game.IsDedicated() then
		if self:IsListenServerHost() then
			self:SetRank( "srv_owner" )
			return { self, COLOR.NORM, "You have reset your rank to ", COLOR.NAME, "owner", COLOR.NORM, "!" }
		else
			return { self, COLOR.NORM, "You are not the host of this listen server!" }
		end
	else
		self:Print( exsto_CHAT, COLOR.NORM, "This command can only be run on a ", COLOR.NAME, "dedicated server!" )
		return 
	end
end
exsto.AddChatCommand( "updateownerrank", {
	Call = exsto.UpdateOwnerRank,
	Desc = "Updates listen server host's rank.",
	Console = { "updateowner" },
	Chat = { "!updateowner" },
	Args = {  },
	Category = "Administration",
})

local steamIDCopy = exsto.CreateVariable( "ExCopySteamID",
	"Copy SteamID with !steamid",
	1,
	"Sets if the !steamid command should automatically copy the SteamID to your clipboard, to be pasted elsewhere."
)
steamIDCopy:SetBoolean()
steamIDCopy:SetCategory( "Exsto General" )

function exsto.GetPlayerSteamID( self, ply )
	if not ply then ply = self end
	local sid = ply:SteamID()
	
	if steamIDCopy:GetValue() == 1 then
		ply:SendLua( "SetClipboardText( \"" .. sid .. "\" )" )
	end
	
	return { self, COLOR.NORM, ply:Nick() .. "'s SteamID is '", COLOR.NAME, ply:SteamID(), COLOR.NORM, "'" }
end
exsto.AddChatCommand( "getsteamid", {
	Call = exsto.GetPlayerSteamID,
	Desc = "Prints the SteamID of the selected player.",
	Console = { "steamid" },
	Chat = { "!steamid" },
	Args = { Player = "PLAYER" },
	ReturnOrder = "Player",
	Optional = { Player = nil },
	Category = "Administration",
} )
	

--[[ -----------------------------------
	Function: player:SetRank
	Description: Sets a player's rank.
	----------------------------------- ]]
function exsto.Registry.Player:SetRank( rank, s )
	if self:GetRank() == rank then return end;
	self:SetNetworkedString( "rank", rank )
	if not s then
		exsto.UserDB:AddRow( {
			SteamID = self:SteamID();
			Rank = rank;
			Name = self:Nick();
		} )
	end
	hook.Call( "ExSetRank", nil, self, rank )
end

--[[ -----------------------------------
	Function: player:SetUserGroup
	Description: Sets a player's usergroup.
	----------------------------------- ]]
function exsto.Registry.Player:SetUserGroup( rank )
	self:SetRank( rank )
end

--[[ -----------------------------------
	Function: player:UpdateUserFlags
	Description: Updates a player's user flags
	----------------------------------- ]]
function exsto.Registry.Player:UpdateUserFlags( tbl )
	self.ExUserFlags = tbl
end

--[[ -----------------------------------
	Function: player:HasUserFlag
	Description: Checks to see if the user has a flag in either allow or deny
	----------------------------------- ]]
function exsto.Registry.Player:HasUserFlag( flag, deny )
	local tbl = ( deny and self.ExDeniedUserFlags ) or self.ExUserFlags
	for _, flags in ipairs( tbl ) do
		if flag == flag then return true, _ end
	end
	return false
end

--[[ -----------------------------------
	Function: player:AddUserFlag
	Description: Adds a flag into the user's flag list
	----------------------------------- ]]	
function exsto.Registry.Player:AddUserFlag( flag )
	-- Check to make sure this flag isn't in his denied flags.
	local result, id = self:HasUserFlag( flag, true )
	if result then -- Lets just remove it from denied.
		table.remove( self.ExDeniedUserFlags, id )
	end
	
	table.insert( self.ExUserFlags, flag )
	self:SaveUserFlags()
end

--[[ -----------------------------------
	Function: player:RemoveUserFlag
	Description: Removes a flag from the user's flag list
	----------------------------------- ]]
function exsto.Registry.Player:RemoveUserFlag( flag )
	local result, id = self:HasUserFlag( flag )
	if result then
		table.remove( self.ExUserFlags, id )
	end
	self:SaveUserFlags()
end

--[[ -----------------------------------
	Function: player:DenyUserFlag
	Description: Denys a specific flag from a user
	Intention: Allows users to have "admin" but not be able to ban, for example.
	----------------------------------- ]]
function exsto.Registry.Player:DenyUserFlag( flag )
	-- Check to make sure this flag isn't in his allowed flags.
	local result, id = self:HasUserFlag( flag )
	if result then -- Lets just remove it from allowed.
		table.remove( self.ExUserFlags, id )
	end
	
	table.insert( self.ExDeniedUserFlags, flag )
	self:SaveUserFlags()
end

--[[ -----------------------------------
	Function: player:RemoveDeniedUserFlag
	Description: Removes a flag from the user's denied flag list
	----------------------------------- ]]
function exsto.Registry.Player:RemoveDeniedUserFlag( flag )
	local result, id = self:HasUserFlag( flag, true )
	if result then
		table.remove( self.ExDeniedUserFlags, id )
	end
	self:SaveUserFlags()
end

--[[ -----------------------------------
	Function: player:SaveUserFlags
	Description: Creates a delay when saving flags, to allow multiple flags to be saved before everything else is.
	----------------------------------- ]]
function exsto.Registry.Player:SaveUserFlags()
	-- TODO: Should we delay the saving procedure to reduce lag?  If this is called multiple times...
	exsto.UserDB:AddRow( {
		SteamID = self:SteamID(),
		FlagsAllow = self.ExUserFlags,
		FlagsDeny = self.ExDeniedUserFlags,
	} )
end

--[[ -----------------------------------
	Function: exsto.AnyAdmins
	Description: Checks to see if there are any admin in the data server.
	----------------------------------- ]]
function exsto.AnyAdmins()
	local plys = exsto.UserDB:GetAll()
	if !plys then return false end
	
	for k,v in pairs( plys ) do
		if v.Rank == "srv_owner" then return true end
	end
	
	return false
end

function exsto.AdminCheck( ply )
	exsto.UserDB:GetAll( function( q, d )
		for _, p in ipairs( d ) do
			if p.Rank == "srv_owner" then return true end
		end
	
		ply:Print( exsto_CHAT, COLOR.NORM, "Exsto has detected this is a ", COLOR.NAME, "dedicated server environment", COLOR.NORM, ", and there are no server owners set yet." )
		ply:Print( exsto_CHAT, COLOR.NORM, "If you are the owner of this server, please rcon the following command:" )
		ply:Print( exsto_CHAT, COLOR.NORM, "exsto rank " .. ply:Name() .. " srv_owner" )
	end )
end

--[[ -----------------------------------
	Function: exsto.SendRankData
	Description: Sends the rank table.
	----------------------------------- ]]
function exsto.SendRankData( ply, sid, uid )
	exsto.SendRankErrors( ply )
	exsto.SendFlags( ply )
	exsto.SendRanks( ply )
end
hook.Add( "ExClientLoading", "exsto_SendRankData", exsto.SendRankData )
concommand.Add( "_ResendRanks", exsto.SendRankData )

function exsto.InitializePlayer( ply, sid, uid )
	exsto.Debug( "Initializing player '" .. ply:Nick() .. "' for initspawn.", 1 )
	ply.InitSpawn = true
	
	exsto.UserDB:GetRow( sid, function( q, d )
		if game.SinglePlayer() then
			ply:SetRank( "srv_owner" )
		else
			ply:SetRank( d and d.Rank or "guest", d and d.Rank and true )	
		end
		
		ply:UpdateUserFlags( type( d and d.UserFlags ) == "string" and FEL.NiceDecode( d and d.UserFlags ) or {} )

		hook.Call( "ExPlayerAuthed", nil, ply, sid, uid )
	end )
end
hook.Add( "PlayerAuthed", "ExInitPlayer", exsto.InitializePlayer )

hook.Add( "ExClientLoading", "ExSpawnPlayer", function( p )
	hook.Call( "ExInitSpawn", nil, p, p:SteamID(), p:UniqueID() )
	hook.Call( "exsto_InitSpawn", nil, p, p:SteamID(), p:UniqueID() ) -- Legacy
end )

-- Turns out we don't need this shit below anymore.

--[[ -----------------------------------
	Function: exsto.FixInitSpawn
	Description: Pings the client and waits till hes loaded, then calls the exsto_InitSpawn hook.
	----------------------------------- ]]
exsto.PlayersLoading = {}
local function Hang()

	if !exsto.PlayersLoading then return end
	
	for k, v in ipairs( exsto.PlayersLoading ) do
		if !v.ply or type( v.ply ) == "NULL" or !v.ply:IsValid() then table.remove( exsto.PlayersLoading, k ) return end
		if !v.ply:IsValid() or v.ply:SteamID() == "STEAM_ID_PENDING" or !v.ply:IsPlayer() or !v.ply.InitSpawn then
			-- TODO: Push player out of loop if not authenticated after certain duration

			v.ply.HasID = false
		elseif v.ply.InitSpawn then
			table.remove( exsto.PlayersLoading, k );
			
			v.ply.HasID = true
			
			hook.Call( "ExInitSpawn", nil, v.ply, v.sid, tonumber( v.uid ) )
			hook.Call( "exsto_InitSpawn", nil, v.ply, v.sid, tonumber( v.uid ) ) -- Legacy

		end
	end
	
end
--hook.Add( "Think", "ExPlayingLoadThink", Hang )

local function Hook( ply, sid, uid )
	print( ply:Nick(), sid, uid )
	table.insert( exsto.PlayersLoading, {
		ply = ply,
		sid = sid,
		uid = uid,
	} )
end
--hook.Add( "PlayerAuthed", "FakeInitialSpawn", Hook )

concommand.Add( "_exstoInitSpawn", function( ply, _, args )
	exsto.Print( exsto_CONSOLE_DEBUG, "InitSpawn --> " .. ply:Nick() .. " is ready for initSpawn!" )
	ply.InitSpawn = true
end )

-- Get rid of Garry's auth.  Sorry.
hook.Add( "PlayerInitialSpawn", "PlayerAuthSpawn", function() end )
