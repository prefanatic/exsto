 if CLIENT then
	-- exsto_InitSpawn client call.  Instead of assuming when the client is active, we can use this to call the hook.  Allows for awesomeness.
	hook.Add( "ExInitialized", "exsto_InitSpawnClient", function()
		RunConsoleCommand( "_exstoInitSpawn" )
	end )
end

--[[ -----------------------------------
	Function: exsto.GetInheritedFlags
	Description: Returns the inherited flags of a rank.
	----------------------------------- ]]
function exsto.GetInheritedFlags( id )
	local rank = exsto.Ranks[ id ]
	local tbl = table.Copy( rank.Inherit ) or {}
	
	if rank.Parent != "NONE" then
		table.Add( tbl, exsto.GetInheritedFlags( rank.Parent ) )
	end
	
	return tbl
end

--[[ -----------------------------------
	Function: exsto.GetRankFlags
	Description: Returns all the flags of a rank incl. inherited
	----------------------------------- ]]
function exsto.GetRankFlags( id )
	local rank = exsto.Ranks[ id ]
	local tbl = table.Copy( rank.FlagsAllow )
	
	table.Add( tbl, exsto.GetInheritedFlags( id ) )
	return tbl
end

--[[ -----------------------------------
	Function: exsto.GetRankData
	Description: Returns the rank information based on short or name.
	----------------------------------- ]]
function exsto.GetRankData( rank )
	if !exsto.Ranks then return false end -- Still loading ranks.
	for k,v in pairs( exsto.Ranks ) do
		if v.ID == rank or v.Name == rank then return v end
	end
	return nil
end

--[[ -----------------------------------
	Function: exsto.GetRankColor
	Description: Returns the rank color, or white if there is none.
	----------------------------------- ]]
function exsto.GetRankColor( rank )
	for k,v in pairs( exsto.Ranks ) do
		if v.ID == rank or v.Name == rank then return v.Color end
	end
	return Color( 255, 255, 255, 255 )	
end

--[[ -----------------------------------
	Function: exsto.RankExists
	Description: Returns true if a rank exists
	----------------------------------- ]]
function exsto.RankExists( rank )
	if !exsto.Ranks then return false end
	if exsto.Ranks[rank] then return true end
	return false
end

-- TODO: ADD SUPPORT FOR USER FLAGS AND DENIED RANK FLAGS
--[[ -----------------------------------
	Function: player:IsAllowed
	Description: Checks to see if a player has a flag, and is immune
	----------------------------------- ]]
function exsto.Registry.Player:IsAllowed( flag, victim )
	if self:EntIndex() == 0 then return true end -- If we are console :3
	if self:GetRank() == "srv_owner" then return true end
	if flag == "updateownerrank" then return true end -- Hardcode to prevent lockouts.

	local rank = exsto.GetRankData( self:GetRank() )
	
	if !rank then return false end
	
	if type( victim ) == "Player" then
	
		local victimRank = exsto.GetRankData( victim:GetRank() )
		if !rank.Immunity or !victimRank.Immunity then -- Just ignore it if they don't exist, we don't want to break Exsto.
			if table.HasValue( exsto.GetRankFlags( self:GetRank() ), flag ) then return true end
		elseif tonumber( rank.Immunity ) <= tonumber( victimRank.Immunity ) then
			if table.HasValue( exsto.GetRankFlags( self:GetRank() ), flag ) then return true end
		else
			return false, "immunity"
		end
	else
		if table.HasValue( exsto.GetRankFlags( self:GetRank() ), flag ) then return true end
	end
	
	return false
end

-- ULX Compat
if !ulx then
	function exsto.Registry.Player:query( flag ) return self:IsAllowed( flag ) end
end

function exsto.Registry.Player:HasAccessOver( ply )
	if self:EntIndex() == 0 then return true end -- If we are console :3
	if self:GetRank() == "srv_owner" then return true end
	
	local rData = exsto.GetRankData( self:GetRank() )
	local pData = exsto.GetRankData( ply:GetRank() )
	
	if rData and pData then
		if tonumber( rData.Immunity ) <= tonumber( pData.Immunity ) then return true end
	end
	return false
end

--[[ -----------------------------------
	Function: player:GetRank
	Description: Returns the rank of a player.
	----------------------------------- ]]
function exsto.Registry.Player:GetRank()
	local rank = self:GetNetworkedString( "rank" )
	
	if rank == "" then return "guest" end
	if !rank then return "guest" end
	if !exsto.RankExists( rank ) then return "guest" end
	
	return rank
end

--[[ -----------------------------------
	Function: player:GetRankColor
	Description: Returns the rank color of a player.
	----------------------------------- ]]
function exsto.Registry.Player:GetRankColor()
	return exsto.Ranks[ self:GetRank() ] and exsto.Ranks[ self:GetRank() ].Color or nil
end

--[[ -----------------------------------
	Function: player:IsAdmin
	Description: Returns true if the player is an admin
	----------------------------------- ]]
function exsto.Registry.Player:IsAdmin()
	if self:EntIndex() == 0 then return true end -- If we are console :3
	if self:IsAllowed( "isadmin" ) then return true end
	if self:IsSuperAdmin() then return true end
	return false
end

--[[ -----------------------------------
	Function: player:IsSuperAdmin
	Description: Returns true if the player is a superadmin
	----------------------------------- ]]
function exsto.Registry.Player:IsSuperAdmin()
	if self:EntIndex() == 0 then return true end -- If we are console :3
	if self:IsAllowed( "issuperadmin" ) then return true end
	return false
end

--[[ -----------------------------------
	Function: player:IsUserGroup
	Description: Checks if a player is a rank.
	----------------------------------- ]]
function exsto.Registry.Player:IsUserGroup( id )	
	return self:GetRank() == id
end

--[[ -----------------------------------
	Function: player:GetUserGroup
	Description: ULX Override: for compat. reasons.
	----------------------------------- ]]
function exsto.Registry.Player:GetUserGroup() return self:GetRank() end

--[[ -----------------------------------
	Function: player:CheckGroup
	Description: ULX Override: for compat. reasons.
	----------------------------------- ]]
function exsto.Registry.Player:CheckGroup( id ) return self:HasUserGroup( id ) end

--[[ -----------------------------------
	Function: player:HasUserGroup
	Description: Checks if a player is a rank.
	----------------------------------- ]]
function exsto.Registry.Player:HasUserGroup( id )	
	if self:GetRank() == id then return true end
	return exsto.aLoader.CheckParent(self:GetRank(), id)
end