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
		
		exsto.CreateFlag( "felsettings", "Allows users to have access to database settings." )
		exsto.CreateFlag( "feldetails", "Allows users access to the database detail subpage." )
		exsto.CreateFlag( "felbackup", "Allows users to the database backup subpage of felsettings." )
	
	end
	
	-- Security!
	function PLUGIN:ExRequestDatabaseList( reader )
		return reader:ReadSender():IsAllowed( "felsettings" )
	end
	function PLUGIN:ExSendDatabaseList( reader )
		return reader:ReadSender():IsAllowed( "felsettings" )
	end
	function PLUGIN:ExSetMySQLDB( reader )
		return reader:ReadSender():IsAllowed( "felsettings" )
	end
	function PLUGIN:ExRequestDatabaseBackups( reader )
		return reader:ReadSender():IsAllowed( "felsettings" )
	end
	function PLUGIN:ExSendBackupList( reader )
		return reader:ReadSender():IsAllowed( "felsettings" )
	end
	function PLUGIN:ExBackupDatabase( reader )
		return reader:ReadSender():IsAllowed( "felsettings" )
	end
	function PLUGIN:ExRestoreDatabase( reader )
		return reader:ReadSender():IsAllowed( "felsettings" )
	end
	function PLUGIN:ExDeleteBackup( reader )
		return reader:ReadSender():IsAllowed( "felsettings" )
	end
	function PLUGIN:ExBackupRate( reader )
		return reader:ReadSender():IsAllowed( "felsettings" )
	end
	function PLUGIN:ExResetDB( reader )
		return reader:ReadSender():IsAllowed( "felsettings" )
	end

	function PLUGIN:RequestDatabases( reader )
		local ply = reader:ReadSender()
		
		self:Debug( "Sending database list to '" .. ply:Nick() .. "'", 1 )
		
		local sender = exsto.CreateSender( "ExSendDatabaseList", ply )
			sender:AddShort( #FEL.GetDatabases() )
		for _, obj in ipairs( FEL.GetDatabases() ) do
			sender:AddString( obj:GetName() )
			sender:AddString( obj:GetDisplayName() )
			sender:AddShort( obj:GetLastBackupTime() )
			sender:AddShort( obj:GetLastUpdateTime() )
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
	
	function PLUGIN:ResetDatabase( reader )
		local ply = reader:ReadSender()
		local db = FEL.GetDatabase( reader:ReadString() )
		
		if !db then return end
		self:Debug( "Resetting database '" .. db:GetName() .. "' triggered by '" .. ply:Nick() .. "'", 1 )
		
		db:Reset()
		game.ConsoleCommand( "changelevel " .. string.gsub( game.GetMap(), ".bsp", "" ) .. "\n" )
	end
	PLUGIN:CreateReader( "ExResetDB", PLUGIN.ResetDatabase )

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
			pnl.List:AddRow( { data.niceDisplay }, data )
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
			table.insert( tbl, { db = reader:ReadString(), niceDisplay = reader:ReadString(), backupTime = reader:ReadShort(), updateTime = reader:ReadShort(), mysql = reader:ReadBoolean() } )
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
		local data = PLUGIN.WorkingDB
		
		PrintTable( data )
		
		pnl.Cat.Header:SetText( data.niceDisplay )
		pnl.MySQL:SetValue( data.mysql )
		pnl.HardName:SetText( data.db )
		
		local date = os.date( "%m-%d-%y", data.updateTime )
		local time = tostring( os.date( "%H:%M:%S", data.updateTime ) )
		if data.updateTime == -1 then date = "never" time = "" end
		pnl.LastUpdated:SetText( "Last Updated: " .. date .. " " .. time )
		
		local date = os.date( "%m-%d-%y", data.backupTime )
		local time = tostring( os.date( "%H:%M:%S", data.backupTime ) )
		if data.backupTime == -1 then date = "never" time = "" end
		pnl.LastBackup:SetText( "Last Backup: " .. date .. " " .. time )

	end
	
	local function detailsInit( pnl )
		pnl.Cat = pnl:CreateCategory( "%DATABASE" )
		pnl.Cat:DockPadding( 4, 4, 4, 4 )
		
		pnl.Cat:CreateSpacer()
		
		pnl.HardName = vgui.Create( "ExText", pnl.Cat )
			pnl.HardName:Dock( TOP )
			pnl.HardName:SetText( "" )
			pnl.HardName:SetTextColor( Color( 0, 180, 255, 255 ) )
			pnl.HardName:SetFont( "ExGenericText18" )
			
		pnl.LastUpdated = vgui.Create( "ExText", pnl.Cat )
			pnl.LastUpdated:Dock( TOP )
			pnl.LastUpdated:SetText( "" )
			pnl.LastUpdated:SetFont( "ExGenericText14" )
			
		pnl.LastBackup = vgui.Create( "ExText", pnl.Cat )
			pnl.LastBackup:Dock( TOP )
			pnl.LastBackup:SetText( "" )
			pnl.LastBackup:SetFont( "ExGenericText14" )
			
		pnl.Cat:CreateSpacer();
		
		pnl.MySQLText = vgui.Create( "ExText", pnl.Cat )
			pnl.MySQLText:Dock( TOP )
			pnl.MySQLText:SetTextColor( Color( 0, 180, 255, 255 ) )
			pnl.MySQLText:SetText( "MySQL" )
			pnl.MySQLText:SetFont( "ExGenericText18" )
		
		pnl.MySQLHelp = vgui.Create( "ExText", pnl.Cat )
			pnl.MySQLHelp:Dock( TOP )
			pnl.MySQLHelp:SetText( "Enables or disables the use of MySQL for this database.  This allows you to share data across servers.  Make sure your MySQL settings are correct before attempting to enable." )
			pnl.MySQLHelp:SetFont( "ExGenericText14" )
			
		pnl.MySQL = vgui.Create( "ExBooleanChoice", pnl.Cat )
			pnl.MySQL:Text( "Status: " )
			pnl.MySQL:Dock( TOP )
			pnl.MySQL:SetQuickMenu()
			pnl.MySQL:SetTall( 40 )
			pnl.MySQL.OnClick = function( o, val )
				pnl:GetObject():Alert( {
					Text = { string.format( "Are you sure you want to set this database to %s?  Any data currently in %s will not transfer over, and you will need to restart the server.", val and "MySQL" or "SQLite", val and "SQLite" or "MySQL" ) },
					Yes = function()
						local sender = exsto.CreateSender( "ExSetMySQLDB" )
							sender:AddString( PLUGIN.WorkingDB.db )
							sender:AddBoolean( val )
						sender:Send()
					end, 
					No = function() o:SetValue( !val ) end 
				} )
			end
			
		pnl.Cat:CreateSpacer()
		
		-- Our options.
		pnl.BackupRestore = vgui.Create( "ExQuickButton", pnl.Cat )
			pnl.BackupRestore:Text( "Backup / Restore" )
			pnl.BackupRestore:Dock( TOP )
			pnl.BackupRestore:SetQuickMenu()
			pnl.BackupRestore.DoClick = function()
				exsto.Menu.OpenPage( PLUGIN.BackupRestorePage )
			end
			
		pnl.Recover = vgui.Create( "ExQuickButton", pnl.Cat )
			pnl.Recover:Text( "Recover" )
			pnl.Recover:Dock( TOP )
			pnl.Recover:SetQuickMenu()
			
		pnl.Reset = vgui.Create( "ExQuickButton", pnl.Cat )
			pnl.Reset:Text( "Reset" )
			pnl.Reset:Dock( TOP )
			pnl.Reset:SetQuickMenu()
			pnl.Reset:SetEvil()
			pnl.Reset.OnClick = function( o )
				pnl:GetObject():Alert( {
					Text = { COLOR.NAME, "Warning!", COLOR.MENU, "  This will completely delete ", COLOR.NAME, "all the data in the table.  A server restart is required to complete this action.  ", COLOR.MENU, "Are you sure you want to continue?" }, 
					Yes = function()
						local sender = exsto.CreateSender( "ExResetDB" )
							sender:AddString( PLUGIN.WorkingDB.db )
						sender:Send()
					end
				} )
			end

		pnl.Cat:InvalidateLayout( true )
	end
	
	local function backFunction( obj )
		exsto.Menu.OpenPage( PLUGIN.MainPage )
		exsto.Menu.DisableBackButton()
		
		PLUGIN.WorkingDB = "%DATABASE"
	end
	
	local function backBackupFunction( obj )
		exsto.Menu.OpenPage( PLUGIN.BackupRestorePage )
	end
	
	local function refreshBackupList( dbs )
		local pnl = PLUGIN.BackupPage.Content
		if !pnl then return end
		
		pnl.List:Clear()
		pnl.RestoreSelected = nil
		for _, data in ipairs( dbs ) do
			pnl.List:AddRow( { data.db, data.time }, data )
		end
		
		if PLUGIN.BackupRestorePage:IsActive() then
			PLUGIN.BackupRestorePage.Content.AutoBackup:SetValue( PLUGIN.WorkingDB.autoBackup )
		end

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
		pnl:GetObject():Alert( {
			Text = { "You have selected to restore a backup!  This will erase all the contents existing in the database.  The server will also reload promptly after the restore has complete.  Are you sure?" },
			Yes = function()
				local sender = exsto.CreateSender( "ExRestoreDatabase" )
					sender:AddString( PLUGIN.WorkingDB.db )
					sender:AddString( pnl.RestoreSelected.db )
				sender:Send()
			end
		} )
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
			pnl.List.Paint = function() end
			pnl.List.LineSelected = function( o, disp, data, obj )
				pnl.RestoreSelected = data
			end
			pnl.List.OnMouseWheeled = nil
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

		invalidate( PLUGIN.BackupPage )
	end
	
	local function infoInit( pnl )
	end
	
	local function infoBackupFunction( obj )
		exsto.Menu.OpenPage( PLUGIN.DetailsPage )
	end
	
	local function backupRestoreInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Backup / Restore" )
		
		pnl.Cat:CreateSpacer();
		
		pnl.BackupText = pnl.Cat:CreateTitle( "Backup" );
		pnl.BackupHelp = pnl.Cat:CreateHelp( "Backups save to the server's 'data/exsto_db_backups' directory.  Files are saved with the date and time." )
		
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
			
		pnl.Cat:CreateSpacer();
		
		pnl.AutoText = pnl.Cat:CreateTitle( "Automatic Backup" );
		pnl.AutoHelp = pnl.Cat:CreateHelp( "Automatically backup databases on a pre-set time interval.  Set to 0 for never run.  Files saved in 'data/exsto_db_backups'" )
		
		pnl.AutoBackup = vgui.Create( "ExNumberChoice", pnl.Cat )
			pnl.AutoBackup:Text( "Rate (hours)" )
			pnl.AutoBackup:SetMinMax( 0, 100 )
			pnl.AutoBackup:Dock( TOP )
			pnl.AutoBackup:SetTall( 40 )
			pnl.AutoBackup.OnValueSet = function( o, val )
				local sender = exsto.CreateSender( "ExBackupRate" )
					sender:AddString( PLUGIN.WorkingDB.db )
					sender:AddShort( val )
				sender:Send()
			end
			
		pnl.Cat:CreateSpacer();
		
		pnl.Restore = pnl.Cat:CreateButton( "Restore Previous Backup" );
			pnl.Restore.DoClick = function( o )
				exsto.Menu.OpenPage( PLUGIN.BackupPage );
			end 

		pnl.Cat:InvalidateLayout( true )
	end
		
		
	function PLUGIN:Init()
		self.MainPage = exsto.Menu.CreatePage( "felsettings", pageInit )
			self.MainPage:SetTitle( "Databases" )
			self.MainPage:OnShowtime( requestDatabaseList )
			self.MainPage:SetIcon( "exsto/database.png" )
	
		self.DetailsPage = exsto.Menu.CreatePage( "feldetails", detailsInit )
			self.DetailsPage:SetTitle( "Details" )
			self.DetailsPage:SetUnaccessable()
			self.DetailsPage:OnShowtime( showtimeDetails )
			self.DetailsPage:SetBackFunction( backFunction )
			
		self.BackupRestorePage = exsto.Menu.CreatePage( "felbackuprestore", backupRestoreInit )
			self.BackupRestorePage:SetTitle( "Backup / Restore" )
			self.BackupRestorePage:SetUnaccessable()
			self.BackupRestorePage:OnShowtime( requestBackupList )
			self.BackupRestorePage:SetBackFunction( function() exsto.Menu.OpenPage( self.DetailsPage ) end )
			
		self.BackupPage = exsto.Menu.CreatePage( "felbackup", backupInit )
			self.BackupPage:SetTitle( "Backup" )
			self.BackupPage:SetUnaccessable()
			self.BackupPage:SetBackFunction( backBackupFunction )
			self.BackupPage:OnShowtime( requestBackupList )
			
	end
	
end

PLUGIN:Register()