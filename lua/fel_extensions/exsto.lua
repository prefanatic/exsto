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
		exsto.FELDebug = exsto.CreateVariable( "ExFelDebug", "FEL Debugging", 0, "Sets the level of debug FEL will print.  0 being nothing, 3 being every debug message." )
			exsto.FELDebug:SetMinimum( 0 )
			exsto.FELDebug:SetMaximum( 3 )
			exsto.FELDebug:SetCategory( "Debug" )
			exsto.FELDebug:SetUnit( "Level" )
			
		-- MySQL!!!!
		exsto.MySQLUsername = exsto.CreateVariable( "ExMySQLUser", "Username", FEL.Config.mysql_user, "Username login for the MySQL server." )
			exsto.MySQLUsername:SetCategory( "MySQL" )
			exsto.MySQLUsername:SetCallback( function( old, new )
				FEL.SetMySQLInformation( new )
			end )
			
		exsto.MySQLPassword = exsto.CreateVariable( "ExMySQLPass", "Password", FEL.Config.mysql_pass, "Password for the MySQL server.  This will always reset to '******' after entry, for security reasons.", { FCVAR_PROTECTED } )
			exsto.MySQLPassword:SetCategory( "MySQL" )
			exsto.MySQLPassword:SetProtected()
			exsto.MySQLPassword:SetCallback( function( old, new )
				FEL.SetMySQLInformation( nil, new )
			end )
			
		exsto.MySQLDatabase = exsto.CreateVariable( "ExMySQLDB", "Database", FEL.Config.mysql_database, "Database for the server to use when saving." )
			exsto.MySQLDatabase:SetCategory( "MySQL" )
			exsto.MySQLDatabase:SetCallback( function( old, new )
				FEL.SetMySQLInformation( nil, nil, new )
			end )
			
		exsto.MySQLHost = exsto.CreateVariable( "ExMySQLHost", "Host", FEL.Config.mysql_host, "The IP address of the MySQL server." )
			exsto.MySQLHost:SetCategory( "MySQL" )
			exsto.MySQLHost:SetCallback( function( old, new ) 
				FEL.SetMySQLInformation( nil, nil, nil, new )
			end )
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