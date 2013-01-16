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

local plugin = {}

--[[ -----------------------------------
	Function: exsto.CreatePlugin
	Description: Creates a metatable plugin.
     ----------------------------------- ]]
function exsto.CreatePlugin()
	local obj = {}
	
	setmetatable( obj, plugin )
	plugin.__index = plugin
	
	obj.Info = {}
	obj.Commands = {}
	--obj.Hooks = {}
	--obj.HookID = {}
	obj.FEL = {}
	obj.FEL.CreateTable = {}
	obj.FEL.AddData = {}
	obj.Variables = {}
	obj.Overrides = {}
	obj.QuickmenuRequests = {}
	
	-- Set defaults for info.
	obj.Info = {
		Name = "Unknown",
		Desc = "None Provided",
		Owner = "Unknown",
		Experimental = false,
		Disabled = false,
	}
	
	return obj
end

--[[ -----------------------------------
	Function: plugin:SetInfo
	Description: Sets the information of a plugin.
     ----------------------------------- ]]
function plugin:SetInfo( tbl )

	tbl.Name = tbl.Name or "Unknown"
	tbl.Desc = tbl.Desc or "None Provided"
	tbl.Experimental = tbl.Experimental or false
	tbl.Disabled = tbl.Disabled or false
	tbl.Clientside = tbl.Clientside or false

	self.Info = tbl
end

--[[ -----------------------------------
	Function: plugin:Register
	Description: Registers the plugin with Exsto.
     ----------------------------------- ]]
local queuedPlugins = {}

if SERVER then
	concommand.Add( "_ExClientPlugsReady", function( ply )
		hook.Call( "ExClientPluginsReady", nil, ply )
	end )
end

hook.Add( "exsto_RecievedSettings", "exsto_CheckOnSettings", function()
	-- Go through our client plugins and remove those who the server doesn't allow.
	for short, data in pairs( exsto.Plugins ) do
		if tobool( exsto.ServerPlugSettings[ short ] ) == false and !data.Clientside then
			data.Object:Unload()
		end
	end
	hook.Call( "ExPluginsReady" )
	RunConsoleCommand( "_ExClientPlugsReady" )
end )

function plugin:Register()
	
	-- Check and see if we exist in the saved plugin table.
	if !exsto.PluginSaved( self ) then
		exsto.NeedSaved[self.Info.ID] = !self.Info.Disabled
	else
		
		-- We are saved, so lets check and see if we are disabled.
		if exsto.PluginDisabled( self ) then
			exsto.Print( exsto_CONSOLE, "PLUGIN --> Skipping loading plugin " .. self.Info.ID .. ".  Not Enabled." )
			
			-- We need to tell Exsto hes atleast disabled.
			exsto.Plugins[self.Info.ID] = {
				Name = self.Info.Name,
				Desc = self.Info.Desc,
				ID = self.Info.ID,
				Owner = self.Info.Owner,
				Clientside = self.Info.Clientside,
				Experimental = self.Info.Experimental or false,
				Object = self,
				Disabled = true,
			}
	
			return
		end
		
	end
	
	--self:CreateGamemodeHooks()
	
	-- Tell Exsto we exist!
	exsto.Plugins[self.Info.ID] = {
		Name = self.Info.Name,
		Desc = self.Info.Desc,
		ID = self.Info.ID,
		Owner = self.Info.Owner,
		Clientside = self.Info.Clientside,
		Experimental = self.Info.Experimental or false,
		Object = self,
		Disabled = false,
	}

	-- Construct the commands we requested.
	for k,v in pairs( self.Commands ) do
		if CLIENT then return end
		--print( "Passing command " .. k .. " to comsys" )
		exsto.AddChatCommand( k, v )
	end
	
	-- Construct FEL tables.
	for k,v in pairs( self.FEL.CreateTable ) do
		if CLIENT then return end
		self.FEL.DB = FEL.CreateDatabase( k )
			self.FEL.DB:ConstructColumns( v[1] )
	end 
	
	-- Insert requested FEL.AddData
	for k,v in pairs( self.FEL.AddData ) do
		if CLIENT then return end
		self.FEL.DB:AddRow( v )
	end
	
	-- Create variables requested
	for k,v in pairs( self.Variables ) do
		if CLIENT then return end
		exsto.AddVariable( v )
	end
	
	-- Init the overrides
	for k,v in pairs( self.Overrides ) do
		v.Table[v.Old] = self[v.New]
	end
	
	-- Quickmenu Requests
	for _, info in ipairs( self.QuickmenuRequests ) do
		exsto.SetQuickmenuSlot( info.name, info.disp, info.data )
	end
	
	--MsgC( COLOR.NAME, "." )
	
	--exsto.Print( exsto_CONSOLE, "PLUGIN --> Loading " .. self.Info.Name .. " by " .. self.Info.Owner .. "!" )
	
	self:Init()
	self.Info.Initialized = true
	exsto.LastPluginRegister = self
	
	hook.Call( "ExPluginRegister", nil, self )
