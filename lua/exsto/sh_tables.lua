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

--[[ -----------------------------------
		LUA Metatable Registry
     ----------------------------------- ]]
exsto.Registry = {
	Player = FindMetaTable( "Player" ),
	Entity = FindMetaTable( "Entity" ),
}

--[[ -----------------------------------
		UMSG Table Info
     ----------------------------------- ]]
exsto.UMSG = {
	STRING = 1,
	FLOAT = 2,
	SHORT = 3,
	LONG = 4,
	BOOLEAN = 5,
	ENTITY = 6,
	VECTOR = 7,
	ANGLE = 8,
	TABLE_BEGIN = 9,
	TABLE_END = 10,
	COLOR_BEGIN = 11,
	COLOR_END = 12,
	NIL = 0
}

--[[ -----------------------------------
	Color Stuff
     ----------------------------------- ]]

COLOR = {}
	COLOR.NORM = Color( 255, 252, 229, 255 )
	COLOR.PAC = Color( 100, 100, 100, 255 )
	COLOR.RED = Color( 200, 50, 50, 255 )
	COLOR.GREEN = Color( 50, 200, 50, 255 )
	COLOR.BLUE = Color( 50, 50, 200, 255 )
	COLOR.EXSTO = Color( 146, 232, 136, 255 )
	COLOR.NAME = Color( 255, 105, 105, 255 )
	
-- Color to Text support
CTEXT ={}

for k,v in pairs( COLOR ) do
	CTEXT[tostring( k ):lower()] = v
end

--[[ -----------------------------------
	Function: exsto.CreateColoredPrint
	Description: Returns a table w/ colors for exsto.Print
    ----------------------------------- ]]

--[[ -----------------------------------
	Function: exsto.GetClosestString
	Description: Returns the closest string in a table.
    ----------------------------------- ]]
