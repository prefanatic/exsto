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

FEL.TableCache = "exsto_felcache/"
FEL.BackupDirectory = "exsto_db_backups/";

if SERVER then
	
	hook.Add( "ExVariableInit", "ExFELIntegration", function()	
		exsto.FELDebug = exsto.CreateVariable( "ExFelDebug", "FEL Debugging", 0, "Enables FEL to debug all queries to the console." )
		exsto.FELDebug:SetMinimum( 0 )
		exsto.FELDebug:SetMaximum( 3 )
		exsto.FELDebug:SetCategory( "Debug" )
	end )
	
end

hook.Add( "ExPrintingInit", "ExFELIntegration", function()
	function FEL.Print( msg )
		exsto.Print( exsto_CONSOLE, msg )
	end

	function FEL.Debug( msg, level )
		if exsto.FELDebug:GetValue() >= level then
			exsto.Debug( msg, 0 )
		end
	end
end )

hook.Add( "FEL_OnQuery", "ExFELQueryDebug", function( str, threaded )
	if CLIENT then return end
	if exsto and exsto.FELDebug and exsto.FELDebug:GetValue() == true then
		if str != "SELECT 1 + 1" then
			for _, ply in ipairs( player.GetAll() ) do
				if ply:IsSuperAdmin() then
					--exsto.Print( exsto_CLIENT, ply, "FEL QUERY: " .. str )
				end
			end
			--exsto.Debug( "FEL QUERY --> " .. str, 0 )
		end
	end
end )