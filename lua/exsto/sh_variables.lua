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
exsto.VariablesT = {}

local dataTypes = {
	string = function( var ) return tostring( var:GetString() ) end,
	boolean = function( var ) return tobool( var:GetString() ) end,
	number = function( var ) return tonumber( var:GetFloat() ) end,
}

-- Variable Object
local var = {}
	var.__index = var
	
function exsto.CreateVariable( id, display, default, help )
	local obj = {}
	setmetatable( obj, var )
	
	obj:SetID( id )
	obj:SetDisplay( display )
	
	-- Judging based off the default value: keep the variable the same data-type, unless specified otherwise.
	obj:SetDataType( type( default ) )
	
	-- Now we need to set the 'default' to either a number or string, because CreateConVar can't handle anything else.
	if obj.Type != "number" or obj.Type != "string" then
		default = tostring( default )
	end
	
	exsto.Debug( "Variables --> Creating variable '" .. id .. "' with default value '" .. default .. "' (" .. obj.Type .. ")", 3 )
	
	-- Create the convar for GMODE
	obj.CVar = CreateConVar( id, default, FCVAR_ARCHIVE, help )

	-- Callback for the cvar.
	cvars.AddChangeCallback( id, function( cid, oldval, newval )
		if obj._IgnoreCallback then obj._IgnoreCallback = false return end
		if oldval == newval then return end -- No need.
		
		-- QOS
		if !obj:PossibleCheck( newval ) then
			-- I believe the only place that this can happen is through the console.  So print the result there.
			exsto.Print( exsto_CONSOLE, "Unable to set '" .. cid .. "' to '" .. newval .. "' - It can only be the following values:" )
			exsto.Print( exsto_CONSOLE, table.concat( obj.Possible, ", " ) )
			
			-- Create a timer to re-change this value back to whatever it was.
			timer.Simple( 0.01, function()
				RunConsoleCommand( cid, oldval )
			end )
			
			return
		end
		
		if !obj.Callback then return end
		local succ, err = pcall( obj.Callback, oldval, newval )
		if !succ then
			exsto.ErrorNoHalt( "Variables --> Callback for '" .. cid .. "' failed with:" )
			exsto.ErrorNoHalt( err )
		end
	end )
	
	-- Insert into the main table.
	exsto.VariablesT[ obj:GetID() ] = obj;
	
	return obj
end

function var:SetDataType( t )
	self.Type = t
end

-- Checks to see if a value is possible.
function var:PossibleCheck( val )
	if !self.Possible then return true end
	for _, entry in ipairs( self.Possible ) do
		if val == entry then return true end
	end
	return false
end

function var:SetPossible( ... )
	self.Possible = {...}
end

function var:SetCallback( func )
	self.Callback = func
end

function var:SetValue( val )
	RunConsoleCommand( self:GetID(), val )
	self.Value = val
end

function var:GetValue()
	-- TODO: Correct parsing of values.
	
	return dataTypes[ self.Type ]( self ) or self:GetString()
end

function var:GetConsoleEditable() return self.ConsoleEditable end
function var:SetConsoleEditable( bool ) self.ConsoleEditable = bool end
function var:GetID() return self.ID end
function var:SetID( id ) self.ID = id end
function var:GetDisplay() return self.Display end
function var:SetDisplay( disp ) self.Display = disp end

-- CVar transporters
function var:GetInt() return self.CVar:GetFloat() end -- Do we want this like this?
function var:GetFloat() return self.CVar:GetFloat() end
function var:GetString() return self.CVar:GetString() end
function var:GetBool() return self.CVar:GetBool() end	