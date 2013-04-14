local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Database Settings",
	ID = "felsettings",
	Desc = "Database Settings",
	Owner = "Prefanatic",
} )

if SERVER then

	function PLUGIN:Init()
		util.AddNetworkString( "ExRequestDatabaseList" )
		util.AddNetworkString( "ExSendDatabaseList" )
		util.AddNetworkString( "ExSetMySQLDB" )
		util.AddNetworkString( "ExRequestDatabaseBackups" )
		util.AddNetworkString( "ExSendBackupList" )
		util.AddNetworkString( "ExBackupDatabase" )
		util.AddNetworkString( "ExRestoreDatabase" )
		util.AddNetworkString( "ExDeleteBackup" )
		util.AddNetworkString( "ExBackupRate" )
		util.AddNetworkString( "ExResetDB" )
	
	end

	function PLUGIN:RequestDatabases( reader )
		local ply = reader:ReadSender()
		
		self:Debug( "Sending database list to '" .. ply:Nick() .. "'", 1 )
		
		local sender = exsto.CreateSender( "ExSendDatabaseList", ply )
			sender:AddShort( #FEL.GetDatabases() )
		for _, obj in ipairs( FEL.GetDatabases() ) do
			sender:AddString( obj:GetName() )
			sender:AddBoolean( obj:IsMySQL() )
		end
		
		sender:Send()
	end
	PLUGIN:CreateReader( "ExRequestDatabaseList", PLUGIN.RequestDatabases )
	
	function PLUGIN:SetMySQL( reader )
		local ply = reader:ReadSender()
		local db = FEL.GetDatabase( reader:ReadString() )
		local status = reader:ReadBoolean()
		
		self:Debug( "Setting '" .. db:GetName() .. "' as mysql '" .. tostring( status ) .. "' by player '" .. ply:Nick() .. "'", 1 )
		
		if status then print( "setmysql" ) db:SetMySQL() else db:SetSQLite() end
	end
	PLUGIN:CreateReader( "ExSetMySQLDB", PLUGIN.SetMySQL )
	
	function PLUGIN:RequestBackupList( reader )
		local ply = reader:ReadSender()
		local obj = FEL.GetDatabase( reader:ReadString() )
		
		if !obj then return end
		self:Debug( "Sending backup list to '" .. ply:Nick() .. "'", 1 )

		local sender = exsto.CreateSender( "ExSendBackupList", ply )

		sender:AddShort( obj:GetAutoBackupRate() )
		sender:AddShort( #obj:GetBackups() )
		for _, f in ipairs( obj:GetBackups() ) do
			sender:AddString( f )
			sender:AddString( os.date( "%d.%m.%Y", file.Time( FEL.BackupDirectory .. obj:GetName() .. "/" .. f, "DATA" ) ) )
		end
		
		sender:Send()
	end
	PLUGIN:CreateReader( "ExRequestDatabaseBackups", PLUGIN.RequestBackupList )
	
	function PLUGIN:SetAutoBackupRate( reader )
		local ply = reader:ReadSender()
		local db = FEL.GetDatabase( reader:ReadString() )
		local rate = reader:ReadShort()
		
		if !db then return end
		self:Debug( "Setting '" .. db:GetName() .. "' autobackup rate to '" .. rate .. "'" , 1 )
		db:SetAutoBackup( rate )
	end
	PLUGIN:CreateReader( "ExBackupRate", PLUGIN.SetAutoBackupRate )

	function PLUGIN:BackupDatabase( reader )
		local ply = reader:ReadSender()
		local db = FEL.GetDatabase( reader:ReadString() )
		
		if !db then return end
		self:Debug( "Backing up database '" .. db:GetName() .. "' triggered by '" .. ply:Nick() .. "'", 1 )
		
		db:Backup()
	end
	PLUGIN:CreateReader( "ExBackupDatabase", PLUGIN.BackupDatabase )
	
	function PLUGIN:RestoreDatabase( reader )
		local ply = reader:ReadSender()
		local db = FEL.GetDatabase( reader:ReadString() )
		local fLoc = reader:ReadString()
		
		if !db then return end
		self:Debug( "Restoring database '" .. db:GetName() .. "' triggered by '" .. ply:Nick() .. "'", 1 )
		
		local d = file.Read( FEL.BackupDirectory .. db:GetName() .. "/" .. fLoc )
		if !d then
			self:Debug( "Unable to open file '" .. fLoc .. "'", 1 )
			return
		end
		
		db:Restore( d )
		game.ConsoleCommand( "changelevel " .. string.gsub( game.GetMap(), ".bsp", "" ) .. "\n" )
	end
	PLUGIN:CreateReader( "ExRestoreDatabase", PLUGIN.RestoreDatabase )
	
	function PLUGIN:DeleteBackup( reader )
		local ply = reader:ReadSender()
		local db = FEL.GetDatabase( reader:ReadString() )
		local fLoc = reader:ReadString()
		
		if !db then return end
		self:Debug( "Deleting database backup '" .. fLoc .. "' for db '" .. db:GetName() .. "' triggered by '" .. ply:Nick() .. "'", 1 )
		
		file.Delete( FEL.BackupDirectory .. db:GetName() .. "/" .. fLoc )
	end
	PLUGIN:CreateReader( "ExDeleteBackup", PLUGIN.DeleteBackup )

end

if CLIENT then

	local function invalidate( cont )
		local pnl = cont.Content
		if !pnl then PLUGIN:Error( "Oh no!  Attempted to access invalid page contents." ) return end
		
		pnl.List:SetDirty( true )
		pnl.List:InvalidateLayout( true )
		
		pnl.List:SizeToContents()
		
		pnl.Cat:InvalidateLayout( true )
	end
	
	local function refreshDatabaseList( dbs )
		local pnl = PLUGIN.MainPage.Content
		if !pnl then return end
		
		pnl.List:Clear()
		for _, data in ipairs( dbs ) do
			pnl.List:AddRow( { data.db }, data )
		end
		
		invalidate( PLUGIN.MainPage )
	end
	
	local function requestDatabaseList( page )
		PLUGIN:Debug( "Requesting database list from server.", 1 )
		exsto.CreateSender( "ExRequestDatabaseList" ):Send()
	end
	
	local function receiveDatabaseList( reader )
		local tbl = {}
		for I = 1, reader:ReadShort() do
			table.insert( tbl, { db = reader:ReadString(), mysql = reader:ReadBoolean() } )
		end
		refreshDatabaseList( tbl )
	end
	exsto.CreateReader( "ExSendDatabaseList", receiveDatabaseList )
	
	local function pageInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Databases" )
		
		pnl.List = vgui.Create( "ExListView", pnl.Cat )
			pnl.List:DockMargin( 4, 0, 4, 0 )
			pnl.List:Dock( TOP )
			pnl.List:DisableScrollbar()
			pnl.List:AddColumn( "" )
			pnl.List:SetHideHeaders( true )
			pnl.List:SetQuickList()
			
		pnl.List.LineSelected = function( lst, disp, data, obj )
			PLUGIN.WorkingDB = data
			exsto.Menu.EnableBackButton()
			exsto.Menu.OpenPage( PLUGIN.DetailsPage )
		end
	
		invalidate( PLUGIN.MainPage )
	end
	
	local function showtimeDetails( page )
		local pnl = page.Content
		
		pnl.Cat.Header:SetText( PLUGIN.WorkingDB.db )
		pnl.MySQL:SetValue( PLUGIN.WorkingDB.mysql )
		
		if PLUGIN.WorkingDB.db == "Global" then
			pnl.MySQL:SetValue( FEL.AllDatabasesMySQL() )
		end
	end
	
	local function detailsInit( pnl )
		pnl.Cat = pnl:CreateCategory( "%DATABASE" )
		
		-- Our options.
		pnl.BackupRestore = vgui.Create( "ExQuickButton", pnl.Cat )
			pnl.BackupRestore:Text( "Backup/Restore" )
			pnl.BackupRestore:Dock( TOP )
			pnl.BackupRestore:SetQuickMenu()
			pnl.BackupRestore:SetTall( 32 )
			pnl.BackupRestore.DoClick = function()
				exsto.Menu.OpenPage( PLUGIN.BackupPage )
			end
			
		pnl.MySQL = vgui.Create( "ExBooleanChoice", pnl.Cat )
			pnl.MySQL:Text( "MySQL Enabled" )
			pnl.MySQL:Dock( TOP )
			pnl.MySQL:SetQuickMenu()
			pnl.MySQL:SetTall( 32 )
			pnl.MySQL.OnClick = function( o, val )
				if PLUGIN.WorkingDB.db == "Global" then
					pnl:GetObject():Alert( string.format( "This will set EVERY database to %s.  Any %s data will not transfer over, and the server will need to be restarted in order for this to take effect.  Are you sure?", val and "MySQL" or "SQLite", val and "SQLite" or "MySQL" ),
						function()
						
						end, function() o:SetValue( !val ) end )
				else
					pnl:GetObject():Alert( string.format( "Are you sure you want to set this database to %s?  Any data currently in %s will not transfer over, and you will need to restart the server.", val and "MySQL" or "SQLite", val and "SQLite" or "MySQL" ),
						function()
							local sender = exsto.CreateSender( "ExSetMySQLDB" )
								sender:AddString( PLUGIN.WorkingDB.db )
								sender:AddBoolean( val )
							sender:Send()
						end, function() o:SetValue( !val ) end )
				end
			end
			
		--[[pnl.Edit = vgui.Create( "ExQuickButton", pnl.Cat )
			pnl.Edit:Text( "Edit" )
			pnl.Edit:Dock( TOP )
			pnl.Edit:SetQuickMenu()
			pnl.Edit:SetTall( 32 )]]
			
		pnl.Recover = vgui.Create( "ExQuickButton", pnl.Cat )
			pnl.Recover:Text( "Recover" )
			pnl.Recover:Dock( TOP )
			pnl.Recover:SetQuickMenu()
			pnl.Recover:SetTall( 32 )
			
		pnl.Reset = vgui.Create( "ExQuickButton", pnl.Cat )
			pnl.Reset:Text( "Reset" )
			pnl.Reset:Dock( TOP )
			pnl.Reset:SetQuickMenu()
			pnl.Reset:SetTall( 32 )
			pnl.Reset:SetEvil()
			pnl.Reset.OnClick = function( o )
				pnl:GetObject():Alert( "Warning!  This will completely delete all the data in the table.  Are you absolutely sure you want to do this?", 
					function()
						local sender = exsto.CreateSender( "ExResetDB" )
							sender:AddString( PLUGIN.WorkingDB.db )
						sender:Send()
					end
				)
			end

		pnl.Cat:InvalidateLayout( true )
	end
	
	local function backFunction( obj )
		exsto.Menu.OpenPage( PLUGIN.MainPage )
		exsto.Menu.DisableBackButton()
		
		PLUGIN.WorkingDB = "%DATABASE"
	end
	
	local function backBackupFunction( obj )
		exsto.Menu.OpenPage( PLUGIN.DetailsPage )
	end
	
	local function refreshBackupList( dbs )
		local pnl = PLUGIN.BackupPage.Content
		if !pnl then return end
		
		pnl.List:Clear()
		pnl.RestoreSelected = nil
		for _, data in ipairs( dbs ) do
			pnl.List:AddRow( { data.db, data.time }, data )
		end
		print( "BACKUP ", PLUGIN.WorkingDB.autoBackup )
		pnl.AutoBackup:SetValue( PLUGIN.WorkingDB.autoBackup )

		invalidate( PLUGIN.BackupPage )
	end
	
	local function requestBackupList( page )
		PLUGIN:Debug( "Requesting backup list from server.", 1 )
		local sender = exsto.CreateSender( "ExRequestDatabaseBackups" )
			sender:AddString( PLUGIN.WorkingDB.db )
		sender:Send()
	end
	
	local function receiveBackupsList( reader )
		local tbl = {}
		PLUGIN.WorkingDB.autoBackup = reader:ReadShort()
		for I = 1, reader:ReadShort() do -- Per 
			table.insert( tbl, { db = reader:ReadString(), time = reader:ReadString() } )
		end
		refreshBackupList( tbl )
	end
	exsto.CreateReader( "ExSendBackupList", receiveBackupsList )
	
	local function restoreSelected( pnl )
		pnl:GetObject():Alert( "You have selected to restore a backup!  This will erase all the contents existing in the database.  The server will also reload promptly after the restore has complete.  Are you sure?",
			function()
				local sender = exsto.CreateSender( "ExRestoreDatabase" )
					sender:AddString( PLUGIN.WorkingDB.db )
					sender:AddString( pnl.RestoreSelected.db )
				sender:Send()
			end
		)
	end
	
	local function backupInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Backup/Restore" )
		
		pnl.List = vgui.Create( "ExListView", pnl.Cat )
			pnl.List:DockMargin( 4, 0, 4, 0 )
			pnl.List:Dock( TOP )
			pnl.List:DisableScrollbar()
			pnl.List:AddColumn( "" )
			pnl.List:AddColumn( "" )
			pnl.List:SetHideHeaders( true )
			pnl.List.LineSelected = function( o, disp, data, obj )
				pnl.RestoreSelected = data
			end
			pnl.List.OnRowRightClick = function( o, id, l )
				local menu = DermaMenu()
					menu:AddOption( "Restore", function() restoreSelected( pnl ) end )
					menu:AddOption( "Delete", function()
						local sender = exsto.CreateSender( "ExDeleteBackup" )
							sender:AddString( PLUGIN.WorkingDB.db )
							sender:AddString( pnl.RestoreSelected.db )
						sender:Send()
						local sender = exsto.CreateSender( "ExRequestDatabaseBackups" )
							sender:AddString( PLUGIN.WorkingDB.db )
						sender:Send()
					end )
			end
			
		pnl.Restore = vgui.Create( "ExQuickButton", pnl.Cat )
			pnl.Restore:Text( "Restore Selected" )
			pnl.Restore:Dock( TOP )
			pnl.Restore.DoClick = function( o )
				if pnl.RestoreSelected then
					restoreSelected( pnl )
				else 
					-- We don't have anything selected.  TODO: Create a file browser to upload from computer.
				end
			end
			
		pnl.Backup = vgui.Create( "ExQuickButton", pnl.Cat )
			pnl.Backup:Text( "Backup" )
			pnl.Backup:Dock( TOP )
			pnl.Backup.DoClick = function( o )
				local sender = exsto.CreateSender( "ExBackupDatabase" )
					sender:AddString( PLUGIN.WorkingDB.db )
				sender:Send()
				local sender = exsto.CreateSender( "ExRequestDatabaseBackups" )
					sender:AddString( PLUGIN.WorkingDB.db )
				sender:Send()
				o:Text( "Backup Complete!" )
				timer.Simple( 2, function() o:Text( "Backup" ) end )
			end 
			
		pnl.AutoBackup = vgui.Create( "ExNumberChoice", pnl.Cat )
			pnl.AutoBackup:Text( "Backup Rate" )
			pnl.AutoBackup:SetMinMax( 0, 100 )
			pnl.AutoBackup:Dock( TOP )
			pnl.AutoBackup:SetTall( 32 )
			pnl.AutoBackup.OnValueSet = function( o, val )
				local sender = exsto.CreateSender( "ExBackupRate" )
					sender:AddString( PLUGIN.WorkingDB.db )
					sender:AddShort( val )
				sender:Send()
			end
			
		invalidate( PLUGIN.BackupPage )
	end
	
	local function infoInit( pnl )
	end
	
	local function infoBackupFunction( obj )
		exsto.Menu.OpenPage( PLUGIN.DetailsPage )
	end
	
	function PLUGIN:Init()
		self.MainPage = exsto.Menu.CreatePage( "felsettings", pageInit )
			self.MainPage:SetTitle( "Databases" )
			self.MainPage:OnShowtime( requestDatabaseList )
	
		self.DetailsPage = exsto.Menu.CreatePage( "feldetails", detailsInit )
			self.DetailsPage:SetTitle( "Details" )
			self.DetailsPage:SetUnaccessable()
			self.DetailsPage:OnShowtime( showtimeDetails )
			self.DetailsPage:SetBackFunction( backFunction )
			
		self.BackupPage = exsto.Menu.CreatePage( "felbackup", backupInit )
			self.BackupPage:SetTitle( "Backup" )
			self.BackupPage:SetUnaccessable()
			self.BackupPage:SetBackFunction( backBackupFunction )
			self.BackupPage:OnShowtime( requestBackupList )
			
		self.MySQLInfoPage = exsto.Menu.CreatePage( "felmysqlinfo", infoInit )
			self.MySQLInfoPage:SetTitle( "Account Information" )
			self.MySQLInfoPage:SetUnaccessable()
			self.MySQLInfoPage:SetBackFunction( infoBackupFunction )
			
	end
	
end

PLUGIN:Register()