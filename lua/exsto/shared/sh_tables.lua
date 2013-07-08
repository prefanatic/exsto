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
	COLOR.EXSTO = Color( 116, 202, 254, 255 )
	COLOR.NAME = Color( 255, 105, 105, 255 )
	COLOR.MENU = Color( 133, 133, 133, 255 ) 
	COLOR.EXSTOGREEN = Color( 146, 232, 136, 255 )
	COLOR.EXSTOCOMP = Color( 255, 68, 255, 255 )
	COLOR.WHITE = Color( 255, 255, 255, 255 )
	COLOR.HAZARDYELLOW = Color( 238, 210, 2, 255 )
	COLOR.GREY = Color( 200, 200, 200, 255 )
	
-- Complementary color generator.  Adapted from easyrgb.com
function exsto.GenerateComplementaryColor( col )
	local h, s, l = exsto.ConvertRGBtoHSL( col ) -- Grab the HSL
	
	h = h + 0.5 -- Complement
	if h > 1 then h = h - 1 end
	
	return exsto.ConvertHSLtoRGB( h, s, l ) -- Reconvert into RGB
end

local function hue2RGB( t1, t2, h )
	if h < 0 then h = h + 1 end
	if h > 1 then h = h - 1 end
	if ( 6 * h ) < 1 then return t1 + ( t2 - t1 ) * 6 * h end
	if ( 2 * h ) < 1 then return t2 end
	if ( 3 * h ) < 2 then return t1 + ( t2 - t1 ) * ( ( 2 / 3 ) - h ) * 6 end
	return t1
end

function exsto.ConvertHSLtoRGB( h, s, l )
	local r, g, b
	if s == 0 then
		r = l * 255
		g = l * 255
		b = l * 255
	else
		local t1, t2
		if l < 0.5 then t2 = l * ( 1 + s )
		else t2 = ( l + s ) - ( s * l )
		end
		
		t1 = 2 * l - t2
		
		r = 255 * hue2RGB( t1, t2, h + ( 1 / 3 ) )
		g = 255 * hue2RGB( t1, t2, h )
		b = 255 * hue2RGB( t1, t2, h - ( 1 / 3 ) )
	end
	
	return Color( math.Round( r ), math.Round( g ), math.Round( b ), 255 )
end

function exsto.ConvertRGBtoHSL( col )
	local h, s
	local r, g, b = col.r / 255, col.g / 255, col.b / 255
	local max, min = math.max( r, g, b ), math.min( r, g, b )
	local delta = max - min
	
	local l = ( max + min ) / 2
	
	if delta == 0 then
		h, s = 0, 0 -- This is gray!
	else
		if l < 0.5 then
			s = max / ( max + min )
		else
			s = max / ( 2 - max - min )
		end
		
		local dR = ( ( ( max - r ) / 6 ) + ( delta / 2 ) ) / delta
		local dG = ( ( ( max - g ) / 6 ) + ( delta / 2 ) ) / delta
		local dB = ( ( ( max - b ) / 6 ) + ( delta / 2 ) ) / delta
		
		if r == max then h = dB - dG
		elseif g == max then h = ( 1 / 3 ) + dR - dB
		elseif b == max then h = ( 2 / 3 ) + dG - dR
		end
		
		if h < 0 then h = h + 1 end
		if h > 1 then h = h - 1 end
	end
	
	return h, s, l
end

-- Color to Text support
CTEXT ={}

for k,v in pairs( COLOR ) do
	CTEXT[tostring( k ):lower()] = v
end

--[[ -----------------------------------
	Function: exsto.CreateColoredPrint
	Description: Returns a table w/ colors for exsto.Print.  Parses str into a table and substitutes color commands for the color table.
	Input: str: String to print.
    ----------------------------------- ]]
