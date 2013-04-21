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

exsto.Cloud = {
	Config = {
		URL = "http://cloud.exstomod.com/";
		Download = "plugin/%s/download";
		Info = "plugin/%s/info";
		PluginDir = "plugins/";
		List = "category/json";
	};
	PluginObjects = {};
}

exsto.CloudDB = FEL.CreateDatabase( "exsto_cloud_db", true )
	exsto.CloudDB:SetDisplayName( "Cloud" )
	exsto.CloudDB:ConstructColumns( {
		Name = "TEXT:not_null";
		Author = "TEXT:not_null";
		Identify = "SMALLINT(11):primary:not_null";
		Version = "INTEGER:not_null";
		Type = "TEXT:not_null";
		Description = "TEXT";
		Downloads = "SMALLINT(11)";
	} )
	
--[[ -----------------------------------
	Category: List Control
	----------------------------------- ]]	
	
local function CLOUD_ListCallback( contents, size )
	if contents == "" or !contents or size <= 0 then
		exsto.ErrorNoHalt( "CLOUD --> Error retreiving JSON server data." )
		return
	end
	
	exsto.Cloud.ServerData = {}
	
	local data = json.decode( contents )
	for id, data in pairs( data ) do
		exsto.Cloud.ServerData[ tonumber( id ) ] = { 
			Name = data.name;
			Author = data.user;
			Downloads = data.downloads;
			Description = data.desc;
			Version = data.version;
			Type = data.type;
			Verified = data.verified;
			Identify = tonumber( id );
		}
	end
	exsto.Print( exsto_CONSOLE, "CLOUD --> JSON server data retreived!" )
	
	hook.Call( "ExCloudJSONReceived", nil )
end

function exsto.Cloud.GrabPluginList()
	//if !json then require( "json" ) end
	
	http.Get( exsto.Cloud.Config.URL .. exsto.Cloud.Config.List, "", CLOUD_ListCallback )
end

--[[ -----------------------------------
	Category: Plugin Fetching
	----------------------------------- ]]
	
exsto.Cloud.DownMan = {}

local function CLOUD_InfoCallback( args, contents, size )
	if contents == "" or !contents or size <= 0 then
		if type( exsto.Cloud.DownMan[ tonumber( args[1] ) ].Caller ) == "Player" then
			exsto.Cloud.DownMan[ tonumber( args[1] ) ].Caller:Print( exsto_CHAT, COLOR.NAME, "Unable", COLOR.NORM, " to download plugin ID ", COLOR.NAME, args[1], COLOR.NORM, "!" )
		else
			exsto.ErrorNoHalt( "CLOUD --> Error retreiving plugin information on ID '" .. args[1] .. "'" )
		end
		return
	end
	
	local split = string.Explode( ";", contents )
	if type( args[2] ) == "function" then -- Be safe.
	
		for _, slice in ipairs( split ) do
			split[ _ ] = slice:gsub( "\n", "" )
		end
		
		args[2]( {
			Name = split[3];
			Author = split[2];
			Version = tonumber( split[4] );
			ID = tonumber( args[1] );
			Type = split[5];
			Downloads = tonumber( split[6] );
		} )
		
	end
end

function exsto.Cloud.GetPluginInfo( id, callback )
	http.Get( exsto.Cloud.Config.URL .. string.format( exsto.Cloud.Config.Info, tostring( id ) ), "", CLOUD_InfoCallback, id, callback )
end

local function CLOUD_DownloadCallback( args, contents, size )
	if contents == "" or !contents or size <= 0 then
		exsto.Error( "CLOUD --> Error retreiving plugin code on ID '" .. args[1] .. "'" )
	end
	
	if type( args[2] ) == "function" then
		args[2]( contents, args[1] )
	end
end

function exsto.Cloud.GetPluginCode( id, callback )
	http.Get( exsto.Cloud.Config.URL .. string.format( exsto.Cloud.Config.Download, tostring( id ) ), "", CLOUD_DownloadCallback, id, callback )
end

local function CLOUD_FinalStageDownload( code, id )
	exsto.Cloud.DownMan[ id ].Code = code
	
	exsto.Cloud.FinalizeDownload( id )
end	

local function CLOUD_SecondStageDownload( data )
	exsto.Print( exsto_CONSOLE, "CLOUD --> Downloading plugin '" .. data.Name .. "' by " .. data.Author .. "!" )
	
	exsto.Cloud.DownMan[ data.ID ].Data = data
	exsto.Cloud.GetPluginCode( data.ID, CLOUD_FinalStageDownload )
end	

function exsto.Cloud.DownloadPlugin( id, ply, update )
	id = tonumber( id )

	-- Check to see if we don't have this already...
	if exsto.CloudDB:GetRow( id ) and !update then
		if CLIENT then
			local data = exsto.CloudDB:GetRow( id )
			exsto.Cloud.Execute( id )
			exsto.Cloud.CallUpdate( data )
			
			-- What the hell?  Make a note in the plugin table.
			exsto.Cloud.ServerPlugins = exsto.Cloud.ServerPlugins or {}
			exsto.Cloud.ServerPlugins[ tonumber( id ) ] = {
				Name = data.Name;
				Author = data.Author;
				Identify = tonumber( id );
				Version = data.Version;
				Type = data.Type;
				Downloads = data.Downloads;
				Description = data.Description;
				Object = t != "server" and exsto.GetLastPluginRegister() or nil;
			}

			return 
		end
		
		if type( ply ) == "Player" then
			ply:Print( exsto_CHAT, COLOR.NORM, "A plugin already exists under ID ", COLOR.NAME, tostring( id ), COLOR.NORM, "!" )
		else
			exsto.ErrorNoHalt( "CLOUD --> A plugin already exists under '" .. id .. "'" )
		end
		return
	end
	exsto.Cloud.DownMan[ id ] = {
		Caller = ply or nil;
	}
	exsto.Cloud.GetPluginInfo( id, CLOUD_SecondStageDownload )
