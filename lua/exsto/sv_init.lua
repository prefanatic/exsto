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
	resource.AddFile( "materials/gwenskin/exsto_quick.png" )
	resource.AddFile( "materials/gwenskin/exsto_main.png")
	exstoResources()
	
	-- Includes!
	exstoShared( "fel.lua" ) -- The main data-saving backend.  Has no ties with Exsto.  Can be loaded first!
	
	exstoShared( "sh_enums.lua" )
	exstoShared( "sh_tables.lua" )
	exstoShared( "sh_umsg_core.lua" )
	exstoShared( "sh_umsg.lua" )
	exstoShared( "sh_print.lua" )
	exstoShared( "sh_variables.lua" )
	exstoServer( "sv_commands.lua" )
	exstoShared( "sh_access.lua" )
	exstoServer( "sv_access.lua" )
	exstoShared( "sh_plugin_metatable.lua" )
	exstoShared( "sh_plugins.lua" )
	exstoShared( "sh_cloud.lua" )
	
	-- Clientside things we haven't sent yet.
		-- Derma Controls!
	exstoClientFolder( "menu/controls" )
	
		-- Modules
	AddCSLuaFile( "includes/modules/von.lua" )
	exstoClient( "fel.lua" )
	
		-- Menu
	exstoClient( "menu/cl_derma.lua" )
	exstoClient( "menu/cl_quickmenu.lua" )
	exstoClient( "menu/cl_pagelist.lua" )
	exstoClient( "menu/cl_anim.lua" )
	exstoClient( "menu/cl_menu_skin_main.lua" )
	exstoClient( "menu/cl_menu_skin_quick.lua" )
	exstoClient( "menu/cl_page.lua" )
	exstoClient( "menu/cl_menu.lua" )
	
		-- Misc
	exstoClient( "cl_menu.lua" )

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

timer.Create( "Exsto_TagCheck", 1, 0, function()
	if not GetConVar( "sv_tags" ) then CreateConVar( "sv_tags", "" ) end -- Why do we have to do this now?
	if !string.find( GetConVar( "sv_tags" ):GetString(), "Exsto" ) then
		RunConsoleCommand( "sv_tags", GetConVar( "sv_tags" ):GetString() .. ",Exsto" )
	end
end )

-- Init some items.
	exsto.LoadPlugins()
	exsto.InitPlugins()

	exsto.LoadFlags()
	--exsto.CreateFlagIndex()
	
	-- After everything is done; update the owner with his flags :)
	--[[if exsto.Ranks[ "srv_owner" ] then
		exsto.Ranks[ "srv_owner" ].AllFlags = exsto.FlagIndex
	end]]
	
	local seconds = SysTime() - exsto.StartTime
	MsgC( Color( 146, 232, 136, 255 ), "Exsto load finished.\n"	)
	hook.Call( "ExInitialized" )