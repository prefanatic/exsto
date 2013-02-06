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
//if !datastream then require( "datastream" ) end

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
]] )
end

local function LoadVariables( srvVer )

	exsto = {}
	exsto.DebugEnabled = true
	exsto.StartTime = SysTime()
	
	exsto.VERSION = 100
	exsto._DebugLevel = 3
end

function exstoInclude( fl )
	include( fl )
end
	
function exstoAddCSLuaFile( fl )
	AddCSLuaFile( fl )
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
	
	if SERVER then
		exstoInclude( "exsto/sv_init.lua" )
		exstoAddCSLuaFile( "exsto/cl_init.lua" )
	elseif CLIENT then
		exstoInclude( "exsto/cl_init.lua" )
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

	function onEntCreated( ent )
		if LocalPlayer():IsValid() then
			LocalPlayer():ConCommand( "exsto_cl_load\n" )
			hook.Remove( "OnEntityCreated", "ExSystemLoad" )
		end
	end
	hook.Add( "OnEntityCreated", "ExSystemLoad", onEntCreated )
end