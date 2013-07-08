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

if !von then require( "von" ) end

AddCSLuaFile( "autorun/exsto_init.lua" )

local function PrintLoading( srvVer )
	MsgC( Color( 146, 232, 136, 255 ),[[
 _______  __   __  _______  _______  _______ 
|       ||  |_|  ||       ||       ||       |
|    ___||       ||  _____||_     _||   _   |
|   |___ |       || |_____   |   |  |  | |  |
|    ___| |     | |_____  |  |   |  |  |_|  |
|   |___ |   _   | _____| |  |   |  |       |
|_______||__| |__||_______|  |___|  |_______|
  Coded by Prefanatic.  Designed by Revanne
  Version - ]] .. tostring( exsto.VERSION ) .. [[
  
]] )
end

local function LoadVariables( srvVer )

	exsto = {}
	exsto.DebugEnabled = true
	exsto.StartTime = SysTime()
	exsto.Debug = function() end -- To prevent nil functions if something tries debugging before the print system handles it.
	
	exsto.VERSION = file.Read( "data/exsto/version.txt", "GAME" ) or "unknown"
end

-- Helpers
function exstoShared( fl )
	exstoServer( fl )
	exstoClient( fl )
end

function exstoServer( fl )
	if not SERVER then return end
	include( "exsto/" .. fl )
end

function exstoClient( fl )
	if SERVER then
		AddCSLuaFile( "exsto/" .. fl )
	elseif CLIENT then
		include( "exsto/" .. fl )
	end
end

function exstoServerFolder( loc )
	local fs = file.Find( "exsto/" .. loc .. "/*.lua", "LUA" )
	for _, fl in ipairs( fs ) do
		exstoServer( loc .. "/" .. fl )
	end
end

function exstoClientFolder( loc )
	local fs = file.Find( "exsto/" .. loc .. "/*.lua", "LUA" )
	for _, fl in ipairs( fs ) do
		exstoClient( loc .. "/" .. fl )
	end
end

function exstoResources()
	--[[local fs = file.Find( "materials/exsto/*", "GAME" )
	for _, fl in ipairs( fs ) do
		resource.AddFile( "materials/exsto/" .. fl )
	end]]
	local fs = file.Find( "resource/fonts/*.ttf", "GAME" )
	for _, fl in ipairs( fs ) do
		resource.AddFile( "resource/fonts/" .. fl )
	end
end

function exstoModule( mod )
	include( "includes/modules/" .. mod )
	if SERVER then AddCSLuaFile( "includes/modules/" .. mod ) end
end

function exstoInit( srvVer )
	
	if exsto then
		if exsto.Print then
			exsto.Print( exsto_CHAT_ALL, COLOR.EXSTO, "Exsto", COLOR.NORM, " is reloading the core!" )
		end
		if exsto.Plugins and exsto.RemoveChatCommand then
			exsto.UnloadAllPlugins()
		end
	end			
	
	LoadVariables( srvVer )
	PrintLoading( srvVer )
	
	-- Create our data directory.
	file.CreateDir( "exsto", "DATA" )
	file.CreateDir( "exsto/temporary", "DATA" )
	
	if SERVER then
		exstoServer( "sv_init.lua" )
		exstoClient( "cl_init.lua" )
	elseif CLIENT then
		exstoClient( "cl_init.lua" )
	end
end

exsto_HOOKCALL = exsto_HOOKCALL or hook.Call
hook.Call = function( name, gm, ... )
	if !exsto or !exsto.Plugins or !exsto.HookCall then
		return exsto_HOOKCALL( name, gm, ... )
	end
	
	return exsto.HookCall( name, gm, ... )
end

if SERVER then
	exstoInit()
	
	concommand.Add( "exsto_cl_load", function( ply, _, args )
		umsg.Start( "clexsto_load", ply )
			umsg.Short( exsto.VERSION )
		umsg.End()
	end )
	
	concommand.Add( "_ExRestartInitSpawn", function( ply, _, args )
		hook.Call( "ExInitSpawn", nil, ply, ply:SteamID(), ply:UniqueID() )
		hook.Call( "exsto_InitSpawn", nil, ply, ply:SteamID(), ply:UniqueID() )
	end )
	
elseif CLIENT then

	local function init( UM )
		exstoInit( UM:ReadShort() )
		hook.Call( "ExInitialized" )
	end
	usermessage.Hook( "clexsto_load", init )

	local function onEntCreated( ent )
		if LocalPlayer():IsValid() then
			LocalPlayer():ConCommand( "exsto_cl_load\n" )
			hook.Remove( "OnEntityCreated", "ExSystemLoad" )
		end
	end
	hook.Add( "OnEntityCreated", "ExSystemLoad", onEntCreated )
end