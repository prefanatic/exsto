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
	Category:  Script Loading
     ----------------------------------- ]]
	
		-- Modules
	exstoClient( "shared/fel.lua" )

		-- Load our derma controls
	exstoClientFolder( "menu/controls" )

		-- Menu
	exstoClient( "menu/cl_skin.lua" )
	exstoClient( "menu/cl_derma.lua" )
	exstoClient( "menu/cl_anim.lua" )
	exstoClient( "menu/cl_menu.lua" )
	exstoClient( "menu/cl_page.lua" )
	exstoClient( "menu/cl_quickmenu.lua" )
	exstoClient( "menu/cl_pagelist.lua" )

		-- Core
	exstoClient( "shared/sh_enums.lua" )

	exstoClient( "shared/sh_tables.lua" )
	exstoClient( "shared/sh_net_metatable.lua" )
	exstoClient( "shared/sh_net.lua" )
	exstoClient( "shared/sh_print.lua" )
	exstoClient( "shared/sh_variables.lua" )

	exstoClient( "shared/sh_groups.lua" )
	exstoClient( "shared/sh_plugin_metatable.lua" )
	exstoClient( "shared/sh_plugins.lua" )

	-- I don't know why or how, but sometimes LocalPlayer is completely valid BEFORE clientside actually finishes a load....
	-- SO!  Lets check.  If we're good, we good.  If not, lets make sure we GET good.
	if LocalPlayer() and IsValid( LocalPlayer() ) then
		hook.Call( "ExClientLoading" )
		exsto.CreateSender( "ExClientLoad" ):Send()
	else
	
		hook.Add( "OnEntityCreated", "ExPlayerCheck", function( ent )
			if ent == LocalPlayer() and IsValid( ent ) then
				hook.Call( "ExClientLoading" )
				exsto.CreateSender( "ExClientLoad" ):Send()
				hook.Remove( "OnEntityCreated", "ExPlayerCheck" )
			end
		end )
	end
	
	hook.Add( "ExReceivedPlugSettings", "ExInitCLPlugs", function()
		if #exsto.Plugins == 0 then
			exsto.LoadPlugins()
			exsto.InitPlugins()
			
			-- Legacy
			hook.Call( "ExPluginsReady" )
			exsto.CreateSender( "ExClientReady" ):Send()
		else
			-- We just want to poll a reload of plugins if one changed or not.
			for _, plug in ipairs( exsto.Plugins ) do
				plug:CheckStatus()
			end
		end
	end )
	
	local seconds = SysTime() - exsto.StartTime
	MsgC( Color( 146, 232, 136, 255 ), "Exsto load finished.  Waiting for server to initiate plugin load.\n"	)