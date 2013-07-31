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
	obj.FEL = {}
	obj.FEL.CreateTable = {}
	obj.FEL.AddData = {}
	obj.Variables = {}
	obj.Overrides = {}
	obj.QuickmenuRequests = {}
	obj.HookPriority = {}
	
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
	tbl.CleanUnload = tbl.CleanUnload or false
	
	self._id = tbl.ID

	self.Info = tbl
end

function plugin:ServerStatus() return exsto.ServerPluginSettings[ self:GetID() ] end

-- Checks and make sure we can be online after a server update poll.
function plugin:CheckStatus()
	if CLIENT and self:ServerStatus() == true and self.Initialized == false then -- Server says to reload.
		self.Disabled = false
		self:Register();
	elseif CLIENT and self:ServerStatus() == false and self.Initialized == true then -- Server says to unload.
		self:Unload();
	end
end

--[[ -----------------------------------
	Function: plugin:Register
	Description: Registers the plugin with Exsto.
     ----------------------------------- ]]
function plugin:Register()

	-- Register with Exsto. 
	if not exsto.GetPlugin( self:GetID() ) then
		table.insert( exsto.Plugins, self )
	end
	
	if SERVER then -- Server side plugin checking.
		-- Do we exist in the settings db?
		local f = false
		for _, data in ipairs( exsto.PluginSettings ) do
			if data.ID == self:GetID() then f = data end
		end
		
		-- If we don't exist, create our table entry.
		self:Debug( "Checking settings state.", 2 )
		if not f then
			self:Debug( "No settings found.  Writing.", 2 )
			exsto.PluginDB:AddRow( {
				ID = self:GetID();
				Enabled = 1;
			} )
		end
	end
	
	exsto.LastPluginRegister = self
	
	-- Proper checks are done.  Check to make sure we can inject ourselves, if we're not disabled.
	self:Debug( "Checking disabled state.", 2 )
	if !self:IsEnabled() then
		self:Debug( "Skipping injection.  Disabled.", 1 )
		return
	end
	
	self:Inject()
	
end

function plugin:Inject()
	-- Construct the commands we requested.
	for k,v in pairs( self.Commands ) do
		if CLIENT then return end
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
	
	self:Init()
	self.Initialized = true
	
	hook.Call( "ExPluginRegister", nil, self )
end

--[[ -----------------------------------
	Function: plugin:Unload
	Description: Unloads the plugin
     ----------------------------------- ]]
function plugin:Unload( reason )

	self:Print( "Unloading" .. ( reason and (" - " .. reason) or "" ) )
	
	if !self.Info.CleanUnload then
		self:Debug( "Warning!  This plugin may not unload properly due to developmental error.  It is suggested you perform a server restart in order to cleanly unload." )
	end
	
	-- TODO: Clean Unload Plugins
	
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
	
	self.Disabled = true
	self.Initialized = false
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
	if CLIENT then
		if exsto.ServerPluginSettings[ self:GetID() ] == false then return false end
	elseif SERVER then
		for _, data in ipairs( exsto.PluginSettings ) do
			if data.ID == self:GetID() then return tobool( data.Enabled ) end
		end
	end
	return not self.Disabled
end

function plugin:Enable()
	-- Save this.
	exsto.PluginDB:AddRow( {
		ID = self:GetID();
		Enabled = 1;
	} )
	
	if SERVER then
		for _, d in ipairs( exsto.PluginSettings ) do
			if d.ID == self:GetID() then exsto.PluginSettings[ _ ].Enabled = 1 end
		end
	end
	
	self:Register()
	
	exsto.SendPluginSettings( player.GetAll() )
end

function plugin:Disable( r )
	-- Save this.
	exsto.PluginDB:AddRow( {
		ID = self:GetID();
		Enabled = 0;
	} )
	
	if SERVER then
		for _, d in ipairs( exsto.PluginSettings ) do
			if d.ID == self:GetID() then exsto.PluginSettings[ _ ].Enabled = 0 end
		end
	end
	
	self:Debug( "Disabling!" )
	self.Disabled = true
	self:Unload( r )
	
	exsto.SendPluginSettings( player.GetAll() )
end

function plugin:GetID() return self._id end
function plugin:GetName() return self.Info.Name end

function plugin:CanCleanlyUnload() return self.Info.CleanUnload end

function plugin:Print( enum, ... )
	if type( enum ) == "string" or type( enum ) == "table" then
		exsto.Print( exsto_CONSOLE_LOGO, COLOR.EXSTO, self:GetName(), COLOR.WHITE, " --> ", enum, ... )
		return
	end

	exsto.Print( enum, ... )
end

function plugin:Debug( msg )
	exsto.Debug( self:GetName() .. " --> " .. msg )
end

function plugin:Error( msg )
	exsto.ErrorNoHalt( self:GetName() .. " --> " .. msg )
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

function plugin:CreateReader( h, func )
	exsto.CreateReader( h, function( reader )
		func( self, reader )
	end )
end

function plugin:CreateSender( h, rep )
	return exsto.CreateSender( h, rep )
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

function plugin:SetHookPriority( name, p )
	self.HookPriority[ name ] = p;
end
function plugin:GetHookPriority( name ) return self.HookPriority[ name ] or 10 end

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

	
	
