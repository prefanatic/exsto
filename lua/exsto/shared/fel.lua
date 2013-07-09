--[[
	File Extension Library
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

-- Thanks to rabbish for the cache idea.

FEL = {}
	FEL.Databases = {}
	FEL.DefaultConfig = {
		mysql_user = "name";
		mysql_pass = "pass";
		mysql_database = "main_db";
		mysql_host = "127.0.0.1";
		debug_level = 0;
		mysql_databases = {};
		backup_rates = {};
		time = {
			update = {};
			backup = {};
		};
	}
	FEL.ConfigFile = "fel_settings.txt";
	FEL.TableCache = "fel_tablecache/"
	FEL.BackupDirectory = "fel_backups/";
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

	if !von then
		local s, err = pcall( require, "von" )
		if !s then
			Error( "FEL --> Unable to load 'von'.  FEL cannot operate without this!" )
		end
	end
	
	-- Load our extensions.
	for _, f in ipairs( file.Find( "fel_extensions/*.lua", "LUA" ) ) do
		include( "fel_extensions/" .. f )
		AddCSLuaFile( "fel_extensions/" .. f )
	end
	
	FEL.ConstructLocation();
	FEL.ReadSettingsFile()
	
	-- Check and see if we need MySQL to operate.
	if FEL.MySQLNeeded() and !mysqloo and SERVER then
		local s, err = pcall( require, "mysqloo" )
		if !s then
			ErrorNoHalt( "FEL --> Unable to load 'mysqloo'.  Make the bin is located in lua/bin and libmysql with srcds.\n" )
			ErrorNoHalt( "FEL --> Defaulting to SQLite.\n" )
		end
	end
end

function FEL.ConstructLocation()
	file.CreateDir( "fel" )
	file.CreateDir( FEL.BackupDirectory )
end

function FEL.ReadSettingsFile()

	-- Read a new von encoded format.
	if !file.Exists( FEL.ConfigFile, "DATA" ) then 
		file.Write( FEL.ConfigFile, von.serialize( FEL.DefaultConfig ) )
		FEL.Config = FEL.DefaultConfig
	else
	
		FEL.Config = von.deserialize( file.Read( FEL.ConfigFile ) )
		
		if FEL.Config[ 1 ] == "TableToKeyValue" then -- We're probably on the old util.TableToKeys.  Remove, sorry!
			file.Write( FEL.ConfigFile, von.serialize( FEL.DefaultConfig ) )
			FEL.Config = FEL.DefaultConfig
		end
	end

end

function FEL.SetMySQLInformation( user, pass, db, host )
	FEL.Debug( "Setting MySQL information: " .. tostring( user ) .. ", " .. tostring( pass ) .. ", " .. tostring( db ) .. ", " .. tostring( host ), 1 )
	FEL.Config.mysql_user = user or FEL.Config.mysql_user;
	FEL.Config.mysql_pass = pass or FEL.Config.mysql_pass;
	FEL.Config.mysql_database = db or FEL.Config.mysql_database;
	FEL.Config.mysql_host = host or FEL.Config.mysql_host;
	FEL.SaveSettings();
end	

-- Hardcoded function if this API doesn't have any other methods to set mysql information.  This is just an API, not a handle-all.
-- Developers should implement their own way of setting the mysql information.
local function q( ply )
	if !ply:EntIndex() == 0 and game.IsDedicated() then
		ply:PrintMessage( HUD_PRINTCONSOLE, "This command can only be run on the server console!" )
		return false
	elseif ply:EntIndex() == 0 or ply:IsListenServerHost() then
		return true
	end
end
local function p( msg, ply )
	if ply:EntIndex() == 0 then print( msg ) return end
	ply:PrintMessage( HUD_PRINTCONSOLE, msg )
end
function FEL.HardcodeMySQLSet( ply, _, args )
	if q( ply ) then
		if !args[ 1 ] or !args[ 2 ] or !args[ 3 ] or !args[ 4 ] then
			p( "Invalid arguments!  We need the username, password, database, and the host: in that order.", ply )
			return
		end
		p( "Setting mysql information.", ply )
		FEL.SetMySQLInformation( unpack( args ) )
	end
end
concommand.Add( "FELSetMySQLInformation", FEL.HardcodeMySQLSet )

function FEL.DropTable( ply, _, args )
	if q( ply ) then
		if !args[ 1 ] then
			p( "No table entered!", ply )
			return
		end
		local db = FEL.GetDatabase( args[ 1 ] )
		if not db then
			p( "No table named '" .. args[ 1 ] .. "'", ply )
			return
		end
		p( "Dropping table '" .. db:GetName() .. "'", ply )
		db:Reset();
	end
end
concommand.Add( "FELDropTable", FEL.DropTable )

function FEL.PrintDatabases( ply, _, args )
	if q( ply ) then
		for _, db in pairs( FEL.GetDatabases() ) do
			p( "Database: " .. db:GetName(), ply )
		end
	end
end
concommand.Add( "FELListTables", FEL.PrintDatabases )

function FEL.SaveSettings()
	file.Write( FEL.ConfigFile, von.serialize( FEL.Config ) )
end

function FEL.GetMySQLDatabases()
	local tbl = {}
	for _, db in ipairs( FEL.GetDatabases() ) do
		if table.HasValue( FEL.Config.mysql_databases, db:GetName() ) then table.insert( tbl, db ) end
	end
	return tbl
end

function FEL.AllDatabasesMySQL()
	return #FEL.GetMySQLDatabases() == #FEL.GetDatabases()
end

function FEL.HasMySQLCapacity()	
	if FEL.Config.mysql_user and FEL.Config.mysql_pass and FEL.Config.mysql_database and FEL.Config.mysql_host and mysqloo then return true end
end

function FEL.MySQLNeeded()
	FEL.Debug( "Checking if MySQL is needed.", 2 )

	-- Check our new SQL configuration.  If we've saved one of these databases as MySQL needed, then we fucking need MySQL.
	if #FEL.Config.mysql_databases >= 1 then return true end
	
	return false
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

-- Database metaobject

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
	obj._lastBackup = CurTime()
	obj._forcedLocal = forceLocal
	obj._CacheUpdate = os.time()
	obj.cacheResetRate = 0
	obj.backupRate = 0
	
	if forceLocal then
		obj:Print( "Fix-me: Forcing SQLite databases not through variables." )
	end
	
	table.insert( FEL.Databases, obj )
	hook.Add( "Think", "FELDBTHINK_" .. dbName, function() obj:Think() end )
	hook.Add( "ShutDown", "FELDBSHUTDOWN_" .. dbName, function()
		if obj:IsMySQL() and obj._ExID then
			obj:Query( "DELETE FROM " .. dbName .. "_instances WHERE ExID=" .. obj._ExID .. ";", false )
		end 
	end )
	
	-- Do we need to initiate a MySQL object?
	if obj:RequiresMySQL() and FEL.HasMySQLCapacity() then obj:InitMySQL()
	elseif !FEL.HasMySQLCapacity() and obj:RequiresMySQL() then obj:Error( "We either are missing MySQLoo or key login settings.  Please check your configuration." ) end
	
	-- Set our backup rate.
	local f = false
	for _, tbl in ipairs( FEL.Config.backup_rates ) do
		if tbl[1] == obj:GetName() then obj:SetAutoBackup( tbl[2] ) f = true end
	end
	
	-- Insert into backup rates if we don't already exist.
	if !f then
		table.insert( FEL.Config.backup_rates, { obj:GetName(), 0 } )
	end
	
	-- Insert into our statistic time if not already there.
	local f = false
	for _, tbl in ipairs( FEL.Config.time.update ) do
		if tbl[1] == obj:GetName() then 
			obj:SetLastBackupTime( FEL.Config.time.backup[ _ ][ 2 ] )
			obj:SetLastUpdateTime( tbl[ 2 ] )
			f = true 
		end
	end
	
	if !f then
		table.insert( FEL.Config.time.update, { obj:GetName(), -1 } )
		table.insert( FEL.Config.time.backup, { obj:GetName(), -1 } )
	end
	
	-- Create backup directory
	file.CreateDir( FEL.BackupDirectory .. obj:GetName() .. "/" )
	
	FEL.SaveSettings()
	
	return obj
end

function db:GetLastBackupTime()	return self._LastBackupTime or -1 end
function db:GetLastUpdateTime() return self._LastUpdateTime or -1 end

function db:SetLastBackupTime( t )
	self._LastBackupTime = t;
	
	for _, tbl in ipairs( FEL.Config.time.backup ) do
		if tbl[ 1 ] == self:GetName() then FEL.Config.time.backup[ _ ][ 2 ] = t break end
	end
	
	FEL.SaveSettings();
end
function db:SetLastUpdateTime( t )
	self._LastUpdateTime = t;
	
	for _, tbl in ipairs( FEL.Config.time.update ) do
		if tbl[ 1 ] == self:GetName() then FEL.Config.time.update[ _ ][ 2 ] = t break end
	end
	
	FEL.SaveSettings();
end

function db:GetBackups()
	return file.Find( FEL.BackupDirectory .. self:GetName() .. "/*.txt", "DATA" )
end

function db:RequiresMySQL()
	for _, db in ipairs( FEL.Config.mysql_databases ) do
		if db == self:GetName() then return true end
	end
end

function db:IsMySQL() return self._mysqlSuccess end

-- This WILL NOT take place until the next server restart, for stability reasons.  I'm not to keen for handling this change live.
function db:SetMySQL()
	table.insert( FEL.Config.mysql_databases, self:GetName() )
	FEL.SaveSettings()
end

function db:SetSQLite()
	for indx, db in ipairs( FEL.Config.mysql_databases ) do
		if db == self:GetName() then table.remove( FEL.Config.mysql_databases, indx ) end
	end
	FEL.SaveSettings()
end

function db:Disable( msg )
	self._Disabled = true
	self._DisabledMsg = msg or ""
end

function db:GetName() return self.dbName end
function db:GetDisplayName() return self.displayName or self:GetName() end
function db:SetDisplayName( txt ) self.displayName = txt end

function db:Error( msg )
	exsto.ErrorNoHalt( "[" .. self.dbName .. "-Error] " .. msg )
end

function db:Print( msg )
	FEL.Print( self.dbName .. " --> " .. msg )
end

function db:Debug( msg, level )
	if type( msg ) == "table" then
		table.insert( msg, 1, COLOR.EXSTO )
		table.insert( msg, 2, self.dbName )
		table.insert( msg, 3, COLOR.WHITE )
		table.insert( msg, 4, " --> " )
		FEL.Debug( msg, level )
		return
	end
	FEL.Debug( { COLOR.EXSTO, self.dbName, COLOR.WHITE, " --> " .. msg }, level )
end

function db:InjectInstance()
	-- This is going to create an accessor table, filled with exsto instances using the table.
	-- We will consistantly check this table, and we can use it to push out notifications that we need cache updates.
	self:Query( "CREATE TABLE IF NOT EXISTS " .. self.dbName .. "_instances ( ExID int NOT NULL AUTO_INCREMENT, CacheUpdate int NOT NULL, PRIMARY KEY (ExID) );", true,
		function( q, data )
			self:Query( "INSERT INTO " .. self.dbName .. "_instances (ExID, CacheUpdate) VALUES(NULL, " .. os.time() .. ");", true,
				function( q, data )
					self._ExID = q:lastInsert()
				end 
			)
		end
	)
end

function db:OnMySQLConnect()
	self:Print( "MySQL connected!" )
	self._mysqlSuccess = true
	
	--self:InjectInstance()
	
	if self._AttemptingMySQLReconnect then -- Grab us back into motion.
		self:Query( self._PreMySQLQueryErr, false )
		self._AttemptingMySQLReconnect = nil
		self._PreMySQLQueryErr = nil
	end
end

function db:OnMySQLConnectFail( err )
	-- Handle login errors.  Don't try to reconnect.  No point.  Their information is incorrect, this isn't a timeout.
	if err:find( "Access denied for user" ) then
		self:Error( "MySQL login error.  Are you using the correct login information?" )
		self._mysqlSucces = false
		self._AttemptingMySQLReconnect = nil
		self._forcedLocal = true
		return
	elseif err:find( "Unknown MySQL server" ) then
		self:Error( "MySQL server location unknown.  You probably don't have the correct IP address!" )
		self._mysqlSuccess = false
		self._AttemptingMySQLReconnect = nil
		self._forcedLocal = true
		return
	end
	
	self:Error( "MySQL Error: " .. tostring( err ) )
	self._mysqlSuccess = false
	
	if self._AttemptingMySQLReconnect and self._AttemptingMySQLReconnect > 4 then -- Three times.
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
	self._mysqlDB = mysqloo.connect( FEL.Config.mysql_host, FEL.Config.mysql_user, FEL.Config.mysql_pass, FEL.Config.mysql_database )
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
		Insert = "INSERT OR REPLACE INTO " .. self.dbName .. "(%s) VALUES(%s)";
		InsertDuplicate = "INSERT INTO " .. self.dbName .. " (%s) VALUES (%s) ON DUPLICATE KEY UPDATE %s;";
		DuplicateSet = "%s = VALUES(%s)";
		Set = "%s = %s";
		Delete = "DELETE FROM %s WHERE %s = %s";
	}
	
	-- Commit and create our table!
	self:Debug( "Running table construction query.", 2 )
	self:Query( self:ConstructQuery( "create" ), false )
	
	-- This has become the gayest thing ever.
	if not self._mysqlSuccess then
		self:GetCacheData( false ) -- We want to reimplement the cache on SQLite.
	end
	--self:CheckIntegrity()	
end

function db:SetRefreshRate( time )
	time = tonumber( time )
	if !time then return end
	
	self.cacheResetRate = time
	self:Debug( "Setting cache refresh rate at '" .. time .. "' seconds.", 1 )
end

function db:CacheRefresh( callback )
	self:GetCacheData( true )
	self:QOSCheck()
	
	self:Debug( "Refreshing Cache.", 1 )
end	

local function pass3( self, data, tbl, index, max )
	table.Add( tbl, data )
	
	if index == max then
		self.Cache._cache = self:QOSCheck( table.Copy( tbl ) )
		if self.CacheUpdated then
			self:CacheUpdated()
		end
	end
end

local function pass2( self, data )
	self.Cache._cache = self:QOSCheck( data or {} )
	if self.CacheUpdated then
		self:CacheUpdated()
	end
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
		self:PushSaves()
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
		self:PushSaves()
		self:Think( true )
		
		file.Write( FEL.TableCache .. self.dbName .. "_cache.txt", von.serialize( self.Columns ) )
	end
end	

function db:PurgeCache()
	self:Print( "Clearing cache.", 1 )
	
	-- We need to push any data we have that needs to be saved.
	self:PushSaves()
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
	if style == "insert_duplicate" then
		local query = self.Queries.InsertDuplicate
		
		self._clk = 1
		local count = table.Count( data )
		for column, rowData in pairs( data ) do
			if type( rowData ) == "string" then rowData = self:Escape( rowData ) end
			if self._clk == count then
				query = string.format( query, column, tostring( rowData ), string.format( self.Queries.Set, column, tostring( rowData ) ) )
			else
				query = string.format( query, column .. ", %s", tostring( rowData ) .. ", %s", string.format( self.Queries.Set, column, tostring( rowData ) ) .. ", %s" )
			end
			
			self._clk = self._clk + 1
		end
		
		return query
	elseif style == "new" then
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

function db:QueryEnd( ignoreDebug )
	if ignoreDebug then return end
	self.qTEnd = SysTime();
	self:Debug( "Took '" .. self.qTEnd - self.qTStart .. "' seconds to run this query.", 3 )
end

function db:Query( str, threaded, callback, ignoreDebug )
	if self._Disabled then
		self:Print( "Disabled! " .. self._DisabledMsg )
		return
	end
	hook.Call( "FEL_OnQuery", nil, str, threaded )
	
	-- Debug reasons.
	if not ignoreDebug then
		self.qTStart = SysTime();
		self:Debug( { "Query (mysql: ", COLOR.NAME, tostring( self._mysqlSuccess ), COLOR.WHITE, ", threaded: ", COLOR.NAME, tostring( threaded ), COLOR.WHITE, ") - ", COLOR.GREY, str }, 3 )
	end
	
	if self._mysqlSuccess == true and self._forcedLocal != true then -- We are MySQL baby
		self._mysqlQuery = self._mysqlDB:query( str )
		self._mysqlQuery.onError = function( q, err, qSTR ) self:OnQueryError( err, qSTR ) end
		self._mysqlQuery:start()
		
		if threaded == false then -- If we request not to be threaded.
			self._mysqlQuery:wait()
			self:QueryEnd( ignoreDebug )
			return self._mysqlQuery:getData()
		else
			self:QueryEnd( ignoreDebug )
			if callback then
				self._mysqlQuery.onSuccess = callback
			end
		end
	else
		local result = sql.Query( str .. ";" )
	
		if result == false then
			-- An error, holy buggers!
			self:OnQueryError( sql.LastError() )
			self:QueryEnd( ignoreDebug )
		else
			self:QueryEnd( ignoreDebug )
			if callback then -- Call it.
				callback( str, result )
			end
			return result
		end
	end

end

function db:PushSaves()	
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
	
	self:SetLastUpdateTime( os.time() )
	
	-- Set our notification that sql data has changed.
	if self:IsMySQL() and self._ExID then -- In no case will we NOT have self._ExID due to an error.  If we don't have it, assume the server is hibernating.
		self:Query( "UPDATE " .. self.dbName .. "_instances SET CacheUpdate=".. os.time() .." WHERE ExID=" .. self._ExID .. ";", true )
	end
end

function db:Think()
	if self._Disabled then return end
	if ( CurTime() > self._lastThink + self.thinkDelay ) then

		-- Heartbeat please.
		if self:IsMySQL() and self._forcedLocal != true then 
			self:Query( "SELECT 1 + 1", true, nil, true ) 
			--[[self:Query( "SELECT * FROM " .. self.dbName .. "_instances", true, function( q, data )
				for entry, d in ipairs( data ) do
					if ( d.CacheUpdate > self._CacheUpdate ) and d.ExID != self._ExID then -- Another instance has updated data!  PULL IT IN!
						self:CacheRefresh()
						self._CacheUpdate = d.CacheUpdate

						-- Update our instance to the last update that we received.
						self:Query( "UPDATE " .. self.dbName .. "_instances SET CacheUpdate=" .. d.CacheUpdate .." WHERE ExID=" .. self._ExID .. ";", true )
					end
				end
			end )]]
		end
		
		
		self._lastThink = CurTime()
	end
	
	--[[if ( CurTime() > self._lastRefreshCheck + self.cacheResetRate ) and self.cacheResetRate != 0 then
		self:CacheRefresh()
		self._lastRefreshCheck = CurTime()
	end]]
	
	if ( CurTime() > self._lastBackup + self.backupRate ) and self.backupRate != 0 then
		self:Backup()
		self._lastBackup = CurTime()
	end
end

function db:Escape( str )
	if self:IsMySQL() then return "\"" .. self._mysqlDB:escape( str ) .. "\"" end
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

function db:QOSCheck( data ) -- Quality of Service brother....
	if data == nil then return nil end
	
	local d = data
	local columnTypes = {}
	for column, queryUsed in pairs( self.Columns ) do
		columnTypes[ column ] = self:GetColumnType( column )
	end
	
	for _, slot in ipairs( data ) do
		for column, value in pairs( slot ) do
			if value == "NULL" then
				d[_][ column ] = nil
			end
			
			if columnTypes[ column ] == "number" then
				d[_][ column ] = tonumber( value )
			elseif columnTypes[ column ] == "string" then
				d[_][ column ] = tostring( value )
			end
		end
	end
	return d
end

function db:AddRow( data, callback )
	
	-- I hate you inconsistencies; lets be redundant and check our data vs data types.
	if !self:DataInconsistancies( data ) then return end
	
	if self._mysqlSuccess then
	
		if not callback then
			self:Debug( "No callback given for '" .. self:GetName() .. ":AddRow()'  We are going to thread it anyways!  This 'might' cause issues.", 1 )
		end
		self:Query( self:ConstructQuery( "insert_duplicate", data ), true, callback )
		
	else
	
		-- We have the data we want to save.  Add in what we're missing.
		local pk = self.Columns._PrimaryKey
		local key = data[ pk ]
		local d, slot = nil, nil
		
		if not key then
			self:Error( "No primary key given for data save!  We have NO idea where to put this data. :(" )
			return
		end
		
		for _, row in ipairs( self.Cache._cache ) do
			if key == row[ pk ] then d = row slot = _ break end
		end

		if not d then
			self:Query( self:ConstructQuery( "new", data ), true, function( q, d )
				if callback then
					callback( q, d )
				end
				table.insert( self.Cache._cache, data )
			end )
			return
		end
		-- We have the cached data as d.  Fill in with our given data and save it all.
		for k, v in pairs( data ) do
			d[ k ] = v
		end
		
		-- Update the cache.
		self.Cache._cache[ slot ] = d;

		self:Query( self:ConstructQuery( "new", d ), true, callback )
	end

end

function db:TblInsert( tbl, data )
	tbl[ #tbl + 1 ] = data
end

function db:GetAll( callback )
	if not self._mysqlSuccess then
		if callback then 
			callback( nil, table.Copy( self.Cache._cache ) )
			return
		else
			return table.Copy( self.Cache._cache )
		end
	end
	
	if not callback then
		self:Debug( "No callback on '" .. self:GetName() .. ":GetAll()', we are going to halt the server due to this!", 1 )
		
		return self:Query( "SELECT * FROM " .. self:GetName() .. ";", false )
	end
	
	self:Query( "SELECT * FROM " .. self:GetName() .. ";", true, function( q, d ) callback( q, self:QOSCheck( d ) ) end )
end

function db:ReadAll()
	return self:GetAll()
end

function db:GetRow( key, callback )
	if not self._mysqlSuccess then
		for _, rowData in ipairs( self.Cache._cache ) do
			if key == rowData[ self.Columns._PrimaryKey ] then
				if callback then
					callback( nil, rowData )
					return
				else
					return rowData
				end
			end
		end
		if callback then
			callback( nil, nil )
			return
		else
			return nil
		end
		return
	end
	
	if not callback then
		self:Debug( "No callback on '" .. self:GetName() .. ":GetRow()', we are going to halt the server due to this!", 1 )
		
		return self:Query( "SELECT * FROM " .. self:GetName() .. " WHERE " .. self.Columns._PrimaryKey .. " = '" .. key .. "';", false )
	end
	
	self:Query( "SELECT * FROM " .. self:GetName() .. " WHERE " .. self.Columns._PrimaryKey .. " = '" .. key .. "';", true, function( q, d ) callback( q, self:QOSCheck( d[1] ) ) end )
end

function db:GetData( key, reqs, callback )
	if not self._mysqlSuccess then
		local data = self:GetRow( key )
		
		if !data then return end
		
		local ret = {}
		for _, req in ipairs( string.Explode( ", ", reqs ) ) do
			table.insert( ret, data[ req:Trim() ] )
		end
		
		if callback then
			callback( nil, ret )
		else
			return ret
		end
		return
	end
	
	if not callback then
		self:Debug( "No callback on '" .. self:GetName() .. ":GetData()', we are going to halt the server due to this!", 1 )
		
		return self:Query( "SELECT " .. reqs .. " FROM " .. self:GetName() .. " WHERE " .. self.Columns._PrimaryKey .. " = '" .. key .. "';", false )
	end
	
	self:Query( "SELECT " .. reqs .. " FROM " .. self:GetName() .. " WHERE " .. self.Columns._PrimaryKey .. " = '" .. key .. "';", true, 
		function( q, d )
			callback( q, self:QOSCheck( d and d[1] or nil ) ) 
		end 
	)
end

function db:DropRow( key, callback )
	if not self._mysqlSuccess then
		for _, rowData in ipairs( self.Cache._cache ) do
			if key == rowData[ self.Columns._PrimaryKey ] then 
				table.remove( self.Cache._cache, _ )
			end
		end
	end

	key = type( key ) == "string" and self:Escape( key ) or key
	self:Query( string.format( self.Queries.Delete, self.dbName, self.Columns._PrimaryKey, key ), true, callback )
	
	--[[ Check our queued data
	for _, rowData in ipairs( self.Cache._new ) do
		if key == rowData[ self.Columns._PrimaryKey ] then
			table.remove( self.Cache._new, _ )
		end
	end
	
	for _, rowData in ipairs( self.Cache._changed ) do
		if key == rowData[ self.Columns._PrimaryKey ] then
			table.remove( self.Cache._changed, _ )
		end
	end]]
end

function db:DropTable( threaded )
	self:Query( "DROP TABLE " .. self.dbName, threaded )
end

-- Completely drops and resets the table.
function db:Reset()
	self:Print( "Resetting database!" )
	
	self:DropTable( true )
	self:Query( self:ConstructQuery( "create" ), false )
	
	--[[self:GetCacheData( false )
	self:CheckIntegrity()	
	self:QOSCheck()	]]
end

-- Sets automatic backups as an interval of t
function db:SetAutoBackup( t )
	self.backupRate = t * 60
	
	for _, tbl in ipairs( FEL.Config.backup_rates ) do
		if tbl[ 1 ] == self:GetName() then FEL.Config.backup_rates[ _ ][ 2 ] = self.backupRate end
	end
	FEL.SaveSettings()
end
function db:GetAutoBackupRate() return self.backupRate / 60 end

function db:Backup()
	-- Read our cache.  Use ReadAll instead of GetAll because we aren't changing this data.
	local data = self:ReadAll()
	
	local date = os.date( "%m-%d-%y" )
	local time = tostring( os.date( "%H-%M-%S" ) )
	local loc = FEL.BackupDirectory .. self.dbName .. "/" .. "backup_" .. date .. " " .. time .. ".txt"
	
	-- We don't need it human readable?  Save as von encoded.
	file.Write( loc, von.serialize( data ) )
	
	self:Debug( "Backed up database to: " .. loc, 1 )
	
	self:SetLastBackupTime( os.time() )
end
	
function db:Restore( data )
	-- We should be receiving von serialized data.  Deserialize.
	data = von.deserialize( data )
	if !data then
		self:Debug( "Received non von-serialized data.  Silently backing out.", 1 )
		return false
	end
	
	self:Debug( "Restoring database.", 1 )
	
	self:DropTable( false )
	self.Cache._new = data;
	self:Query( self:ConstructQuery( "create" ), false )
	self:PushSaves()
	self:Think( true )
end

function FEL.GetDatabases()
	return FEL.Databases
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

concommand.Add( "FELCreateMySQL", function( ply, _, args )
	local db = FEL.GetDatabase( args[ 1 ] )
	if !db then return end
	db:SetMySQL()
end )
