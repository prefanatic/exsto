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
	
	-- Load our derma controls
	include( "exsto/menu/controls/exbutton.lua" )
	 
	include( "exsto/menu/cl_derma.lua" )
	include( "exsto/menu/cl_anim.lua" )
	include( "exsto/sh_tables.lua" )
	include( "exsto/sh_umsg_core.lua" )
	include( "exsto/sh_umsg.lua" )
	include( "exsto/sh_print.lua" )
	include( "exsto/fel.lua" )
	include( "exsto/menu/cl_menu_skin_main.lua" )
	include( "exsto/menu/cl_menu_skin_quick.lua" )
	include( "exsto/menu/cl_menu.lua" )
	include( "exsto/menu/cl_page.lua" )
	include( "exsto/menu/cl_quickmenu.lua" )
	include( "exsto/cl_menu.lua" )
	include( "exsto/sh_access.lua" )
	include( "exsto/sh_plugins.lua" )
	--include( "exsto/sh_cloud.lua" )
	
	-- Init clientside items.
	exsto.LoadPlugins()
	exsto.InitPlugins( launchInit )
	
	local seconds = SysTime() - exsto.StartTime
	MsgC( Color( 146, 232, 136, 255 ), "Exsto load finished.\n"	)