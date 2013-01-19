local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "FEL Settings",
	ID = "felsettings",
	Desc = "File Extension Library Settings",
	Owner = "Prefanatic",
} )

if SERVER then

	util.AddNetworkString( "ExSendDatabaseName" )
	util.AddNetworkString( "ExSendDatabaseData" )
	util.AddNetworkString( "ExRequestDBNames" )
	util.AddNetworkString( "ExRequestDBTransfer" )

	-- Sends all of our databases to the client.  Not the data, just the names.
	function PLUGIN:SendDatabases( ply )
		local sender = exsto.CreateSender( "ExSendDatabaseName", ply );
			sender:AddShort( #FEL.Databases );

			for I = 1, #FEL.Databases do
				sender:AddString( FEL.Databases[ I ].dbName );
			end
		sender:Send()
	end

	-- Send the database information to the client.
	function PLUGIN:SendDatabaseData( ply, dbName )
		local db = FEL.GetDatabase( dbName )
		if !db then self:Error( "Unable to retrieve database: '" .. dbName .. "'" ) return end

		local data = db:GetAll()
		
		local sender = exsto.CreateSender( "ExSendDatabaseData", ply )
			-- Loop through the databases content.
			sender:AddString( dbName )
			sender:AddShort( #data )
			for I = 1, #data do
				sender:AddShort( table.Count( data[ I ] ) )
				for column, row in pairs( data[ I ] ) do
					sender:AddString( column )
					sender:AddVariable( row )
				end
			end
		sender:Send() -- Push the database.  This is going to be kind of big...
	end

	-- Handlers
	local function accDatabaseNames( reader )
		PLUGIN:SendDatabases( reader:ReadSender() )
		PLUGIN:Debug( "Sending database names to '" .. reader:ReadSender():Nick() .. "'" )
	end
	exsto.CreateReader( "ExRequestDBNames", accDatabaseNames )

	local function accDatabaseData( reader )
		PLUGIN:SendDatabaseData( reader:ReadSender(), reader:ReadString() );
		PLUGIN:Debug( "Sending database contents to '" .. reader:ReadSender():Nick() .. "'")
	end
	exsto.CreateReader( "ExRequestDBTransfer", accDatabaseData )


	function PLUGIN:Init()
		for _, db in ipairs( FEL.Databases ) do
			--PrintTable( db.Columns )
		end

		--PrintTable( exsto.UserDB:GetAll() )
		
	end

end

if CLIENT then
	function PLUGIN:Init()
		self.Databases = {}
	end
	
	local function recDatabaseNames( reader )
		for I = 1, reader:ReadShort() do
			PLUGIN.Databases[ reader:ReadString() ] = {}
		end
		PLUGIN.Panel.Secondary.DBSelect:Populate()
	end
	exsto.CreateReader( "ExSendDatabaseName", recDatabaseNames );

	local function recDatabaseData( reader )
		local data = {}
		local dbName = reader:ReadString()

		for I = 1, reader:ReadShort() do
			data[ I ] = {}
			for i = 1, reader:ReadShort() do
				data[ I ][ reader:ReadString() ] = reader:ReadVariable();
			end
		end

		-- We received the table.  Lets format this into the DListView we have.
		PLUGIN.Databases[ dbName ] = data;
		PLUGIN.Panel.DataViewPopulate( dbName )

		PLUGIN.RequestingData = false
	end
	exsto.CreateReader( "ExSendDatabaseData", recDatabaseData )

	local function onDBSelect( box, index, value, data )
		if PLUGIN.RequestingData then PLUGIN:Print( "In the middle of a data transfer.  Please wait!" ) return end
		
		-- Call the server, lets let him know!
		local sender = exsto.CreateSender( "ExRequestDBTransfer" )
			sender:AddString( value );
		sender:Send();

		PLUGIN.RequestingData = true
	end

	Menu:CreatePage( {
		Title = "FEL Settings",
		Short = "felsettings",
		},
		function( panel )
			PLUGIN.Panel = panel

			-- Let's get the databases.
			local sender = exsto.CreateSender( "ExRequestDBNames" ):Send();


			panel.Secondary = panel:RequestSecondary()
			panel.Secondary.Warning = exsto.CreateLabel( "center", 4, "Warning: Databases may contain a lot of data.", "ExGenericTextNoBold14", panel.Secondary )
			panel.Secondary.Warning2 = exsto.CreateLabel( "center", 20, "Lag can occur with large tables.", "ExGenericTextNoBold14", panel.Secondary )
			panel.Secondary.DBSelect = exsto.CreateMultiChoice( 5, 44, panel.Secondary:GetWide() - 10, 15, panel.Secondary )
				panel.Secondary.DBSelect.OnSelect = onDBSelect
				panel.Secondary.DBSelect.Populate = function( box )
					box:Clear()
					for name, data in pairs( PLUGIN.Databases ) do
						box:AddChoice( name );
					end
				end

			-- Data list view.
			panel.DataViewPopulate = function( db )
				if panel.DataView and panel.DataView:IsValid() then panel.DataView:Remove() end

				panel.DataView = exsto.CreateListView( 5, 5, panel:GetWide() - 10, panel:GetTall() - 50, panel )

				-- Now, add our data.
				local data = PLUGIN.Databases[ db ]
				local columns = {}
				local formattedRows = {}

				-- First, find our the columns we need to use.
				for _, entry in ipairs( data ) do
					formattedRows[ _ ] = {}
					for column, row in pairs( entry ) do
						if !table.HasValue( columns, column ) then table.insert( columns, column ) end
						table.insert( formattedRows[ _ ], tostring( row ) )
					end
				end

				-- Construct columns.
				for _, column in ipairs( columns ) do
					panel.DataView:AddColumn( column )
				end

				-- Now, add our data :)
				for _, row in ipairs( formattedRows ) do
					panel.DataView:AddLine( unpack( row ) );
				end
			end


		end
	)
end

PLUGIN:Register()