local function StringDist( s, t )
	local d, sn, tn = {}, #s, #t
	local byte, min = string.byte, math.min
		for i = 0, sn do d[i * tn] = i end
		for j = 0, tn do d[j] = j end
		for i = 1, sn do
			local si = byte(s, i)
			for j = 1, tn do
				d[i*tn+j] = min(d[(i-1)*tn+j]+1, d[i*tn+j-1]+1, d[(i-1)*tn+j-1]+(si == byte(t,j) and 0 or 1))
			end
		end
	return d[#d]
end
	
function exsto.GetClosestString( str, possible, id, ply, text )
	local data = { Max = 100, New = "" }
	local dist

	for k,v in pairs( possible ) do
		if id then v = v[id] end
		dist = StringDist( str, v )
		if dist < data.Max then data.Max = dist data.New = v end
	end
	
	if text and ply then
		ply:Print( exsto_CHAT, COLOR.NORM, text .. " ", COLOR.NAME, str, COLOR.NORM, ".  Maybe you want ", COLOR.NAME, data.New, COLOR.NORM, "?" )
	end
	
	return data.New
end
--[[ -----------------------------------
	Function: exsto.SmartNumber
	Description: Returns the number in a table that has no index.
     ----------------------------------- ]]
function exsto.SmartNumber( tbl )
	return table.Count( tbl )
end

--[[ -----------------------------------
	Function: exsto.GetTableID
	Description: Returns the index of a value in a table.
     ----------------------------------- ]]
function exsto.GetTableID( tbl, value )
	for k,v in pairs( tbl ) do if v == value then return k end end
end

--[[ -----------------------------------
	Function: exsto.TextToColor
	Description: Recieves a color from text.
     ----------------------------------- ]]
function exsto.TextToColor( text )
	return CTEXT[text] or nil
end

--[[ -----------------------------------
	Function: exsto.ColorToText
	Description: Recieves a text from a color.
     ----------------------------------- ]]
function exsto.ColorToText( col )
	for k,v in pairs( CTEXT ) do
		if v == col then return k end
	end
	
	return col
end

--[[ -----------------------------------
	Function: exsto.ParseValue
	Description: Parses a value and returns its data type.
     ----------------------------------- ]]
function exsto.ParseValue( value )
	
	if type( value ) == "boolean" then return "boolean" end
	if type( value ) == "number" then return "number" end

	value = value:lower():Trim()

	if value == "true" or value == "false" then return "boolean" end
	if tonumber( value ) then return "number" end
	
	return "string"
	
end
exsto.ParseVarType = exsto.ParseValue

--[[ -----------------------------------
	Function: exsto.FormatValue
	Description: Formats a value depending on its type.
     ----------------------------------- ]]
local dataTypes = {
	string = function( data ) return tostring( data ), "string" end,
	boolean = function( data ) return tobool( data ), "boolean" end,
	number = function( data ) return tonumber( data ), "number" end,
}
	
function exsto.FormatValue( value, type )
	return dataTypes[type]( value )
end

--[[ -----------------------------------
	Function: exsto.TableToNumbers
	Description: Creates a table in numbers, reflecting on a data table
     ----------------------------------- ]]
function exsto.TableToNumbers( tbl )
	local newtbl = table.Copy( table.sort( tbl ) )
	
	local count = 1
	for k,v in pairs( newtbl ) do
		newtbl[count] = { Data = v, Index = k }
		table.remove( newtbl, exsto.GetTableID( newtbl, k ) )
	end
	
	return newtbl, tbl
end

--[[ -----------------------------------
	Function: exsto.GetAddonFolder
	Description: Returns the name of the Exsto addon folder.
     ----------------------------------- ]]
local folder
function exsto.GetAddonFolder()

	if !folder then
		-- Create a fake debug so we can grab where we are running from.
		local runningLoc = debug.getinfo( 1, "S" ).short_src
		
		runningLoc = string.Explode( "\\", runningLoc )
		folder = runningLoc[2]
	end
	
	return folder
	
end
concommand.Add( "GetAddonFolder", exsto.GetAddonFolder )
--[[ -----------------------------------
	Function: exsto.MultiplePlayers
	Description: Returns the number of players, and in a table.
     ----------------------------------- ]]
function exsto.MultiplePlayers( plys )
	if type( plys ) == "Player" then return 1, { plys } end
	
	local data = {}
	local count = table.Count( plys ) 
	
	for I = 1, count do
		data[I] = plys[I]
	end
	
	return count, data
end

--[[ -----------------------------------
	Function: exsto.ConvertToFlagIndex
	Description: Converts a table filled with stringed flags to a numeric flag type.
     ----------------------------------- ]]
function exsto.ConvertToFlagIndex( tbl )
	local data = {}
	for k,v in pairs( tbl ) do
		
		for I = 1, #exsto.FlagIndex do
			if exsto.FlagIndex[I] == v then
				table.insert( data, I )
			end
		end
		
	end

	return data
end

--[[ -----------------------------------
	Function: exsto.ConvertToNormalFlags
	Description: Converts a flag in numeric style to normal
     ----------------------------------- ]]
function exsto.ConvertToNormalFlags( tbl )
	local data = {}
	local flag, desc
	
	for I = 1, #tbl do
		flag = exsto.FlagIndex[I]
		//desc = exsto.Flags[flag]
		
		data[ I ] = flag
	end

	return data
end

--[[ -----------------------------------
	Function: exsto.NiceTime
	Description: Returns a number in a nice string
     ----------------------------------- ]]
function exsto.NiceTime( num )
	--[[local ret, int, dec = "", 0, 0
	
	int, dec = math.modf( 7 * 24 * 60 * num ) -- week
	if int > 0 then
		ret = int .. " weeks, "
	end
	
	int, dec = math.modf( 24 * 60 * dec ) -- days
	if int > 0 then
		ret = ret .. int .. " days, "
	end
	
	int, dec = math.modf( 60 * dec ) -- hours
	if int > 0 then
		ret = ret .. int .. " hours, "
	end
	
	int, dec = math.modf( dec )]]
	
	return num .. " minutes"
end

--[[ -----------------------------------
	Exsto Default Ranks.
     ----------------------------------- ]]
exsto.DefaultRanks = {
	superadmin = {
		Name = "Super Admin",
		Description  = "Head Honcho",
		ID = "superadmin",
		Color = von.serialize( Color( 60, 124, 200, 200 ) ),
		Parent = "admin",
		Immunity = 0,
		FlagsAllow = von.serialize( {
			"issuperadmin", "variable", "resendplug", "deletevar", "createvar", "reloadplug", "playertitle", "addgimp",  "luarun", "cexec",
			"vareditor", "rankeditor",
		} );
		FlagsDeny = von.serialize( {
		} );
	},
	
	admin = {
		Name = "Admin",
		Description  = "The Guy.",
		ID = "admin",
		Color = von.serialize( Color( 60, 124, 100, 200 ) ),
		Parent = "guest",
		Immunity = 1,
		FlagsAllow = von.serialize( {
			"isadmin", "banlist", "mapslist",
		} );
		FlagsDeny = von.serialize( {
		} );
	},
	
	guest = {
		Name = "Guest",
		Description  = "A visitor to the server!",
		ID = "guest",
		Color = von.serialize( Color( 200, 124, 200, 200 ) ),
		Parent = "NONE";
		Immunity = 9,
		FlagsAllow = von.serialize( {
			"getrank", "search", "menu", "gettotaltime", "title", "displayheadtags", "mytitle", "togglechatanim", "updateownerrank",
			"helppage", 
		} );
		FlagsDeny = von.serialize( {
		} );
	}
}