end

function exsto.Cloud.FinalizeDownload( id )
	local info = exsto.Cloud.DownMan[ id ]
		info.Data.Identify = tonumber( id )
	file.Write( "exsto_cloud/pluginid_" .. id .. "_" .. info.Data.Version .. ".txt", info.Code )
	
	exsto.CloudDB:AddRow( {
		Name = info.Data.Name;
		Author = info.Data.Author;
		Identify = tonumber( info.Data.ID );
		Version = info.Data.Version;
		Type = info.Data.Type;
		Downloads = info.Data.Downloads;
		Description = exsto.Cloud.ServerData[ tonumber( info.Data.ID ) ].Description or "None Provided." ;
	} )
	
	-- Send to clients if we can
	if SERVER then
		if info.Data.Type != "server" then timer.Simple( 0.1, exsto.Cloud.AddToResource, id ) end
		timer.Simple( 0.1, exsto.Cloud.SendToClients, id ) -- We need to send anyway?  He needs a list of server plugins.
	elseif CLIENT then
		exsto.Cloud.ServerPlugins = exsto.Cloud.ServerPlugins or {}
		exsto.Cloud.ServerPlugins[ tonumber( id ) ] = {
			Name = info.Data.Name;
			Author = info.Data.Author;
			Identify = tonumber( id );
			Version = info.Data.Version;
			Type = info.Data.Type;
			Downloads = exsto.Cloud.ServerData[ tonumber( info.Data.ID ) ].Description or "None Provided.";
			Description = info.Data.Downloads;
		}
	end
	
	-- Cleanup
	exsto.Cloud.DownMan[ id ] = nil
	
	-- Execute
	exsto.Cloud.Execute( id )
	exsto.Cloud.CallUpdate( info.Data )
end	

function exsto.Cloud.CallUpdate( tbl )
	hook.Call( "ExPlugDownloaded", nil, tbl )
end

--[[ -----------------------------------
	Category: Plugin Removal
	----------------------------------- ]]

function exsto.Cloud.DeletePlugin( id, ply )
	for _, data in ipairs( exsto.CloudDB:GetAll() ) do
		if id == data.Identify then -- Our baby is here!
			-- Unload the plugin.
			if exsto.Cloud.PluginObjects[ id ] then
				-- Tell the client we lost his commands?
				for id in pairs( exsto.Cloud.PluginObjects[ id ].Commands ) do
					local sender = exsto.CreateSender( "ExDelCommand", "all" )
						sender:AddString( id )
					sender:Send()
				end
				exsto.Cloud.PluginObjects[ id ]:Unload()
			end
			
			
			
			file.Write( "exsto_cloud/pluginid_" .. data.Identify .. "_" .. data.Version .. ".txt", "-- Deleted by " .. ply:Nick() or "Cloud" )
			exsto.CloudDB:DropRow( data.Identify )
			
			exsto.Cloud.DeleteOnClients( data.Identify )
			exsto.Print( exsto_CONSOLE, "CLOUD --> Deleting plugin " .. data.Identify )
			return
		end
	end
	
	if type( ply ) == "Player" then
		ply:Print( exsto_CHAT, COLOR.NORM, "Couldn't find any plugin under ID ", COLOR.NAME, id, COLOR.NORM, "!" )
	else
		exsto.ErrorNoHalt( "CLOUD --> Cannot delete unknown plugin '" .. id .. "'" )
	end
end

function exsto.Cloud.DeleteOnClients( id )
	local sender = exsto.CreateSender( "ExDelPlugin", "all" )
		sender:AddChar( id )
	sender:Send()
end

--[[ -----------------------------------
	Category: Plugin Executing
	----------------------------------- ]]

local currentExecutionID = nil
function exsto.Cloud.Execute( id )
	local version = exsto.CloudDB:GetRow( tonumber( id ) ).Version
	local code = file.Read( "exsto_cloud/pluginid_" .. id .. "_" .. version .. ".txt" )
	if !code or code == "" then
		exsto.Error( "CLOUD --> Failure to execute " .. id .. ".  No file or code found." )
	end
	
	currentExecutionID = id
	exsto.Cloud.ExecuteString( code, id, version )
end

function exsto.Cloud.ExecuteString( str, id, ver )
	id = id or math.random( 0, 100 )
	local func = CompileString( str, "ExCloud_" .. id .. " _" .. ver or "NOVER" )
	if type( func ) != "function" then
		exsto.ErrorNoHalt( "CLOUD --> " .. id .. " --> Contains lua parsing errors.  Read previous error." )
		return false
	end
	
	local status, err = pcall( func )
	if !status then
		exsto.ErrorNoHalt( "CLOUD --> " .. id .. " --> Error executing.\n" .. err .. "\n" )
		return false
	end
	
	exsto.Cloud.PluginObjects[ id ] = exsto.GetLastPluginRegister();
	if SERVER then -- We need to update with whatever the hell just happened.
		for id in pairs( exsto.GetLastPluginRegister().Commands ) do
			exsto.SendCommand( id, "all" )
		end
	end
end

hook.Add( "ExPluginRegister", "ExCloudAssociativePluginMonitor", function( plug )
	end )

-- Finalize
if SERVER then
	//include( "sv_cloud.lua" )
	
	//AddCSLuaFile( "cl_cloud.lua" )
else
	//include( "cl_cloud.lua" )
end