end

--[[ -----------------------------------
	Function: plugin:Unload
	Description: Unloads the plugin
     ----------------------------------- ]]
function plugin:Unload()

	exsto.Print( exsto_CONSOLE, "PLUGIN --> Unloading " .. self.Info.Name .. "!" )
	
	-- Call our own "OnUnload"
	if self.OnUnload then
		self:OnUnload()
	end
	
	-- Remove the over-rides
	for k,v in pairs( self.Overrides ) do
		v.Table[v.Old] = v.Saved
	end
	
	-- Remove chat commands
	if type( self.Commands ) == "table" and type( exsto.RemoveChatCommand ) == "function" then
		for k,v in pairs( self.Commands ) do
			exsto.RemoveChatCommand( k )
		end
	end
	
	self.Info.Disabled = true
end

--[[ -----------------------------------
	Function: plugin:Reload
	Description: Reloads a plugin
     ----------------------------------- ]]
function plugin:Reload()
	self:Unload()
	self:Register()	
end

--[[ -----------------------------------
		Plugin Helper Functions
     ----------------------------------- ]]
function plugin:IsEnabled()
	if exsto.PluginDisabled( self ) then return false end
	if self.Info.Disabled then return false end
	return true
end

function plugin:Print( enum, ... )
	if type( enum ) == "string" then
		exsto.Print( exsto_CONSOLE, "PLUGINS --> " .. self.Info.Name .. " --> " .. enum )
		return
	end

	exsto.Print( enum, ... )
end

function plugin:Debug( msg )
	exsto.Debug( "Plugins --> " .. self.Info.Name .. " --> " .. msg )
end

function plugin:Error( msg )
	exsto.ErrorNoHalt( "Plugins --> " .. self.Info.Name .. " --> " .. msg )
end

function plugin:AddVariable( tbl )
	table.insert( self.Variables, tbl )
end

function plugin:CreateTable( id, tbl, options )
	self.FEL.CreateTable[id] = { tbl, options }
end

function plugin:AddData( id, tbl )
	self.FEL.AddData[id] = tbl
end

function plugin:AddCommand( id, tbl )
	tbl.Plugin = self
	self.Commands[id] = tbl
end

function plugin:AddOverride( old, new, tbl )
	table.insert( self.Overrides, { Old = old, New = new, Table = tbl, Saved = tbl[old] } )
end

function plugin:SendData( hook, ply, ... )
	self:Print( "DEPRICATED SENDING METHOD!" )
	exsto.UMStart( hook, ply, ... )
end

function plugin:DataHook( hook )
	self:Print( "DEPRICATED SENDING METHOD!" )
	exsto.UMHook( hook, function( ... ) self[ hook ]( self, ... ) end )
end

function plugin:RequestQuickmenuSlot( commandName, dispName, _data )
	table.insert( self.QuickmenuRequests, { name = commandName, data = _data, disp = dispName } )
end

--[[ -----------------------------------
	Function: plugin:AddHook
	Description: Adds a hook to a plugin
     ----------------------------------- 
function plugin:AddHook( name, func )
	-- Construct the unique name.
	local id = self.Info.ID .. "-" .. name
	
	exsto.Hooks[self.Info.ID] = {}
	exsto.Hooks[self.Info.ID]["Name"] = name
	exsto.Hooks[self.Info.ID]["ID"] = id
	
	hook.Add( name, id, func )
	exsto.Print( exsto_CONSOLE_DEBUG, "PLUGIN --> " .. self.Info.ID .. " --> Adding " .. name .. " hook!" )
end]]

function plugin:Init()
end

	
	