function exsto.CreateColoredPrint( str )
	-- Explode our string
	local tbl, strBuffer = string.Explode( " ", str ), ""
	
	-- Loop through to construct our new table.
	local new, clStart, clEnd, clTag, r, g, b, a = {}
	for _, word in ipairs( tbl ) do
		clStart, clEnd, clTag, r, g, b, a = string.find( word, "(%[c=(%d+),(%d+),(%d+),(%d+)%])" )
		if clStart then -- We've found a color.  Input it
			-- Flush strBuffer
			if strBuffer != "" then
				table.insert( new, strBuffer )
				strBuffer = ""
			end
			
			table.insert( new, Color( r, g, b, a ) )
		else -- No color.  Insert string.
			-- But wait, can we throw in one of our COLOR colors?
			clStart, clEnd, clTag, c2 = string.find( word, "(%[c=COLOR,(%u+)%])" )
			if clStart and COLOR[ c2 ] then
				-- Flush strBuffer
				if strBuffer != "" then
					table.insert( new, strBuffer )
					strBuffer = ""
				end
				
				table.insert( new, COLOR[ c2 ] )
			else
				-- Append to the str buffer
				strBuffer = strBuffer .. word .. " " 
			end
		end
	end
	
	table.insert( new, strBuffer )
	return new
end	

--[[ -----------------------------------
	Function: exsto.CreateStringColorPrint
	Description: Converts table returned by exsto.CreateColoredPrint back into a string format.
	Input: tbl: The above
    ----------------------------------- ]]
function exsto.CreateStringColorPrint( tbl )
	local strBuffer = ""
	for _, d in ipairs( tbl ) do
		if type( d ) == "table" then
			strBuffer = strBuffer .. "[c=" .. d.r .. "," .. d.g .. "," .. d.b .. "," .. d.a .. "] "
		else
			strBuffer = strBuffer .. d
		end
	end
	return strBuffer
end

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
	
function exsto.GetClosestString( str, possible, member, ply, text )
	local max, new, dist = 100, ""
	
	for k, v in pairs( possible ) do
		if member then v = v[ member ] end
		
		dist = StringDist( str, v )
		if dist < max then
			max = dist
			new = v
		end
	end
	
	if text and ply then
		ply:Print( exsto_CHAT, COLOR.NORM, text .. " ", COLOR.NAME, str, COLOR.NORM, ".  Maybe you want ", COLOR.NAME, new, COLOR.NORM, "?" )
	end
	
	return new
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
		
		runningLoc = string.Explode( "/", runningLoc )
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
	Input: Minutes
     ----------------------------------- ]]
function exsto.NiceTime( num )
	local int, dec, rec = 0, 0, ""
	
	int, dec = math.modf( num / 60 / 24 / 7 )
	if int > 0 then 
		rec = int .. " weeks, " 
		num = num - ( int * 60 * 24 * 7 )
	end
	
	int, dec = math.modf( num / 60 / 24 )
	if int > 0 then
		rec = rec .. int .. " days, "
		num = num - ( int * 60 * 24 )
	end
	
	int, dec = math.modf( num / 60 )
	if int > 0 then
		rec = rec .. int .. " hours, "
		num = num - ( int * 60 )
	end
	
	return rec .. math.Round( num ) .. " minutes"
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
			"rankeditor", "allowentity", "allowprop", "allowstool", "allowswep", "ban", "banid",
			"denyentity", "denyprop", "denystool", "denyswep", "entspawn", "felbackup", "feldetails", "felsettings", "immunity",
			"rank", "rankid", "server-settings", "banlistdetails", "afkkickignore", "command", "findghosts",
			"playerpickup", "setconvar", "unban", "pluginpage", "nolimitrank", "crcinvalnotify"
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
			"isadmin", "banlist", "mapslist", "adminsay", "blind", "bring", "cannoclip", "changelvl", "chatnotify",
			"chatnotify2", "clear", "color", "count", "decals", "effect", "enter", "exit", "extinguish", "freeze",
			"gag", "ghost", "gimp", "give", "godmode", "goto", "hideadmin", "ignite", "jail", "jumppower", "kick",
			"lookup", "mute", "noclip", "nolimits", "own", "playsound", "pm", "printlogs", "printrestrict", "ragdoll",
			"rave", "reloadmap", "respawn", "returnweps", "rocketman", "runspeed", "say", "seizure", "send",
			"setarmor", "setfrags", "setdeaths", "sethealth", "slap", "slay", "spectate", "stopsounds", "stripweps",
			"teleport", "unlimitedammo", "unmute", "walkspeed"
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
			"helppage", "review", "round", "voteban", "votekick", "voteno", "voteyes", "quickmenu", "settings", "motd"
		} );
		FlagsDeny = von.serialize( {
		} );
	}
}