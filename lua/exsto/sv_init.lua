--[[
	Exsto
	Copyright (C) 2010  Prefanatic

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

--[[ -----------------------------------
	Category:  Script Loading/Resources
    ----------------------------------- ]]
	resource.AddFile( "materials/gwenskin/exsto_main.png")
	exstoResources()
	
	-- Includes!
	exstoShared( "shared/fel.lua" ) -- The main data-saving backend.  Has no ties with Exsto.  Can be loaded first!
	
	exstoShared( "shared/sh_enums.lua" )
	exstoShared( "shared/sh_tables.lua" )
	exstoShared( "shared/sh_net_metatable.lua" )
	exstoShared( "shared/sh_net.lua" )
	exstoShared( "shared/sh_print.lua" )
	exstoShared( "shared/sh_variables.lua" )
	exstoServer( "server/sv_commands.lua" )
	exstoShared( "shared/sh_groups.lua" )
	exstoServer( "server/sv_groups.lua" )
	exstoShared( "shared/sh_plugin_metatable.lua" )
	exstoShared( "shared/sh_plugins.lua" )
	
	-- Clientside things we haven't sent yet.
		-- Derma Controls!
	exstoClientFolder( "menu/controls" )
	
		-- Modules
	AddCSLuaFile( "includes/modules/von.lua" )
	AddCSLuaFile( "includes/modules/json.lua" )
	
		-- Menu
	exstoClient( "menu/cl_derma.lua" )
	exstoClient( "menu/cl_quickmenu.lua" )
	exstoClient( "menu/cl_pagelist.lua" )
	exstoClient( "menu/cl_anim.lua" )
	exstoClient( "menu/cl_skin.lua" )
	exstoClient( "menu/cl_page.lua" )
	exstoClient( "menu/cl_menu.lua" )

--[[ -----------------------------------
	Category:  Player Utils
     ----------------------------------- ]]
local nick = exsto.Registry.Player.Nick

function exsto.Registry.Player:IsConsole() if !self:IsValid() then return false end end 
function exsto.Registry.Player:Nick() if !self:IsValid() then return "UNKNOWN" else return nick( self ) end end
	exsto.Registry.Player.Name = exsto.Registry.Player.Nick

--[[ -----------------------------------
	Category:  Console Utils
     ----------------------------------- ]]
function exsto.Registry.Entity:Name() if !self:IsValid() then return "Console" end end
function exsto.Registry.Entity:Nick() if !self:IsValid() then return "Console" end end
function exsto.Registry.Entity:SteamID() if !self:IsValid() then return "Console" end end
function exsto.Registry.Entity:IsAllowed() if !self:IsValid() then return true end end
function exsto.Registry.Entity:IsSuperAdmin() if !self:IsValid() then return true end end
function exsto.Registry.Entity:IsAdmin() if !self:IsValid() then return true end end
function exsto.Registry.Entity:IsConsole() if !self:IsValid() then return true end end
function exsto.Registry.Entity:IsPlayer() if !self:IsValid() then return false end end

--[[ -----------------------------------
	Category:  Player Extras
     ----------------------------------- ]]
function exsto.MenuCall( id, func )
	concommand.Add( id, function( ply, command, args )
		if tonumber( ply.MenuAuthKey ) != tonumber( args[1] ) then return end
		table.remove( args, 1 )
		
		func( ply, command, args )
	end )
end

function exsto.GetMenuPlayers()
	return exsto.MenuPlayers or {}
end

function exsto.AddMenuPlayer( reader )
	if not exsto.MenuPlayers then exsto.MenuPlayers = {} end
	local ply = reader:ReadSender()
	
	exsto.Debug( "Player '" .. ply:Nick() .. "' is active in the menu.", 2 )
	table.insert( exsto.MenuPlayers, ply )
end
exsto.CreateReader( "ExMenuUser", exsto.AddMenuPlayer )

function exsto.RemoveMenuPlayer( reader )
	if not exsto.MenuPlayers then exsto.MenuPlayers = {} return end
	local ply = reader:ReadSender()
	
	exsto.Debug( "Player '" .. ply:Nick() .. "' has left the menu.", 2 )
	for _, p in ipairs( exsto.MenuPlayers ) do
		if IsValid( p ) and ( ply:SteamID() == p:SteamID() ) then table.remove( exsto.MenuPlayers, _ ) end
	end
end
exsto.CreateReader( "ExMenuUserLeft", exsto.RemoveMenuPlayer )

function exsto.TableHasMemberValue( tbl, member, value )
	for k, v in pairs( tbl ) do
		if v[ member ] == value then return k, v end
	end
	return false
end

function exsto.BuildPlayerNicks()
	local tbl = {}
	
	for k,v in ipairs( player.GetAll() ) do
		table.insert( tbl, v:Nick() )
	end
	return tbl
end

function exsto.FindPlayer( ply )
	return exsto.FindPlayers( ply )[1] or nil
end

function exsto.FindPlayers( search, ply )
	local players = {}
	local inverse = 0
	
	if search:sub(1,1) == "!" then
		inverse = 1
		search = search:Replace("!","")
	end
	
	for _, str in ipairs(string.Explode(",", search)) do
		local str = string.Trim(str) PrintTable(players)
		local tempPlayers = {}
	
		-- The player themself
		if str == "me" then
			table.insert(tempPlayers, _, ply)
		
		-- Rank styles
		elseif str:sub( 1, 1 ) == "%" then
			str = str:Replace("%",""):lower()
			for _, ply in ipairs( player.GetAll() ) do
				if ply:GetRank() == str then table.insert(tempPlayers, _, ply) end
			end
		
		-- WildCard
		elseif str == "*" then
			tempPlayers = player.GetAll()
		
		-- Specific matching
		else
			for _, ply in ipairs( player.GetAll() ) do
				if ply:Nick():lower():find( str:lower(), 1, true ) then table.insert(tempPlayers, _, ply) end
			end
		end
	
		table.Merge(players, tempPlayers)
		players = table.ClearKeys(players, false)
	end
	
	if inverse == 1 then
		allPlayers = player.GetAll()
		newPlayers = {}
		for _,ply in pairs(allPlayers) do
			if !table.HasValue(players,ply) then
				table.insert(newPlayers,ply)
			end
		end
		players = newPlayers
	end
	
	return players
end

function exsto.GetPlayerByID( id )
	for k,v in ipairs( player.GetAll() ) do
		if v:SteamID() == id then return v end
	end
	return nil
end

function exsto.dbGetPlayerByID( id )
	if string.match( id, "STEAM_[0-5]:[0-9]:[0-9]+" ) then
		id = string.upper(id)
		local users = exsto.UserDB:GetAll()
		for _, user in ipairs(users) do
			if user.SteamID == id then 
				return user
			end
		end
	end
	return nil
end

local succ, err = pcall( require, "json" );
if !succ then
	exsto.Debug( "Failed to load json.  Oh well.  No ping!", 1 )
	return
end

timer.Create( "ExPing", 60, 0, function()
	if !json then return end

	-- Ping up to our server that we've init.
	local hostname = GetConVar( "hostname" ):GetString()

	-- Fetch the IP.
	http.Fetch( "http://api.hostip.info/get_json.php", function( contents )
		exsto.Debug( "Retreived host info.  Decoding.", 2 )
		
		local decode = json.decode( contents )
		local ip = decode.ip
		
		if contents and decode and ip then
			-- lol.
			http.Fetch( "http://www.exstomod.co.uk/ping.php?p=1&h=" .. hostname .. "&ip=" .. ip, function( contents )
				if contents:find( "Checking" ) then
					exsto.Debug( "Server ping success!  Updated Hostname = " .. hostname .. ", IP = " .. ip .. ", LastSeen = " .. os.time(), 1 )
				else
					exsto.Debug( "Server ping failure!  Callback: " .. contents, 1 )
				end
			end )
		else
			exsto.Debug( "Server ping failure!  Callback: " .. contents, 1 )
		end
	end )			

end )	

-- Init some items.
	exsto.LoadPlugins()
	exsto.InitPlugins()

	exsto.LoadFlags()
	MsgC( Color( 146, 232, 136, 255 ), "Exsto load finished.\n"	)
	hook.Call( "ExInitialized" )