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

-- Variables
exsto.NumberHooks = 0
exsto.ServerPluginSettings = {}
exsto.NeedSaved = {}
exsto.Plugins = {}
exsto.LoadedPlugins = {}
exsto.Hooks = {}
exsto.PlugLocation = "exsto/plugins/"
exsto.PluginLocations = {
	cl = "exsto/plugins/client/";
	sh = "exsto/plugins/shared/";
	sv = "exsto/plugins/server/";
}

if SERVER then

--[[ -----------------------------------
	Function:  exsto.SendPluginSettings
	Description: Sends the plugin settings to a player.
     ----------------------------------- ]]
	function exsto.SendPluginSettings( ply )
		local db = exsto.PluginDB:ReadAll()
		local sender = exsto.CreateSender( "ExRecPlugSettings", ply )
			sender:AddShort( #db )
			for _, data in ipairs( db ) do
				sender:AddString( data.ID )
				sender:AddBool( data.Enabled )
			end
			sender:Send()
	end
	hook.Add( "ExClientLoading", "ExStreamPluginList", exsto.SendPluginSettings )
	
elseif CLIENT then
	
--[[ -----------------------------------
	Function: IncommingHook
	Description: Recieves the server's plugin settings file.
     ----------------------------------- ]]
	function exsto.ReceivePluginSettings( reader )
		exsto.ServerPluginSettings = {}
		for I = 1, reader:ReadShort() do
			exsto.ServerPluginSettings[ reader:ReadString() ] = reader:ReadBool()
		end
		
		hook.Call( "ExReceivedPlugSettings" )
		
		-- Legacy
		hook.Call( "exsto_RecievedSettings" )
	end
	exsto.CreateReader( "ExRecPlugSettings", exsto.ReceivePluginSettings )

end

--[[ -----------------------------------
	Function: exsto.HookCall
	Description: Calls hooks for plugins.
     ----------------------------------- ]]
function exsto.HookCall( name, gm, ... )
	for _, plug in ipairs( exsto.Plugins ) do
		if type( plug[ name ] ) == "function" and plug:IsEnabled() and plug.Initialized then

			local data = { pcall( plug[ name ], plug, ... ) }
			
			-- data[1] == Status
			-- data[2] == Error or First Return
			-- data[3+] == Returns
			
			-- If we are returning something...

			if data[1] == true and data[2] != nil then
				table.remove( data, 1 )
				return unpack( data )
			elseif data[1] == false then -- It returned an error, catch it.
				exsto.ErrorNoHalt( "Hook '" .. name .. "' failed in plugin '" .. plug:GetID() .. "' error: " )
				exsto.ErrorNoHalt( data[2] )
				exsto.Plugins[ _ ]:Disable( 1 )
			end
		end
	end
	
	return exsto_HOOKCALL( name, gm, ... )
end

--[[ -----------------------------------
	Function: exsto.LoadPlugins
	Description: Reads all the plugins from the plugin folder.
     ----------------------------------- ]]
function exsto.LoadPlugins()
	-- Do nothin nomore
end

--[[ -----------------------------------
	Function: exsto.InitPlugins
	Description: Initializes all the plugins that were loaded.
     ----------------------------------- ]]
function exsto.InitPlugins()
	exsto.Print( exsto_CONSOLE, "Plugins --> Starting load." );
	
	if SERVER then
		-- Create the settings database.
		exsto.Debug( "Plugins --> Creating settings table.", 2 );
		exsto.PluginDB = FEL.CreateDatabase( "exsto_plugin_settings" )
			exsto.PluginDB:SetDisplayName( "Plugin Settings" )
			exsto.PluginDB:ConstructColumns( {
				ID = "TEXT:not_null:primary";
				Enabled = "TINYINT:not_null";
			} )
	end

	exsto.Debug( "Plugins --> Looping into load process.", 2 );
	
	-- Client
	local loc = file.Find( exsto.PluginLocations.cl .. "*.lua", "LUA" )
	for _, name in pairs( loc ) do
		exsto.Debug( "Plugins --> Including client: " .. name, 3 )
		exstoClient( "plugins/client/" .. name )
	end
	
	-- Shared
	local loc = file.Find( exsto.PluginLocations.sh .. "*.lua", "LUA" )
	for _, name in pairs( loc ) do
		exsto.Debug( "Plugins --> Including shared: " .. name, 3 )
		exstoShared( "plugins/shared/" .. name )
	end
	
	if SERVER then
		local loc = file.Find( exsto.PluginLocations.sv .. "*.lua", "LUA" )
		for _, name in pairs( loc ) do
			exsto.Debug( "Plugins --> Including server: " .. name, 3 )
			exstoServer( "plugins/server/" .. name )
		end
	end
	
	exsto.Print( exsto_CONSOLE, "Plugins --> Finished load." )
end

--[[ -----------------------------------
	Function: exsto.UnloadAllPlugins
	Description: Unloads all hooks from plugins.
     ----------------------------------- ]]
function exsto.UnloadAllPlugins()
	exsto.NumberHooks = 0
	for k,v in pairs( exsto.Plugins ) do
		v.Object:Unload()
	end
end

--[[ -----------------------------------
	Function: exsto.EnablePlugin
	Description: Enables a plugin, then writes to the settings file.
     ----------------------------------- ]]
function exsto.EnablePlugin( plug )
	plug.Info.Disabled = false
	
	exsto.PluginSettings[plug.Info.ID] = true
	FEL.CreateSettingsFile( "exsto_plugin_settings", exsto.PluginSettings )
	
	plug:Register()
end

--[[ -----------------------------------
	Function: exsto.DisablePlugin
	Description: Disables a plugin, then writes to the settings file.
     ----------------------------------- ]]
function exsto.DisablePlugin( plug )
	plug.Info.Disabled = true
	
	exsto.PluginSettings[plug.Info.ID] = false
	FEL.CreateSettingsFile( "exsto_plugin_settings", exsto.PluginSettings )
	
	plug:Unload()
	plug:Register()
end

--[[ -----------------------------------
	Function: exsto.GetLastPluginRegister
	Description: Returns the last plugin registered
    ----------------------------------- ]]
function exsto.GetLastPluginRegister()
	return exsto.LastPluginRegister or nil
end

--[[ -----------------------------------
	Function: exsto.PluginStatus
	Description: Returns true if a plugin is disabled
     ----------------------------------- ]]
function exsto.PluginStatus( plug )
	for k,v in pairs( exsto.PluginSettings ) do
		if k == plug.Info.ID then return !v end
	end
	return false
end

--[[ -----------------------------------
	Function: exsto.GetPlugin
	Description: Returns the plugin's data object.
     ----------------------------------- ]]
function exsto.GetPlugin( id )
	for _, plug in pairs( exsto.Plugins ) do
		if plug:GetID() == id then return plug end
	end
	return false
end

local function IsLoaded( ID )
	if exsto.GetPlugin( ID ) then return true end
end