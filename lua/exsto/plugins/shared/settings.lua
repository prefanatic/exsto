-- Prefan Access Controller
-- Var changing plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Variable Changer",
	ID = "change-var",
	Desc = "A plugin that allows management over variables!",
	Owner = "Prefanatic",
} )

if SERVER then

	function PLUGIN:Init()
		exsto.CreateFlag( "settings", "Allows users to see the settings page." )
		exsto.CreateFlag( "server-settings", "Allows users to change server settings." )
		
		util.AddNetworkString( "ExChangeVar" )
	end
	
	function PLUGIN:ExChangeVar( reader )
		return reader:ReadSender():IsAllowed( "server-settings" )
	end
	
	function PLUGIN:UpdateVariable( reader )
		local id = reader:ReadString()
		local val = reader:ReadVariable()
		
		-- Get our object!
		local obj = exsto.Variables[ id ]
		if !obj then self:Error( "Trying to access unknown variable w/ id '" .. id .. "'" ) return end
		
		self:Debug( "Getting data from client: Updating '" .. id .. "' with '" .. tostring( val ) .. "'" )
		obj:SetValue( val )
	end
	PLUGIN:CreateReader( "ExChangeVar", PLUGIN.UpdateVariable )
	
elseif CLIENT then

	-- TODO: Refresh this editor if variables are changed.
		-- Check and make sure the ID belongs to the currently selected page.  If so, refresh and reselect.  If not, refresh anyways.
		
	local function invalidate( cont )
		local pnl = cont.Content
		if !pnl then PLUGIN:Error( "Oh no!  Attempted to access invalid page contents." ) return end
		
		pnl.List:SetDirty( true )
		pnl.List:InvalidateLayout( true )
		
		pnl.List:SizeToContents()
		
		pnl.Cat:InvalidateLayout( true )
	end

	local function onShowtime( page, search )
		local pnl = page.Content
		if !pnl then return end

		search = search or ""
		
		pnl.List:Clear()
		
		local tmp = {}
		if LocalPlayer():IsAllowed( "server-settings" ) then -- Serverside settings.
			for id, data in pairs( exsto.ServerVariables ) do
				if data.Category:lower():find( search ) then
					if !tmp[ data.Category ] then tmp[ data.Category ] = {} end
					table.insert( tmp[ data.Category ], { cl = false, id = id } )
				end
			end
		end
		
		-- Clientside settings.
		for id, var in pairs( exsto.Variables ) do
			if var:GetCategory():lower():find( search ) then
				if !tmp[ var:GetCategory() ] then tmp[ var:GetCategory() ] = {} end
				table.insert( tmp[ var:GetCategory() ], { cl = true, id = id } )
			end
		end

		for cat, ids in pairs( tmp ) do
			pnl.List:AddRow( { cat }, ids )
		end
		
		pnl.List:SortByColumn( 1 )
		invalidate( PLUGIN.Page )
	end

	local function updateVariable( id, val )
		-- Send this information up to the big guys to change!
		local sender = exsto.CreateSender( "ExChangeVar" )
			sender:AddString( id )
			sender:AddVariable( val )
		sender:Send()
	end
	
	local function detailsOnShowtime( page )
		local page = page.Content
		if !page.Objects then page.Objects = {} end
		
		-- Clear the old objects.
		for _, obj in ipairs( page.Objects ) do
			obj:Remove()
		end
		page.Objects = {}

		-- Now, we need to loop through all of our data and create objects for each of these things.  Cross your fingers.
		local data
		for _, dID in ipairs( PLUGIN.WorkingCat ) do
			if not dID.cl then -- Serverside
				data = exsto.ServerVariables[ dID.id ] -- So this is 'live' so to speak
			else
				data = exsto.Variables[ dID.id ]
			end
			
			page.Cat.Header:SetText( data.Category ) -- Kind of silly to do this, but it saves writing extra code.
			
			local obj = vgui.Create( "ExSettingsElement", page.Cat )
				if dID.cl then obj:SetClientside() end
				obj:Dock( TOP )
				obj:SetTitle( data.Display )
				obj:SetHelp( data.Help )

			if data.Maximum == 1 and data.Minimum == 0 and #data.Possible == 2 then -- We're a boolean
				obj:SetBoolean()
			elseif  data.Possible and #data.Possible > 0 then
				obj:SetMultiChoice()
				-- Enable multi selecting if we can do that.
				if data.Multi then obj:SetMultipleOptions() end
				
				for i, possible in ipairs( data.Possible ) do
					obj:AddChoice( possible, possible )
				end
			elseif data.Type == "string" then -- We're a text box
				obj:SetTextEntry()
			elseif data.Type == "number" then -- We're a number!
				obj:SetNumberEntry( "" )
				obj:SetMin( data.Minimum )
				obj:SetMax( data.Maximum )
				obj:SetUnit( data.Unit )
			end
			
			if not dID.cl then
				obj:SetValue( data.Value )
			else
				obj:SetValue( data:GetValue() )
			end
			
			obj.OnValueSet = function( o, val )
				if not dID.cl then
					updateVariable( dID.id, val )
				else
					-- Parse out this.  We don't do this above because the server handles it.
					if type( val ) == "boolean" then val = ( val and 1 or 0 ) end
					RunConsoleCommand( dID.id, val )
				end
			end
			
			table.insert( page.Objects, obj )
			
			-- Little hack
			table.insert( page.Objects, page.Cat:CreateSpacer() )
			
		end

	end

	local function settingsInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Settings" )
		
		pnl.List = vgui.Create( "ExListView", pnl.Cat )
			pnl.List:DockMargin( 4, 0, 4, 0 )
			pnl.List:Dock( TOP )
			pnl.List:DisableScrollbar()
			pnl.List:AddColumn( "" )
			pnl.List.OnMouseWheeled = nil
			pnl.List:SetHideHeaders( true )
			pnl.List:SetQuickList()
			
		pnl.List.LineSelected = function( o, disp, data, line )
			PLUGIN.WorkingCat = data
			exsto.Menu.EnableBackButton()
			exsto.Menu.OpenPage( PLUGIN.DetailsPage )
		end
			
		invalidate( PLUGIN.Page )
	end
	
	local function detailsInit( pnl )
		pnl.Cat = pnl:CreateCategory( "%CAT" )
	end
	
	local function detailsBack( page )
		PLUGIN.WorkingCat = nil
		exsto.Menu.DisableBackButton()
		exsto.Menu.OpenPage( PLUGIN.Page )
	end
	
	local function onSearch( e )
		onShowtime( PLUGIN.Page, e:GetValue() )
	end

	function PLUGIN:Init()
		self.Page = exsto.Menu.CreatePage( "settings", settingsInit )
			self.Page:SetTitle( "Settings" )
			self.Page:SetSearchable( true )
			self.Page:OnShowtime( onShowtime )
			self.Page:SetIcon( "exsto/settings.png" )
			self.Page:OnSearchTyped( onSearch )
		
		self.DetailsPage = exsto.Menu.CreatePage( "settingsdetails", detailsInit )
			self.DetailsPage:SetFlag( "settings" )
			self.DetailsPage:SetTitle( "Details" )
			self.DetailsPage:OnShowtime( detailsOnShowtime )
			self.DetailsPage:SetBackFunction( detailsBack )
			self.DetailsPage:SetUnaccessable()
	end
	
end
 
PLUGIN:Register()