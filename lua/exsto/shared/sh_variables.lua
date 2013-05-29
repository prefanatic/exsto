--[[
	Exsto
	Copyright (C) 2013  Prefanatic

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

-- Exsto's Variable System.  Ho ho!

-- Data table
exsto.Variables = {}

local dataTypes = {
	string = function( var ) return tostring( var:GetString() ) end,
	boolean = function( var ) return var:GetString() == "true" end,
	number = function( var ) return tonumber( var:GetFloat() ) end,
	multi = function( var ) return string.Explode( ",", var:GetString() ) end,
}

-- Networking
if SERVER then

	function exsto.SendVariable( obj, ply )
		if type( obj ) == "string" then obj = exsto.Variables[ obj ] end
		if !obj then exsto.ErrorNoHalt( "Variables --> Unable to send variable!" ) return end
		
		exsto.Debug( "Variables --> Sending '" .. obj:GetID() .. "'", 3 )
		
		local sender = exsto.CreateSender( "ExSendVariable", ply )
			sender:AddString( obj:GetID() )
			sender:AddString( obj:GetDisplay() )
			sender:AddString( obj:GetHelp() )
			sender:AddVariable( obj:Protected() == true and "*******" or obj:GetValue() )
			sender:AddString( obj:GetType() )
			sender:AddShort( obj.Maximum )
			sender:AddShort( obj.Minimum )
			sender:AddString( obj:GetCategory() )
			sender:AddTable( obj:GetPossible() or {} )
			sender:AddBoolean( obj.Multi or false )
			sender:AddString( obj:GetUnit() )
			sender:AddBool( obj:GetClientOverride() or false )
		sender:Send()
	end
	
	function exsto.SendAllVariables( ply )
		exsto.Debug( "Variables --> Sending all variables to '" .. ply:Nick() .. "'", 2 )
		for id, obj in pairs( exsto.Variables ) do
			exsto.SendVariable( obj, ply )
		end
		exsto.Debug( "Variables --> Variables sent.", 2 )
	end
	hook.Add( "ExClientLoading", "ExSendVariables", exsto.SendAllVariables )

elseif CLIENT then
	
	exsto.ServerVariables = {}

	exsto.CreateReader( "ExSendVariable", function( reader )
		local id = reader:ReadString()
		exsto.ServerVariables[ id ] = {
			ID = id,
			Display = reader:ReadString(),
			Help = reader:ReadString(),
			Value = reader:ReadVariable(),
			Type = reader:ReadString(),
			Maximum = reader:ReadShort(),
			Minimum = reader:ReadShort(),
			Category = reader:ReadString(),
			Possible = reader:ReadTable(),
			Multi = reader:ReadBoolean(),
			Unit = reader:ReadString(),
			ClientOverride = reader:ReadBool(),
		}
		exsto.Debug( "Variables --> Received '" .. id .. "' from the server!", 3 )
		
		-- Can we override an existing client variable?
		if exsto.Variables[ id ] and exsto.ServerVariables[ id ].ClientOverride then
			exsto.Debug( "Variables --> Overriding client variable '" .. id .. "' with server value.", 2 )
			exsto.Variables[ id ]:SetValue( exsto.ServerVariables[ id ].Value )
		end
	end )
	
	function exsto.GetServerValue( id )
		return exsto.ServerVariables[ id ] and exsto.ServerVariables[ id ].Value or nil
	end

end

-- Variable Object
local var = {}
	var.__index = var
	
--[[ Styles
	number -- Wanger
	string -- Text box
	boolean -- Button either depressed or not
	Color -- Figure this out.
	MultiChoice -- DComboBox!
]]
	
function exsto.CreateVariable( id, display, default, help, eVars )
	local obj = {}
	setmetatable( obj, var )

	obj:SetID( id )
	obj:SetDisplay( display )
	obj:SetHelp( help )
	obj:SetCategory( "Misc" )
	
	-- Judging based off the default value: keep the variable the same data-type, unless specified otherwise.
	obj:SetDataType( type( default ) )
	
	-- Set the maximum and default minimum values for the number wanger.
	obj:SetMaximum( 100 )
	obj:SetMinimum( 0 )
	obj:SetUnit( "Units" )
	
	-- Helper if we're a boolean
	if obj:GetType() == "boolean" then 
		exsto.Debug( "Variables --> '" .. id .. "' is an incorrect boolean!  Please change to use 0, 1 booleans instead of true, false.", 3 )
		
		default = ( default == true and 1 ) or ( 0 )
		obj:SetBoolean()
	end
	
	-- Now we need to set the 'default' to either a number or string, because CreateConVar can't handle anything else.
	if obj.Type != "number" or obj.Type != "string" then
		default = tostring( default )
	end
	
	exsto.Debug( "Variables --> Creating variable '" .. id .. "' with default value '" .. default .. "' (" .. obj.Type .. ")", 3 )
	
	-- Create the convar for GMODE
	local fcvar = { FCVAR_ARCHIVE }
	table.Merge( fcvar, eVars or {} )
	obj.CVar = CreateConVar( id, default, fcvar, help )

	-- Callback for the cvar.
	cvars.AddChangeCallback( id, function( cid, oldval, newval )
		exsto.Debug( "Variables --> Attempting variable change on '" .. cid .. "' from '" .. oldval .. "' to '" .. newval .. "'", 3 )

		if obj._IgnoreCallback then obj._IgnoreCallback = false return end
		if oldval == newval then return end -- No need.
			
		-- QOS
		if !obj:PossibleCheck( obj:GetValue() ) then
			-- I believe the only place that this can happen is through the console.  So print the result there.
			exsto.Print( exsto_CONSOLE, "Unable to set '" .. cid .. "' to '" .. newval .. "' - It can only be the following values:" )
			
			-- Clean the possibles into a string.
			local str = ""
			for I = 1, #obj.Possible do
				str = str .. tostring( obj.Possible[ I ] ) .. ( I != #obj.Possible and ", " or "" )
			end
			exsto.Print( exsto_CONSOLE, str )
			
			-- Create a timer to re-change this value back to whatever it was.
			timer.Simple( 0.01, function()
				exsto.Debug( "Variables --> Resetting '" .. cid .. "' to prior value.", 3 )
				obj._IgnoreCallback = true
				RunConsoleCommand( cid, oldval )
			end )
			
			return
		end
		
		-- Send this information down to the client!
		if SERVER then exsto.SendVariable( obj, player.GetAll() ) end
		hook.Call( "ExVariableChanged", nil, obj, obj:GetValue() )
		
		if !obj.Callback then return end
		local succ, err = pcall( obj.Callback, oldval, obj:GetValue() )
		if !succ then
			exsto.ErrorNoHalt( "Variables --> Callback for '" .. cid .. "' failed with:" )
			exsto.ErrorNoHalt( err )
		end
	end )
	
	-- Insert into the main table.
	exsto.Variables[ obj:GetID() ] = obj;
	
	-- If we make one, we need to send it!
	if SERVER then exsto.SendVariable( obj, player.GetAll() ) end
	
	return obj
end

function var:SetCategory( cat )
	self.Category = cat
end

function var:GetCategory() return self.Category end

function var:SetProtected() self._Protected = true end
function var:Protected() return self._Protected end

-- Extraneous settings for the settings page.
function var:SetMaximum( num )
	self.Maximum = num
end
var.SetMax = var.SetMaximum

function var:SetMinimum( num )
	self.Minimum = num
end
var.SetMin = var.SetMinimum

-- Helper to designate between variables being booleans or not.
function var:IsBoolean()
	if self.Maximum == 1 and self.Minimum == 0 then return true end
	return false
end

-- Helper to set booleans as numbers
function var:SetBoolean()
	self:SetPossible( 0, 1 ) 
	
	self:SetDataType( "number" )
	
	self:SetMaximum( 1 )
	self:SetMinimum( 0 )
end

function var:SetUnit( u ) self.Unit = u end
function var:GetUnit() return self.Unit end

function var:GetType() return self.Type end

function var:SetDataType( t )
	self.Type = t
end

-- Checks to see if a value is possible.
function var:PossibleCheck( val )
	if !self.Possible then return true end
	if type( val ) == "table" then -- Our value is coming as a table!
		local g = {}
		for _, value in ipairs( val ) do
			g[ value ] = false;
			for _, entry in ipairs( self.Possible ) do
				if value == entry then g[ value ] = true break end
			end
		end
		
		-- Final check
		for _, value in ipairs( val ) do
			if g[ value ] == false then return false end
		end
		return true
	end
	for _, entry in ipairs( self.Possible ) do
		if val == entry then return true end
	end
	return false
end

function var:SetPossible( ... )
	self.Possible = {...}
end

function var:SetMultiChoice()
	self.Multi = true
	self.Type = "multi"
end

function var:SetCallback( func )
	self.Callback = func
end

function var:SetValue( val )
	-- We need to parse out into a number if this is a boolean.  D:
	if val == true then val = 1 elseif val == false then val = 0 end
	RunConsoleCommand( self:GetID(), val )
	self.Value = val
end

function var:GetValue()
	if CLIENT and exsto.ServerVariables and exsto.ServerVariables[ var:GetID() ] and exsto.ServerVariables[ var:GetID() ].ClientOverride then
		local svVar = exsto.ServerVariables[ var:GetID() ]
		return svVar.Value
	end
	
	return dataTypes[ self.Type ]( self ) or self:GetString()
end

function var:SetClientOverride( bool ) self.ClientOverride = bool end
function var:GetClientOverride() return self.ClientOverride end
function var:GetConsoleEditable() return self.ConsoleEditable end
function var:SetConsoleEditable( bool ) self.ConsoleEditable = bool end
function var:GetID() return self.ID end
function var:SetID( id ) self.ID = id end
function var:GetDisplay() return self.Display end
function var:SetDisplay( disp ) self.Display = disp end
function var:GetHelp() return self.Help end
function var:SetHelp( h ) self.Help = h end
function var:GetPossible() return self.Possible end

-- CVar transporters
function var:GetInt() return self.CVar:GetFloat() end -- Do we want this like this?
function var:GetFloat() return self.CVar:GetFloat() end
function var:GetString() return self.CVar:GetString() end
function var:GetBool() return self.CVar:GetBool() end	

-- Call out a hook saying we're ready for variable creation.
hook.Call( "ExVariableInit" )