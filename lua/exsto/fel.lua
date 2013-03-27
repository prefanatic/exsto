--[[
	File Extension Library
	Copyright (C) 2011  Prefanatic

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

-- Thanks to rabbish for the cache idea.

FEL = {}
	FEL.Databases = {}
	FEL.DefaultConfig = {
		host = "localhost";
		username = "username";
		password = "password";
		database = "database";
		mysql_enabled = "false";
		debug_level = "0";
	}
	FEL.ConfigFile = "fel_settings.txt";
	FEL.TableCache = "fel_tablecache/"
	FEL.KnownDataTypes = { -- Strings == 2, Integer == 1
		CHAR = "string";
		VARCHAR = "string";
		TINYTEXT = "string";
		TEXT = "string";
		MEDIUMTEXT = "string";
		LONGTEXT = "string";
		
		TINYINT = "number";
		SMALLINT = "number";
		MEDIUMINT = "number";
		INT = "number";
		BIGINT = "number";
		FLOAT = "number";
		DOUBLE = "number";
		DECIMAL = "number";
		
		BOOLEAN = "boolean";
	}
	
function FEL.Init()
	-- Load our extensions.
	for _, f in ipairs( file.Find( "fel_extensions/*.lua", "LUA" ) ) do
		include( "fel_extensions/" .. f )
		AddCSLuaFile( "fel_extensions/" .. f )
	end
	
	if !file.Exists( FEL.ConfigFile, "DATA" ) then
		file.Write( FEL.ConfigFile, util.TableToKeyValues( FEL.DefaultConfig ) )
		FEL.Config = FEL.DefaultConfig
	else
		FEL.Config = util.KeyValuesToTable( file.Read( FEL.ConfigFile ) )
	end
	
	if !mysql and FEL.Config.mysql_enabled == "true" and SERVER then
		local s, err = pcall( require, "mysqloo" )
		if !s then
			ErrorNoHalt( "FEL --> Unable to load 'mysqloo'.  Make the bin is located in lua/bin and libmysql with srcds.\n" )
			ErrorNoHalt( "FEL --> Defaulting to SQLite.\n" )
			
			-- Override.
			FEL.Config.mysql_enabled = "false"
		end
	end
end

function FEL.Print( msg )
	print( "FEL --> " .. msg )
end

function FEL.Debug( msg, level )
	if tonumber( FEL.Config.debug_level ) >= level then
		print( "[FELDebug] " .. msg )
	end
end

FEL.Init()

local db = {
	dbName;
	Cache = {};
	thinkDelay = 5;
}
db.__index = db

function FEL.CreateDatabase( dbName, forceLocal )
	local obj = {}
	setmetatable( obj, db )
	
	obj.dbName = dbName
	obj.Cache = { 
		_new = {};
		_changed = {};
		_cache = {};
	}
	obj._LastKey = nil
	obj._lastThink = CurTime()
	obj._lastRefreshCheck = CurTime()
	obj._forcedLocal = forceLocal
	obj.cacheResetRate = 0
	
	if forceLocal then
		obj:Print( "Fix-me: Forcing SQLite databases not through variables." )
	end
	
	table.insert( FEL.Databases, obj )
	hook.Add( "Think", "FELDBTHINK_" .. dbName, function() obj:Think() end )
	
	if FEL.Config.mysql_enabled == "true" and forceLocal != true then -- Connect to a mysql server.
		obj:InitMySQL()
	end
	
	return obj
end

function db:Disable( msg )
	self._Disabled = true
	self._DisabledMsg = msg or ""
end

function db:Error( msg )
	exsto.ErrorNoHalt( "[" .. self.dbName .. "-Error]" .. msg )
end

function db:Print( msg )
	FEL.Print( self.dbName .. " --> " .. msg )
end

function db:Debug( msg, level )
	FEL.Debug( self.dbName .. " --> " .. msg, level )
end

function db:OnMySQLConnect()
	self:Print( "MySQL connected!" )
	self._mysqlSuccess = true
	
	if self._AttemptingMySQLReconnect then -- Grab us back into motion.
		self:Query( self._PreMySQLQueryErr, false )
		self._AttemptingMySQLReconnect = nil
		self._PreMySQLQueryErr = nil
	end
end

function db:OnMySQLConnectFail( err )
	self:Error( "MySQL Error: " .. tostring( err ) )
	self._mysqlSuccess = false
	
	if self._AttemptingMySQLReconnect and self._AttemptingMySQLReconnect > 3 then -- Three times.
		self:Error( "Unable to reconnect to MYSQL.  Forcing SQLite." )
		self._forcedLocal = true
		self._AttemptingMySQLReconnect = nil
		return
	end
	
	self:ReconnectMySQL( self._PreMySQLQueryErr )
end

function db:ReconnectMySQL( lastquery )
	self:Error( "Attempting to reconnect to MySQL." )
	
	self._mysqlSuccess = false
	self._PreMySQLQueryErr = self._PreMySQLQueryErr or lastquery 
	self._AttemptingMySQLReconnect = ( self._AttemptingMySQLReconnect and self._AttemptingMySQLReconnect + 1 ) or 1
	self:InitMySQL()
end

function db:InitMySQL()
	if self._mysqlDB then self._mysqlDB = nil end
	
	self:Debug( "Creating MySQL object.", 2 )
	self._mysqlDB = mysqloo.connect( FEL.Config.host, FEL.Config.username, FEL.Config.password, FEL.Config.database )
	self._mysqlDB:connect()
	self._mysqlDB.onConnected = function( mysqldb ) self:OnMySQLConnect() end
	self._mysqlDB.onConnectionFailed = function( mysqldb, err ) self:OnMySQLConnectFail( err ) end
	self._mysqlDB:wait()
end

function db:ConstructColumns( columnData )
	local formatted = {}
	
	self:Debug( "Creating column data.", 3 )
	for columnName, data in pairs( columnData ) do
		local split = string.Explode( ":", data )
		local clean = ""
		
		for _, str in ipairs( split ) do
			if str == "primary" then
				formatted._PrimaryKey = columnName 
			elseif str == "not_null" then
				clean = clean .. " NOT NULL"
			else
				clean = clean .. str
			end
		end
		
		formatted[ columnName ] = clean
	end
	
	if !formatted._PrimaryKey then
		self:Error( "Unable to construct columns.  No primary key was created." )
		self:Disable( "No primary key was designated under column construction." )
	end

	self.Columns = formatted	
	self.Queries = {
		Create = "CREATE TABLE IF NOT EXISTS " .. self.dbName .. "(%s)";
		Datatypes = "%s %s";
		Update = "UPDATE " .. self.dbName .. " SET %s WHERE " .. formatted._PrimaryKey .. " = %s";
		Insert = "INSERT INTO " .. self.dbName .. "(%s) VALUES(%s)";
		Set = "%s = %s";
		Delete = "DELETE FROM %s WHERE %s = %s";
	}
	
	-- Commit and create our table!
	self:Debug( "Running table construction query.", 2 )
	self:Query( self:ConstructQuery( "create" ), false )
	
	self:GetCacheData( false )
	self:CheckIntegrity()	
	self:QOSCheck()	
end

function db:SetRefreshRate( time )
	time = tonumber( time )
	if !time then return end
	
	self.cacheResetRate = time
	self:Debug( "Setting cache refresh rate at '" .. time .. "' seconds.", 1 )
end

function db:CacheRefresh()
	self:GetCacheData( true )
	self:QOSCheck()
	
	self:Debug( "Refreshing Cache.", 1 )
end	

local function pass3( self, data, tbl, index, max )
	table.Add( tbl, data )
	
	if index == max then
		self.Cache._cache = table.Copy( tbl )
	end
end

local function pass2( self, data )
	self.Cache._cache = data or {}
end

local function pass( self, cacheData, thread )
	self:Debug( "Processing entry count.", 2 )
	
	if cacheData and cacheData[1] and cacheData[1]["COUNT(*)"] then
		self._cacheCount = tonumber( cacheData[1]["COUNT(*)"] )
	end

	if self._cacheCount < 1024 or !self._cacheCount then
		self:Debug( "Need to grab multiple packets.  Number of entries: " .. tostring( self._cacheCount ), 3 )
		
		local data = self:Query( "SELECT * FROM " .. self.dbName, thread, function( q, data ) pass2( self, data ) end ) or {}
		if !threaded then self.Cache._cache = data end
		return
	end
	
	local tmp = {}
	local neededPackets = math.ceil( self._cacheCount / 1000 )
	
	for I = 0, neededPackets - 1 do
		self:Debug( "Grabbing packet '" .. tostring( I ) .. "' out of '" .. tostring( neededPackets - 1 ) .. "'", 3 )
		
		local data = self:Query( "SELECT * FROM " .. self.dbName .. " LIMIT " .. I * 1000 .. ",1000", thread, function( q, data ) pass3( self, data, tmp, I, neededPackets - 1 ) end )
		if !threaded then pass3( self, data, tmp, I, neededPackets - 1 ) end
	end
	
end

-- TODO: This needs to be threaded after loads.
function db:GetCacheData( thread )
	self.Cache._cache = {}
	self._cacheCount = 0
	
	self:Debug( "Threaded: " .. tostring( thread ), 3 )
	
	local data = self:Query( "SELECT COUNT(*) FROM " .. self.dbName, thread, function( q, data ) pass( self, data, thread ) end )
	if !thread then pass( self, data, thread ) end
end

function db:CheckIntegrity()

	local dbLocal = file.Read( FEL.TableCache .. self.dbName .. "_cache.txt", "DATA" )
	if !dbLocal then
		file.Write( FEL.TableCache .. self.dbName .. "_cache.txt", von.serialize( self.Columns ) )
		return
	else
		dbLocal = von.deserialize( dbLocal )
	end
	
	-- Check if the cache is old_fel.
	if type( dbLocal[1] ) == "table" and type( dbLocal[2] ) == "table" then
		print( "FEL --> " .. self.dbName .. " --> Local cache using old FEL!  Updating to support new format." )
		self.Cache._new = table.Copy( self.Cache._cache )
		self:DropTable( false )
		self:Query( self:ConstructQuery( "create" ), false )
		self:Think( true )
		
		file.Write( FEL.TableCache .. self.dbName .. "_cache.txt", von.serialize( self.Columns ) )
		return
	end
	
	self:Debug( "Running cache--database quality check.  Parsing for changes.", 1 )
	
	-- Create a table of our current columns
	local currentColumns = {}
	for column in pairs( self.Columns ) do
		table.insert( currentColumns, column )
	end
	
	-- Create a table of the columns from the table
	local oldColumns = {}
	for column in pairs( dbLocal ) do
		table.insert( oldColumns, column )
	end
	
	local changedData = {}
	
	-- OK, check to see if we need to add any columns.
	for _, column in ipairs( currentColumns ) do
		if !table.HasValue( oldColumns, column ) then table.insert( changedData, { t = "add", c = column, d = self.Columns[ column ] } ) end
	end
	
	-- Now to get rid of.
	for _, column in ipairs( oldColumns ) do
		if !table.HasValue( currentColumns, column ) then table.insert( changedData, { t = "remove", c = column } ) end
	end
	
	-- Check primary keys.
	if !dbLocal._PrimaryKey and self.Columns._PrimaryKey then
		table.insert( changedData, { t = "pk", c = self.Columns._PrimaryKey } )
	end
	
	-- Commit brother!
	if table.Count( changedData ) > 0 then
	
		self:Debug( "Databases changes found.  Dropping and reconstructing.", 1 )
		self:Debug( "List of removals:", 2 )
		
		for _, d in ipairs( changedData ) do
			self:Debug( " --     " .. d.t .. " : " .. tostring( d.c ), 2 )
		end

		-- Screw this.  Drop and update.
		
		self.Cache._new = table.Copy( self.Cache._cache )
		self:DropTable( false )
		self:Query( self:ConstructQuery( "create" ), false )
		self:Think( true )
		
		file.Write( FEL.TableCache .. self.dbName .. "_cache.txt", von.serialize( self.Columns ) )
	end
end	

function db:PurgeCache()
	self:Print( "Clearing cache.", 1 )
	
	-- We need to push any data we have that needs to be saved.
	self:Think( true )
	
	self:GetCacheData()
	self:CheckIntegrity()	
	self:QOSCheck()	
end

function db:CheckCache( id, data )
	self._LastKey = nil
	for _, cached in ipairs( self.Cache[ id ] ) do
		if cached[ self.Columns._PrimaryKey ] == data[ self.Columns._PrimaryKey ] then
			self._LastKey = _
			return true
		end
	end
end

function db:ConstructQuery( style, data )
	if style == "new" then
		local query = self.Queries.Insert
		
		self._clk = 1
		local count = table.Count( data )
		for column, rowData in pairs( data ) do
			if type( rowData ) == "string" then rowData = self:Escape( rowData ) end
			if self._clk == count then 
				query = string.format( query, column, rowData )
			else
				query = string.format( query, column .. ", %s", tostring( rowData ) .. ", %s" )
			end
			
			self._clk = self._clk + 1
		end
		
		return query
	elseif style == "changed" then
		local query = string.format( self.Queries.Update, "%s", type( data[ self.Columns._PrimaryKey ] ) == "string" and self:Escape( data[ self.Columns._PrimaryKey ] ) or data[ self.Columns._PrimaryKey ] )
		
		self._clk = 1
		local count = table.Count( data )
		for column, rowData in pairs( data ) do
			if type( rowData ) == "string" then rowData = self:Escape( rowData ) end
			if self._clk == count then
				query = string.format( query, string.format( self.Queries.Set, column, rowData ) )
			else
				query = string.format( query, string.format( self.Queries.Set, column, rowData ) .. ", %s" )
			end
			
			self._clk = self._clk + 1
		end
		
		return query
	elseif style == "create" then
		local query = self.Queries.Create
		local columns = table.Copy( self.Columns )
			columns._PrimaryKey = nil
		
		self._clk = 1
		local count = table.Count( columns )
		for column, dataType in pairs( columns ) do
			if self._clk == count then
				query = string.format( query, string.format( self.Queries.Datatypes, column, dataType ) .. ", PRIMARY KEY( " .. self.Columns._PrimaryKey .. " )" )
			else
				query = string.format( query, string.format( self.Queries.Datatypes, column, dataType ) .. ", %s" )
			end
			
			self._clk = self._clk + 1
		end
		
		return query
	end
end

function db:OnQueryError( err, query )
	self:Error( "SQL Error: " .. err )
	
	-- Check and make sure the MySQL server hasn't gone away.  :(
	if string.find( err:lower(), "has gone away" ) and !self._AttemptingMySQLReconnect then
		self:ReconnectMySQL( query )
	end		
end

function db:Query( str, threaded, callback )
	if self._Disabled then
		self:Print( "Disabled! " .. self._DisabledMsg )
		return
	end
	hook.Call( "FEL_OnQuery", nil, str, threaded )
	
	self:Debug( "Query (mysql :" .. tostring( self._mysqlSuccess ) .. ", threaded: " .. tostring( threaded ) .. ") - " .. str, 3 )
	
	if self._mysqlSuccess == true and self._forcedLocal != true then -- We are MySQL baby
		self._mysqlQuery = self._mysqlDB:query( str )
		self._mysqlQuery.onError = function( query, err ) self:OnQueryError( err, query ) end
		self._mysqlQuery:start()
		
		if threaded == false then -- If we request not to be threaded.
			self._mysqlQuery:wait()
			return self._mysqlQuery:getData()
		else
			if callback then
				self._mysqlQuery.onSuccess = callback
			end
		end
	else
		local result = sql.Query( str .. ";" )
	
		if result == false then
			-- An error, holy buggers!
			self:OnQueryError( sql.LastError() )
		else
			if callback then -- Call it.
				callback( str, result )
			end
			return result
		end
	end
end

function db:Think( force )
	if self._Disabled then return end
	if ( CurTime() > self._lastThink + self.thinkDelay ) or force then
		if FEL.Config.mysql_enabled == "true" and self._mysqlSuccess != true and self._mysqlSuccess != false and self._forcedLocal != true then -- Wait.  Just queue up;
			self._lastThink = CurTime()
			return
		end
		
		if #self.Cache._changed > 0 then -- Hoho we have some changes!
			for _, rowData in ipairs( self.Cache._changed ) do
				self:Query( self:ConstructQuery( "changed", rowData ), true )
			end
			
			self.Cache._changed = {}
		end
		
		if #self.Cache._new > 0 then
			for _, rowData in ipairs( self.Cache._new ) do
				self:Query( self:ConstructQuery( "new", rowData ), true )
			end
			
			self.Cache._new = {}
		end
		
		-- Heartbeat please.
		if FEL.Config.mysql_enabled == "true" and self._forcedLocal != true then self:Query( "SELECT 1 + 1", true ) end
		
		self._lastThink = CurTime()
	end
	
	if ( CurTime() > self._lastRefreshCheck + self.cacheResetRate ) and self.cacheResetRate != 0 then
		self:CacheRefresh()
		self._lastRefreshCheck = CurTime()
	end
end

function db:Escape( str )
	if FEL.Config.mysql_enabled == "true" and self._forcedLocal != true then return "\"" .. self._mysqlDB:escape( str ) .. "\"" end
	return SQLStr( str )
end

function db:GetColumnType( column )
	local colQuery = self.Columns[ column ]
	
	if !colQuery then
		self:Error( "Unknown column '" .. column .. " accessed." )
	end
	
	for t, nT in pairs( FEL.KnownDataTypes ) do
		if colQuery:Left( t:len() ) == t then return nT end
	end
	return "null"
end

function db:DataInconsistancies( data )
	-- We need to have tables for this containing all possible data, and fkjasdfoisdfijsdfoisdf
	for column, value in pairs( data ) do
		local dt = self:GetColumnType( column )

		if type( value ):lower() != dt:lower() then 
			self:Error( "Supplied value '" .. tostring( value ) .. "' is not consistent with '" .. dt .. "' under column '" .. column .. "'" )
			return
		end
	end

	return true
end

function db:QOSCheck() -- Quality of Service brother....
	local columnTypes = {}
	for column, queryUsed in pairs( self.Columns ) do
		columnTypes[ column ] = self:GetColumnType( column )
	end
	
	for _, slot in ipairs( self.Cache._cache ) do
		for column, value in pairs( slot ) do
			if columnTypes[ column ] == "number" then
				self.Cache._cache[ _ ][ column ] = tonumber( value )
			elseif columnTypes[ column ] == "string" then
				self.Cache._cache[ _ ][ column ] = tostring( value )
			end
		end
	end
end

function db:AddRow( data, options )
	options = options or {}
	
	-- I hate you inconsistencies; lets be redundant and check our data vs data types.
	if !self:DataInconsistancies( data ) then return end
	
	-- Check our _new and _changed first brother.
	if self:CheckCache( "_new", data ) then
		table.Merge( self.Cache._new[ self._LastKey ], data )
		if #player.GetHumans() == 0 then self:Think( true ) end
		return
	elseif self:CheckCache( "_changed", data ) then
		table.Merge( self.Cache._changed[ self._LastKey ], data )
		if #player.GetHumans() == 0 then self:Think( true ) end
		return
	end
		
	if self:CheckCache( "_cache", data ) then
		if options.Update == false then return end	
		table.Merge( self.Cache._cache[ self._LastKey ], data )		
		self:TblInsert( self.Cache._changed, data )
		if #player.GetHumans() == 0 then self:Think( true ) end
		return
	else
		self:TblInsert( self.Cache._cache, data )
		self:TblInsert( self.Cache._new, data )
		if #player.GetHumans() == 0 then self:Think( true ) end
	end
end

function db:TblInsert( tbl, data )
	tbl[ #tbl + 1 ] = data
end

function db:GetAll()
	return table.Copy( self.Cache._cache )
end

-- Different from db:GetAll().  Just returns a reference table instead of a copied table.  Not as intensive, for use in think hooks.
function db:ReadAll()
	return self.Cache._cache
end

function db:GetRow( key )
	for _, rowData in ipairs( self.Cache._cache ) do
		if key == rowData[ self.Columns._PrimaryKey ] then return rowData end
	end
end

function db:GetData( key, reqs )
	local data = self:GetRow( key )
	
	if !data then return end
	
	local ret = {}
	for _, req in ipairs( string.Explode( ", ", reqs ) ) do
		table.insert( ret, data[ req:Trim() ] )
	end
	
	return unpack( ret )
end

function db:DropRow( key )
	for _, rowData in ipairs( self.Cache._cache ) do
		if key == rowData[ self.Columns._PrimaryKey ] then 
			table.remove( self.Cache._cache, _ )
			
			key = type( key ) == "string" and self:Escape( key ) or key
			self:Query( string.format( self.Queries.Delete, self.dbName, self.Columns._PrimaryKey, key ), true )
			break
		end
	end
	
	-- Check our queued data
	for _, rowData in ipairs( self.Cache._new ) do
		if key == rowData[ self.Columns._PrimaryKey ] then
			table.remove( self.Cache._new, _ )
		end
	end
	
	for _, rowData in ipairs( self.Cache._changed ) do
		if key == rowData[ self.Columns._PrimaryKey ] then
			table.remove( self.Cache._changed, _ )
		end
	end
end

function db:DropTable( threaded )
	self:Query( "DROP TABLE " .. self.dbName, threaded )
end

--[[ -----------------------------------
	Function: FEL.GetDatabase
	Description: Returns the database object.
     ----------------------------------- ]]
function FEL.GetDatabase( name )
	for _, obj in ipairs( FEL.Databases ) do
		if obj.dbName == name then return obj end
	end
	return nil
end

--[[ -----------------------------------
	Function: FEL.GetObjectFromMySQL
	Description: Returns db object from a mysql database object.
     ----------------------------------- ]]
function FEL.GetObjectFromMySQL( db )
	for _, obj in ipairs( FEL.Databases ) do
		if obj._mysqlDB and obj._mysqlDB == db then return obj end
	end
	return nil
end

--[[ -----------------------------------
	Function: FEL.NiceColor
	Description: Makes a color nice.
     ----------------------------------- ]]
function FEL.NiceColor( color )
	return "[c=" .. color.r .. "," .. color.g .. "," .. color.b .. "," .. color.a .. "]"
end

--[[ -----------------------------------
	Function: FEL.MakeColor
	Description: Makes a nice color a color.
     ----------------------------------- ]]
function FEL.MakeColor( str )
	local startCol, endCol, r, g, b, a = string.find( str, "%[c=(%d+),(%d+),(%d+),(%d+)%]" )
	if startCol then
		return Color( tonumber( r ), tonumber( g ), tonumber( b ), tonumber( a ) )
	else
		return Color( 255, 255, 255, 255 )
	end
end

--[[ -----------------------------------
	Function: FEL.NiceEncode
	Description: Encodes a table to a readable string.
     ----------------------------------- ]]
function FEL.NiceEncode( data )
	
	local form = type( data )
	local encoded = "[form=" .. form .. "]";
	local oldData = data
	
	if form == "Vector" then
		data = {}
			data[1] = oldData.x
			data[2] = oldData.y
			data[3] = oldData.z
	elseif form == "Angle" then
		data = {}
			data[1] = oldData.p
			data[2] = oldData.y
			data[3] = oldData.r
	end

	if !type( data ) == "table" then ErrorNoHalt( "Unknown data format!" ) return end
	
	local index = 0
	local stringIndex = false
	local cur = 1
	for k,v in pairs( data ) do

		index = cur
		if type( k ) == "string" then index = k stringIndex = true end
		encoded = encoded .. "["..index.."]" .. tostring( v )
		
		cur = cur +1
	end
	encoded = encoded .. "[/form, " .. index .. ", " .. tostring( stringIndex ) .. "]"
	
	return encoded
end

--[[ -----------------------------------
	Function: FEL.NiceDecode
	Description: Decodes a nice string into a table
     ----------------------------------- ]]
function FEL.NiceDecode( str )
	
	local startPos, endPos, startTag, form = string.find( str, "(%[form=(%a+)%])" )
	local endStart, endEnd, endTag, count, stringIndex = string.find( str, "(%[/form, (%d+), (%a+)%])" )
	
	if !startPos or !endStart then
		ErrorNoHalt( "FEL --> Couldn't decode, no START found!\n" .. str )
		return
	end
	
	if !form then ErrorNoHalt( "FEL --> Couldn't locate decoding form!\n" .. str ) return end
	if !stringIndex then ErrorNoHalt( "Couldn't tell if decoding a stringed index!\n" .. str ) return end
	if !count then ErrorNoHalt( "Couldn't count the amount of data in the encoded string!\n" .. str ) return end
	
	count = tonumber( count )
	stringIndex = tobool( stringIndex )

	local sub = string.sub( str, endPos + 1, endStart - 1 )
	local data = {}
	
	for k,v in string.gmatch( sub, "%[([%d%%.]+)%]([%a%d-%._]+)" ) do
		if !stringIndex then
			data[tonumber(k)] = v
		else
			data[k] = v
		end
	end

	if form == "table" then 
		return data
	elseif form == "Vector" then
		return Vector( data[1], data[2], data[3] )
	elseif form == "Angle" then
		return Angle( data[1], data[2], data[3] )
	end
	
	return data
	
end

--[[ -----------------------------------
	Function: FEL.FindTableDifference
	Description: Finds a difference in a table.
     ----------------------------------- ]]
function FEL.FindTableDifference( original, new )

	local addTo = {}
	
	local tableChanged = false
	
	-- First, we need to check the original to see if hes missing any from new.
	for k,v in pairs( original ) do
		if !table.HasValue( new, k ) then
			tableChanged = true
			-- Hes missing a flag!
			addTo[k] = v
		end
	end
	
	if tableChanged then	
		return addTo
	end

end

--[[ -----------------------------------
	Function: FEL.LoadSettingsFile
	Description: Loads a file with settings in it.
     ----------------------------------- ]]
function FEL.LoadSettingsFile( id )
	
	if file.Exists( id .. ".txt", "DATA" ) then
		
		local data = file.Read( id .. ".txt", "DATA" ):Trim()

		local strStart, strEnd, strType = string.find( data, "%[settings%s-=%s-\"([%w%s%p]-)\"%]" )
		local endStart, endEnd = string.find( data, "%[/settings%]" )
		
		if !strStart or !endStart then exsto.ErrorNoHalt( "FEL --> Error loading " .. id .. ".  No settings start!" ) return end
		
		local sub = string.sub( data, strEnd + 1, endStart - 1 ):Trim()
		local capture = string.gmatch( sub, "([%w%p]+)%s+=%s+([%w%p]+)" )
		
		local tbl = {}
		for k,v in capture do
			local type = exsto.ParseVarType( v:Trim() )
			tbl[k:Trim()] = exsto.FormatValue( v:Trim(), type )
		end
		
		return tbl
		
	else
		return {}
	end
	
end

--[[ -----------------------------------
	Function: FEL.CreateSettingsFile
	Description: Creates a .txt settings file.
     ----------------------------------- ]]
function FEL.CreateSettingsFile( id, tbl )
	local readData	
	local header = "[settings = \"" .. id .. "\"]"
	local body = ""
	local footer = "[/settings]"

	for k,v in pairs( tbl ) do
		body = body .. k .. " = " .. tostring( v ) .. "\n"
	end
	
	local data = header .. "\n" .. body .. footer
	
	file.Write( id .. ".txt", data )
end

function FEL.PurgeDataCache( ply, _, args )
	if ply:IsSuperAdmin() or ply:EntIndex() == 0 then
		for _, db in ipairs( FEL.Databases ) do
			if db.dbName == args[1] then db:PurgeCache() break end
		end
	end
end
concommand.Add( "FELPurgeCache", FEL.PurgeDataCache )