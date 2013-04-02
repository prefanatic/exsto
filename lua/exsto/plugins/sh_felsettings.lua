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
	
	end

	function PLUGIN:RequestDatabases( reader )
		local ply = reader:ReadSender()
		
		self:Debug( "Sending database list to '" .. ply:Nick() .. "'", 1 )
		
		local sender = exsto.CreateSender( "ExSendDatabaseList", ply )
			sender:AddShort( #FEL.GetDatabases() )
		for _, obj in ipairs( FEL.GetDatabases() ) do
			sender:AddString( obj:GetName() )
		end
		
		sender:Send()
	end
	PLUGIN:CreateReader( "ExRequestDatabaseList", PLUGIN.RequestDatabases )

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
		for _, name in ipairs( dbs ) do
			pnl.List:AddLine( name ).Name = name
		end
		
		invalidate()
	end
	
	local function requestDatabaseList( page )
		PLUGIN:Debug( "Requesting database list from server.", 1 )
		exsto.CreateSender( "ExRequestDatabaseList" ):Send()
	end
	
	local function receiveDatabaseList( reader )
		local tbl = {}
		for I = 1, reader:ReadShort() do
			table.insert( tbl, reader:ReadString() )
		end
		refreshDatabaseList( tbl )
	end
	exsto.CreateReader( "ExSendDatabaseList", receiveDatabaseList )
	
	local function onRowSelected( lst, lineid, line )
		PLUGIN.WorkingDB = line.Name
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
		
		pnl.Cat.Header:SetText( PLUGIN.WorkingDB )
	end
	
	local function detailsInit( pnl )
		pnl.Cat = pnl:CreateCategory( "%DATABASE" )
		
		-- Our options.
		pnl.Restore = vgui.Create( "ExButton", pnl.Cat )
			pnl.Restore:Text( "Restore" )
			pnl.Restore:Dock( TOP )
			pnl.Restore:SetQuickMenu()
			pnl.Restore:SetTall( 32 )
			
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
	
	function PLUGIN:Init()
		self.MainPage = exsto.Menu.CreatePage( "felsettings", pageInit )
			self.MainPage:SetTitle( "Databases" )
			self.MainPage:OnShowtime( requestDatabaseList )
	
		self.DetailsPage = exsto.Menu.CreatePage( "feldetails", detailsInit )
			self.DetailsPage:SetTitle( "Details" )
			self.DetailsPage:SetUnaccessable()
			self.DetailsPage:OnShowtime( showtimeDetails )
			self.DetailsPage:SetBackFunction( backFunction )
	end
	
end

PLUGIN:Register()