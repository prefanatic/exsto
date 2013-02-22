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

-- Extension for FEL to work with some portions of Exsto.

FEL.ConfigFile = "exsto_mysql_settings.txt";
FEL.TableCache = "exsto_felcache/"

if SERVER then
	
	hook.Add( "ExInitialized", "ExFELIntegration", function()	
		exsto.FELDebug = exsto.CreateVariable( "ExFelDebug", "FEL Debugging", false, "Enables FEL to debug all queries to the console." )
	end )
	
end

hook.Add( "FEL_OnQuery", "ExFELQueryDebug", function( str, threaded )
	if CLIENT then return end
	if exsto and exsto.FELDebug and exsto.FELDebug:GetValue() == true then
		if str != "SELECT 1 + 1" then
			for _, ply in ipairs( player.GetAll() ) do
				if ply:IsSuperAdmin() then
					exsto.Print( exsto_CLIENT, ply, "FEL QUERY: " .. str )
				end
			end
			exsto.Debug( "FEL QUERY --> " .. str, 0 )
		end
	end
end )