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


-- EVC (Exsto Var Controller)

exsto.VarDB = FEL.CreateDatabase( "exsto_data_variables" )
	exsto.VarDB:ConstructColumns( {
		Pretty = "TEXT:not_null";
		Dirty = "VARCHAR(100):primary:not_null";
		Value = "TEXT:not_null";
		DataType = "TEXT:not_null";
		Description = "TEXT";
		Possible = "TEXT";
		EnvVar = "TEXT",
	} )
	
exsto.Variables = {}

local dataTypes = {
	string = function( data ) return tostring( data ), "string" end,
	boolean = function( data ) return tobool( data ), "boolean" end,
	number = function( data ) return tonumber( data ), "number" end,
}

--[[ -----------------------------------
	Function: exsto.AddVariable
	Description: Creates a variable and inserts it into the Exsto table.
	 ----------------------------------- ]]
function exsto.AddVariable( data )
	if type( data ) != "table" then exsto.ErrorNoHalt( "Issue creating variable!  Not continuing in this function call!" ) return end
	
	if exsto.FindVar( data.Dirty ) then
		-- Update its callback function.  Those don't save through!
		exsto.Variables[data.Dirty].OnChange = data.OnChange
		return false
	end
	
	local filler_function = function( val ) return true end
	
	exsto.Variables[data.Dirty] = {
		Pretty = data.Pretty,
		Dirty = data.Dirty,
		Value = data.Default,
		DataType = type( data.Default ),
		Description = data.Description or "No Description Provided!",
		OnChange = data.OnChange or nil,
		Possible = data.Possible or {},
		EnvVar = data.EnvVar or false,
	}
	
	exsto.Print( exsto_CONSOLE_DEBUG, "EVC --> " .. data.Dirty .. " --> Adding from function, was not in database!" )
	exsto.SaveVarInfo( data.Dirty )

end

--[[ -----------------------------------
	Function: exsto.AddEnvironmentVar
	Description: Creates an EnvVar
	 ----------------------------------- ]]
function exsto.AddEnvironmentVar( dirty, value )
	exsto.AddVariable( {
		Pretty = "envar_" .. dirty,
		Dirty = dirty,
		Default = value,
		EnvVar = true,
	} )
end

--[[ -----------------------------------
	Function: exsto.SetVar
	Description: Sets a variable to be a certian value, then calls the callback.
	 ----------------------------------- ]]
function exsto.SetVar( dirty, value )
	local var = exsto.FindVar( dirty ) 
	if !var then return end

	value = dataTypes[var.DataType]( value )
	
	local returnData
	if type( var.OnChange ) == "function" then
		local accepted, returnData = var.OnChange( value )
		
		if accepted then
			exsto.Variables[dirty].Value = value
			exsto.SaveVarInfo( dirty )
		else
			return accepted, returnData
		end
	else
		exsto.Variables[dirty].Value = value
		exsto.SaveVarInfo( dirty )
		return true
	end
	
end

--[[ -----------------------------------
	Function: exsto.SaveVarInfo
	Description: Saves the variable's information to FEL.
	 ----------------------------------- ]]
function exsto.SaveVarInfo( dirty )
	local var = exsto.FindVar( dirty )	
	exsto.VarDB:AddRow( {
		Pretty = var.Pretty;
		Dirty = var.Dirty;
		Value = tostring( var.Value );
		DataType = var.DataType;
		Description = var.Description;
		Possible = FEL.NiceEncode( var.Possible );
		EnvVar = tostring( var.EnvVar );
	} )
end

--[[ -----------------------------------
	Function: exsto.GetVar
	Description: Returns a variable's data table.
	 ----------------------------------- ]]
function exsto.GetVar( dirty )
	if !exsto.Variables or !exsto.Variables[ dirty ] then return nil end
	return exsto.Variables[dirty]
end
exsto.FindVar = exsto.GetVar

--[[ -----------------------------------
	Function: exsto.GetValue
	Description: Returns a variable's value
	 ----------------------------------- ]]
function exsto.GetValue( dirty )
	return exsto.Variables[dirty].Value
end

--[[ -----------------------------------
	Function: exsto.Variable_Load
	Description: Loads all existing exsto variables.
	 ----------------------------------- ]]
function exsto.Variable_Load()
	local vars = exsto.VarDB:GetAll()

	if !vars then return end
	
	exsto.Print( exsto_CONSOLE, "Variables --> Starting load." )

	for k,v in pairs( vars ) do
		
		exsto.Print( exsto_DEBUG, "EVC --> Loading variable " .. v.Pretty .. "!" )
	
		local oldchange = exsto.Variables[v.Dirty]
		if oldchange and oldchange.OnChange then oldchange = oldchange.OnChange end
		
		-- Fix the data type.
		local datatype = exsto.ParseVarType( v.Value )
		local value = dataTypes[datatype]( v.Value )
		
		exsto.Variables[v.Dirty] = {
			Pretty = v.Pretty,
			Dirty = v.Dirty,
			Value = value,
			DataType = datatype,
			Description = v.Description,
			OnChange = oldchange or nil,
			Possible = FEL.NiceDecode( v.Possible ),
			EnvVar = tobool( v.EnvVar )
		}
	end
	
	exsto.Print( exsto_CONSOLE, "Variables --> Ended load." )
end

exsto.Variable_Load()