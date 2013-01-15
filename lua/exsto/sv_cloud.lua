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

exsto.AddVariable({
	Pretty = "Cloud Server Notify",
	Dirty = "cloud_serv_notify",
	Default = true,
	Description = "Enables or disables the full server notifications CLOUD gives.",
	Possible = { true, false },
})

exsto.AddVariable({
	Pretty = "Cloud Enabled",
	Dirty = "cloud_enabled",
	Default = true,
	Description = "Enables or disables Exsto CLOUD.",
	Possible = { true, false },
})

exsto.AddVariable({
	Pretty = "Cloud Update Settings",
	Dirty = "cloud_update_settings",
	Default = "standard",
	Description = "A variable for Cloud update settings.\nStandard --> Updates automatically, except if the updated plugin is not verified.\nForce --> Updates always.\nNever --> Never updates.",
	Possible = { "standard", "force", "never" },
})

--[[ -----------------------------------
	Category: General
	----------------------------------- ]]

function exsto.Cloud.UpdateCheck()
	for _, data in ipairs( exsto.CloudDB:GetAll() ) do
		if exsto.Cloud.ServerData[ data.Identify ] and exsto.Cloud.ServerData[ data.Identify ].Version > data.Version then
			if exsto.GetValue( "cloud_update_settings" ) == "never" then return end -- End us if we don't want to update.
			if ( exsto.GetValue( "cloud_update_settings" ) == "standard" and exsto.Cloud.ServerData[ data.Identify ].Verified != 0 ) or exsto.GetValue( "cloud_update_settings" ) == "force" then 
				exsto.Print( exsto_CONSOLE, "CLOUD --> Plugin '" .. data.Identify .. "' requires an update!" )
				exsto.Cloud.DownloadPlugin( data.Identify, nil, true )
			end
		end
	end
end
hook.Add( "ExCloudJSONReceived", "ExUpdatePlugins", exsto.Cloud.UpdateCheck )

--[[ -----------------------------------
	Category: Client Communication
	----------------------------------- ]]
	
function exsto.Cloud.AddToResource( id )
	local data = exsto.CloudDB:GetRow( id )
	
	resource.AddFile( "data/exsto_cloud/pluginid_" .. data.Identify .. "_" .. data.Version .. ".txt" )
end

function exsto.Cloud.SendToClients( id )
	local data = exsto.CloudDB:GetRow( id )
	
	if data.Type == "server" then
		local sender = exsto.CreateSender( "ExSendPluginIDS", "all" )
			sender:AddChar( 1 )
			sender:AddChar( data.Identify )
			sender:AddShort( data.Version )
			sender:AddString( data.Name )
			sender:AddString( data.Author )
			sender:AddString( data.Type )
			sender:AddShort( data.Downloads )
			sender:AddString( data.Description )
		sender:Send()
		return
	end
	
	local sender = exsto.CreateSender( "ExCloudDLWrapper", "all" )
		sender:AddShort( data.Identify )
	sender:Send()
end

--[[ -----------------------------------
	Category: Exsto Interface
	----------------------------------- ]]

function exsto.DownloadPlugin( ply, id )
	exsto.Cloud.DownloadPlugin( id, ply )
end
exsto.AddChatCommand( "getplugin", {
	Call = exsto.DownloadPlugin,
	Desc = "Downloads a plugin from CLOUD.",
	Console = { "getplug" },
	Chat = { "!getplug" },
	ReturnOrder = "ID",
	Args = { ID = "NUMBER" }
})

function exsto.ForceCheck( ply )
	exsto.Cloud.UpdateCheck()
	return { ply, COLOR.NORM, "Forcing a ", COLOR.NAME, " cloud ", COLOR.NORM, " update check!" }
end
exsto.AddChatCommand( "cloudupdate", {
	Call = exsto.ForceCheck,
	Desc = "Forces Cloud to do an update check.",
	Console = { "cupdate" },
	Chat = { "!cupdate" },
	ReturnOrder = "",
	Args = {}
})

function exsto.DeletePlugin( ply, id )
	print( id, ")_____" )
	exsto.Cloud.DeletePlugin( id, ply )	
end
exsto.AddChatCommand( "delplugin", {
	Call = exsto.DeletePlugin,
	Desc = "Deletes a local copy of a plugin.",
	Console = { "delplug" },
	Chat = { "!delplug" },
	ReturnOrder = "ID",
	Args = { ID = "NUMBER" }
})

function exsto.OpenCloudMenu( ply )
	ply:QuickSend( "ExOpenCloud" )
end
exsto.AddChatCommand( "cloud", {
	Call = exsto.OpenCloudMenu,
	Desc = "Opens up the Exsto CLOUD menu.",
	Console = { "cloud" },
	Chat = { "!cloud" },
})

function exsto.SendAllID( ply )
	local plugs = exsto.CloudDB:GetAll()
	local sender = exsto.CreateSender( "ExSendPluginIDS", ply )
		sender:AddChar( #plugs )

		for I = 1, #plugs do
			sender:AddChar( plugs[ I ].Identify )
			sender:AddShort( plugs[ I ].Version )
			sender:AddString( plugs[ I ].Name )
			sender:AddString( plugs[ I ].Author )
			sender:AddString( plugs[ I ].Type )
			sender:AddShort( plugs[ I ].Downloads )
			sender:AddString( plugs[ I ].Description )
		end
	sender:Send()
end
hook.Add( "ExInitSpawn", "ExSendPluginIDS", exsto.SendAllID )

function exsto.CloudInit()
	--if exsto.GetVar( "cloud_enabled" ).Value == false then exsto.ErrorNoHalt( "CLOUD --> Disabled by variable!  Halting initialization!" ) return end
	exsto.Cloud.GrabPluginList()
	
	-- Init our plugins
	for _, data in ipairs( exsto.CloudDB:GetAll() ) do
		if data.Type == "server" then
			exsto.Cloud.Execute( data.Identify )
		else
			if data.Type == "shared" then
				exsto.Cloud.Execute( data.Identify )
				exsto.Cloud.AddToResource( data.Identify )
			else
				exsto.Cloud.AddToResource( data.Identify )
			end
		end
	end

end
//exsto.CloudInit()