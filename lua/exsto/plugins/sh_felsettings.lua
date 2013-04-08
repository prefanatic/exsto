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

end

if CLIENT then

	local function invalidate()
		local pnl = PLUGIN.MainPage.Content
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
			pnl.List:AddLine( data.db ).Data = data
		end
		
		pnl.List:AddLine( "Global" ).Data = { db = "Global", mysql = nil }
		
		invalidate()
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
	
	local function onRowSelected( lst, lineid, line )
		PLUGIN.WorkingDB = line.Data
		exsto.Menu.EnableBackButton()
		exsto.Menu.OpenPage( PLUGIN.DetailsPage )
	end

	local function pageInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Databases" )
		
		pnl.List = vgui.Create( "ExListView", pnl.Cat )
			pnl.List:DockMargin( 4, 0, 4, 0 )
			pnl.List:Dock( TOP )
			pnl.List:DisableScrollbar()
			pnl.List:AddColumn( "" )
			pnl.List:SetHideHeaders( true )
			
		pnl.List.OnRowSelected = onRowSelected
	
		invalidate()
	end
	
	local function showtimeDetails( page )
		local pnl = page.Content
		
		pnl.Cat.Header:SetText( PLUGIN.WorkingDB.db )
		pnl.MySQL:SetValue( PLUGIN.WorkingDB.mysql )
		
		pnl.Restore:SetDisabled( false )
		pnl.Edit:SetDisabled( false )
		
		if PLUGIN.WorkingDB.db == "Global" then
			pnl.Restore:SetDisabled( true )
			pnl.Edit:SetDisabled( true )
			pnl.MySQL:SetValue( FEL.AllDatabasesMySQL() )
		end
	end
	
	local function detailsInit( pnl )
		pnl.Cat = pnl:CreateCategory( "%DATABASE" )
		
		-- Our options.
		pnl.Restore = vgui.Create( "ExButton", pnl.Cat )
			pnl.Restore:Text( "Restore" )
			pnl.Restore:Dock( TOP )
			pnl.Restore:SetQuickMenu()
			pnl.Restore:SetTall( 32 )
			pnl.Restore.DoClick = function()
				pnl:GetObject():Alert( "Test Alert!", function() pnl:GetObject():Alert( "This is a secondary alert that should be much longer than the other one!" ) end )
			end
			
		pnl.Backup = vgui.Create( "ExButton", pnl.Cat )
			pnl.Backup:Text( "Backup" )
			pnl.Backup:Dock( TOP )
			pnl.Backup:SetQuickMenu()
			pnl.Backup:SetTall( 32 )
			
		pnl.MySQL = vgui.Create( "ExBooleanChoice", pnl.Cat )
			pnl.MySQL:Text( "MySQL Enabled" )
			pnl.MySQL:Dock( TOP )
			pnl.MySQL:SetQuickMenu()
			pnl.MySQL:SetAlignX( TEXT_ALIGN_CENTER )
			pnl.MySQL:SetMaxTextWide( false )
			pnl.MySQL:MaxFontSize( 28 )
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
			
		pnl.Edit = vgui.Create( "ExButton", pnl.Cat )
			pnl.Edit:Text( "Edit" )
			pnl.Edit:Dock( TOP )
			pnl.Edit:SetQuickMenu()
			pnl.Edit:SetTall( 32 )
			
		pnl.Recover = vgui.Create( "ExButton", pnl.Cat )
			pnl.Recover:Text( "Recover" )
			pnl.Recover:Dock( TOP )
			pnl.Recover:SetQuickMenu()
			pnl.Recover:SetTall( 32 )
			
		pnl.Reset = vgui.Create( "ExButton", pnl.Cat )
			pnl.Reset:Text( "Reset" )
			pnl.Reset:Dock( TOP )
			pnl.Reset:SetQuickMenu()
			pnl.Reset:SetTall( 32 )

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
	
	local function backupInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Backup" )
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
			
		self.MySQLInfoPage = exsto.Menu.CreatePage( "felmysqlinfo", infoInit )
			self.MySQLInfoPage:SetTitle( "Account Information" )
			self.MySQLInfoPage:SetUnaccessable()
			self.MySQLInfoPage:SetBackFunction( infoBackupFunction )
			
	end
	
end

PLUGIN:Register()