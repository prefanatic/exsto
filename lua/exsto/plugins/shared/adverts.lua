local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Adverts",
	ID = "adverts",
	Desc = "Allows the creation of adverts",
	Owner = "Prefanatic",
	CleanUnload = true;
} )

if SERVER then

	function PLUGIN:Init()
		util.AddNetworkString( "ExRequestAdverts" )
		util.AddNetworkString( "ExSendAdverts" )
		util.AddNetworkString( "ExUpdateAdvertValue" )
		util.AddNetworkString( "ExStartBannerAd" )
		util.AddNetworkString( "ExToggleAdvert" )
		util.AddNetworkString( "ExDeleteAdvert" )
		util.AddNetworkString( "ExStartCenterAd" )
		
		exsto.CreateFlag( "advertlist", "Allows users to access the advert list and create/edit adverts." )
		
		self.DB = FEL.CreateDatabase( "exsto_adverts" )
			self.DB:SetDisplayName( "Adverts" )
			self.DB:ConstructColumns( {
				ID = "VARCHAR(255):primary:not_null";
				Display = "TEXT";
				Contents = "TEXT";
				StringContents = "TEXT";
				Location = "TINYINT";
				Delay = "INTEGER";
				Data = "TEXT";
				Enabled = "TINYINT";
			} )
			
		self.Adverts = {}
		self.Running = {}
		
		self.Locations = {
			chat = 1;
			banner = 2;
			center = 3;
		}

		-- Throw our saved data into our own table.
		self:RefreshData()
		
	end
	
	function PLUGIN:RefreshData()
		self.DB:GetAll( function( q, d )
			if not d then
				local msg = "[c=COLOR,NAME] This [c=COLOR,NORM] is an example advert!";
				self.DB:AddRow( {
					ID = "example";
					Display = "Advert Example";
					Contents = von.serialize( exsto.CreateColoredPrint( msg ) );
					StringContents = msg;
					Location = 1;
					Delay = 1;
					Data = von.serialize( {} );
					Enabled = 0;
				} )
				timer.Simple( 0.5, function() self:RefreshData() end )
				return
			end
			
			for _, data in pairs( d ) do				
				self.Adverts[ data.ID ] = {
					ID = data.ID;
					Display = data.Display;
					Contents = von.deserialize( data.Contents );
					StringContents = data.StringContents;
					Location = data.Location;
					Delay = data.Delay;
					Data = von.deserialize( data.Data );
					Enabled = data.Enabled
				}
			
				-- Start the advert
				self:StartAdvert( data.ID )
			end
		end )
	end
	
	function PLUGIN:ExDeleteAdvert( reader )
		return reader:ReadSender():IsAllowed( "advertlist" )
	end
	function PLUGIN:ClientDeleteAdvert( reader )
		local id = reader:ReadString()
		self:Debug( "Player '" .. reader:ReadSender():Nick() .. "' is deleting the advert '" .. id .. "'", 1 )
		self:RemoveAdvert( id )
	end
	PLUGIN:CreateReader( "ExDeleteAdvert", PLUGIN.ClientDeleteAdvert )
	
	function PLUGIN:ExToggleAdvert( reader )
		return reader:ReadSender():IsAllowed( "advertlist" )
	end
	function PLUGIN:ToggleAdvert( reader )
		local data = self.Adverts[ reader:ReadString() ]
		self:Debug( "Player '" .. reader:ReadSender():Nick() .. "' is toggling the advert '" .. data.ID .. "'", 1 )
		if data.Enabled == 1 then return self:DisableAdvert( data.ID ) end
		self:EnableAdvert( data.ID )
	end
	PLUGIN:CreateReader( "ExToggleAdvert", PLUGIN.ToggleAdvert )
	
	function PLUGIN:ExUpdateAdvertValue( reader )
		return reader:ReadSender():IsAllowed( "advertlist" )
	end
	function PLUGIN:UpdateAdvertValue( reader )
		self:Debug( "Player '" .. reader:ReadSender():Nick() .. "' is updating a value from the client.", 1 )
		self:EditAdvert( reader:ReadString(), reader:ReadShort(), reader:ReadString() )
	end
	PLUGIN:CreateReader( "ExUpdateAdvertValue", PLUGIN.UpdateAdvertValue )
	
	function PLUGIN:ExRequestAdverts( reader )
		return reader:ReadSender():IsAllowed( "advertlist" )
	end
	function PLUGIN:SendPlayerAdvert( reader )
		local ply = reader:ReadSender()
		self:Debug( "Player '" .. ply:Nick() .. "' is requesting the adverts list.", 1 )
		PLUGIN:SendAdverts( ply )
	end
	PLUGIN:CreateReader( "ExRequestAdverts", PLUGIN.SendPlayerAdvert )
	
	function PLUGIN:SendAdverts( ply )
		local sender = exsto.CreateSender( "ExSendAdverts", ply or player.GetAll() )
		
		sender:AddShort( table.Count( self.Adverts ) )
		for id, data in pairs( self.Adverts ) do
			sender:AddString( id )
			sender:AddString( data.Display )
			sender:AddString( data.StringContents )
			sender:AddShort( data.Location )
			sender:AddShort( data.Delay )
			--sender:AddTable( data.Data )
			sender:AddBool( data.Enabled )
		end
		
		sender:Send()
	end

	function PLUGIN:ExInitSpawn( ply )
		-- We want to send our running advertisements to them.
		self:SendAdverts( ply )
	end			
	
	function PLUGIN:AdvertRunning( id )
		for _, data in ipairs( self.Running ) do
			if data.ID == id then return true end
		end
		return false
	end
	
	function PLUGIN:Think()
		-- Loop through what we've got active
		for _, data in ipairs( self.Running ) do
			if data.Enabled == 1 and ( CurTime() > data.NextRun ) then -- Can we run?
				data.NextRun = CurTime() + ( data.Delay * 60 )
				self:RunAdvert( data ) -- Run the advert!
			end
			if data.Enabled == 0 then -- Remove us from this table!
				self:DisableAdvert( data.ID )
			end
		end
	end
	
	function PLUGIN:RunAdvert( data )
		if data.Location == self.Locations.chat then -- We're chat bound
			exsto.Print( exsto_CHAT_ALL, unpack( data.Contents ) ) -- And we're done!
		elseif data.Location == self.Locations.center then
			local sender = exsto.CreateSender( "ExStartCenterAd", player.GetAll() )
				sender:AddString( data.ID )
				sender:AddString( data.StringContents )
			sender:Send()
		elseif data.Location == self.Locations.banner then
			local sender = exsto.CreateSender( "ExStartBannerAd", player.GetAll() )
				sender:AddString( data.ID )
				sender:AddString( data.StringContents )
			sender:Send()
		end
	end

	function PLUGIN:StartAdvert( id )
		-- Reference our table
		local data = self.Adverts[ id ]
		
		-- Create our NextRun, and add to it if we have a StartDelay
		data.NextRun = CurTime() + ( data.Data.StartDelay or 0 )
		
		-- Insert into our running.
		table.insert( self.Running, data )
	end		
	
	function PLUGIN:CreateAdvert( id, disp, contents, loc, delay, data )
		contents = "[c=COLOR,NORM] " .. contents 
		local tblContents = exsto.CreateColoredPrint( contents )
	
		-- Save it
		self.DB:AddRow( {
			ID = id;
			Display = disp;
			Contents = von.serialize( tblContents );
			StringContents = contents;
			Location = loc;
			Delay = delay;
			Data = von.serialize( data );
			Enabled = 1;
		} )
		
		-- Throw it into our own table
		self.Adverts[ id ] = {
			ID = id;
			Display = disp;
			Contents = tblContents;
			StringContents = contents;
			Location = loc;
			Delay = delay;
			Data = data;
			Enabled = 1;
		}
		
		-- And start it
		self:StartAdvert( id )
		
		self:SendAdverts()
		
	end
	
	function PLUGIN:RemoveAdvert( id )
		self.DB:DropRow( id )
		self.Adverts[ id ] = nil
		
		for _, data in ipairs( self.Running ) do
			if data.ID == id then table.remove( self.Running, _ ) break end
		end
		
		self:SendAdverts()
	end
	
	function PLUGIN:DisableAdvert( id )
		self.Adverts[ id ].Enabled = 0
		self.DB:AddRow( {
			ID = id;
			Enabled = 0;
		} )
		
		for _, data in ipairs( self.Running ) do
			if data.ID == id then table.remove( self.Running, _ ) break end
		end
		self:SendAdverts()
	end
	
	function PLUGIN:EnableAdvert( id )
		self.Adverts[ id ].Enabled = 1
		self.DB:AddRow( {
			ID = id;
			Enabled = 1;
		} )
		
		self:StartAdvert( id )
		self:SendAdverts()
	end
	
	function PLUGIN:UpdateRunningData( id )
		for _, data in ipairs( self.Running ) do
			if data.ID == id then table.remove( self.Running, _ ) break end
		end
		table.insert( self.Running, self.Adverts[ id ] )
	end
		
	
	function PLUGIN:EditAdvert( id, class, value )
		if class == 1 then -- Display
			self.Adverts[ id ].Display = value;
			self.DB:AddRow( {
				ID = id;
				Display = value;
			} )
		elseif class == 2 then -- Message
			self.Adverts[ id ].StringContents = value;
			self.Adverts[ id ].Contents = exsto.CreateColoredPrint( value );
			self.DB:AddRow( {
				ID = id;
				StringContents = value;
				Contents = von.serialize( self.Adverts[ id ].Contents );
			} )
		elseif class == 3 then -- Location
			self.Adverts[ id ].Location = self.Locations[ value ];
			self.DB:AddRow( {
				ID = id;
				Location = self.Adverts[ id ].Location;
			} )
		elseif class == 4 then -- Delay
			self.Adverts[ id ].Delay = tonumber( value );
			self.DB:AddRow( {
				ID = id;
				Delay = self.Adverts[ id ].Delay;
			} )
		elseif class == 5 then -- Bones
			self:CreateAdvert( id, value, "", 1, 5, {} )
			self:DisableAdvert( id )
		end
		self:UpdateRunningData( id )
	end
		
	
	--[[ -----------------------------
		Command Handlers
	---------------------------------]]
	function PLUGIN:ComCreateAdvert( caller, id, display, location, delay, contents )
		local loc = self.Locations[ location ]
		if not loc then
			local str = exsto.GetClosestString( location, { "chat", "banner", "center" } )
			exsto.Print( exsto_CHAT, caller, COLOR.NAME, location, COLOR.NORM, " is not a valid advert location.  Maybe you want ", COLOR.NAME, str, COLOR.NORM, "?" )
			return
		end
		
		self:CreateAdvert( id, display, contents, loc, delay, {} )
		exsto.Print( exsto_CHAT_ALL, COLOR.NAME, caller:Nick(), COLOR.NORM, " has created the advert ", COLOR.NAME, display )
	end
	PLUGIN:AddCommand( "advertcreate", {
		Call = PLUGIN.ComCreateAdvert,
		Console = { "advertcreate" },
		Arguments = {
			{ Name = "ID", Type = "STRING" };
			{ Name = "Display", Type = "STRING" };
			{ Name = "Location", Type = "STRING" };
			{ Name = "Delay", Type = "TIME" };
			{ Name = "Contents", Type = "STRING" };
		};
		Category = "Adverts";
	} )

	function PLUGIN:ComRemoveAdvert( caller, id )
		local disp = self.Adverts[ id ].Display
		exsto.Print( exsto_CHAT_ALL, COLOR.NAME, caller:Nick(), COLOR.NORM, " has removed the advert ", COLOR.NAME, disp )
		self:RemoveAdvert( id )
	end
	PLUGIN:AddCommand( "advertremove", {
		Call = PLUGIN.ComRemoveAdvert,
		Console = { "advertremove" },
		Arguments = {
			{ Name = "ID", Type = "STRING" };
		};
		Category = "Adverts";
	} )
	
	function PLUGIN:ComEnableAdvert( caller, id )
		local data = self.Adverts[ id ] 
		if data and data.Enabled == 0 then
			self:EnableAdvert( id )
			exsto.Print( exsto_CHAT_ALL, COLOR.NAME, caller:Nick(), COLOR.NORM, " has enabled the advert ", COLOR.NAME, data.Display )
			return
		else
			exsto.Print( exsto_CHAT, caller, COLOR.NORM, "The advert is already ", COLOR.NAME, "enabled" )
			return
		end
		
		local str = exsto.GetClosestString( id, self.Adverts, "ID" )
		exsto.Print( exsto_CHAT, caller, COLOR.NAME, id, COLOR.NORM, " is not a valid advert.  Maybe you want ", COLOR.NAME, str, COLOR.NORM, "?" )
		return
	end
	PLUGIN:AddCommand( "advertenable", {
		Call = PLUGIN.ComEnableAdvert,
		Console = { "advertenable" },
		Arguments = {
			{ Name = "ID", Type = "STRING" };
		};
		Category = "Adverts";
	} )
	
	function PLUGIN:ComDisableAdvert( caller, id )
		local data = self.Adverts[ id ] 
		if data and data.Enabled == 1 then
			self:DisableAdvert( id )
			exsto.Print( exsto_CHAT_ALL, COLOR.NAME, caller:Nick(), COLOR.NORM, " has disabled the advert ", COLOR.NAME, data.Display )
			return
		else
			exto.Print( exsto_CHAT, caller, COLOR.NORM, "The advert is already ", COLOR.NAME, "disabled" )
			return
		end
		
		local str = exsto.GetClosestString( id, self.Adverts, "ID" )
		exsto.Print( exsto_CHAT, caller, COLOR.NAME, id, COLOR.NORM, " is not a valid advert.  Maybe you want ", COLOR.NAME, str, COLOR.NORM, "?" )
		return
	end
	PLUGIN:AddCommand( "advertdisable", {
		Call = PLUGIN.ComDisableAdvert,
		Console = { "advertdisable" },
		Arguments = {
			{ Name = "ID", Type = "STRING" };
		};
		Category = "Adverts";
	} )
	
	function PLUGIN:ComPrintAdverts( caller )
		for id, data in pairs( self.Adverts ) do
			exsto.Print( exsto_CLIENT, caller, data.Display )
			exsto.Print( exsto_CLIENT, caller, "\t Identifier: " .. data.ID )
			exsto.Print( exsto_CLIENT, caller, "\t Location: " .. data.Location )
			exsto.Print( exsto_CLIENT, caller, "\t Delay: " .. data.Delay )
			exsto.Print( exsto_CLIENT, caller, "\t Contents: " .. tostring( data.Contents ) .. "\n" )
		end
	end
	PLUGIN:AddCommand( "advertlist", {
		Call = PLUGIN.ComPrintAdverts,
		Console = { "advertlist" },
		Category = "Adverts";
	} )
	
	
else

	local function update( class, value )
		local sender = exsto.CreateSender( "ExUpdateAdvertValue" )
			sender:AddString( PLUGIN.WorkingAdvert.ID )
			sender:AddShort( class )
			sender:AddString( value )
		sender:Send()
	end

	local function advertInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Adverts" )
		
		pnl.List = vgui.Create( "ExListView", pnl.Cat )
			pnl.List:DockMargin( 4, 0, 4, 0 )
			pnl.List:Dock( TOP )
			pnl.List:DisableScrollbar()
			pnl.List:AddColumn( "" )
			pnl.List:SetHideHeaders( true )
			pnl.List:SetQuickList( pnl.Cat )
			pnl.List:SetEnableDisable()
			pnl.List:SetTextInset( 25 )
			pnl.List.Populate = function( o, search )
				o:Clear()
				local data = PLUGIN.ServerAdverts
				
				search = search or ""
				for I = 1, #data do
					if string.find( data[ I ].Display:lower(), search:lower() ) then
						o:AddRow( { data[ I ].Display }, data[ I ] )
					end
				end
				o:SortByColumn( 1 )
				o:Validate()
			end
			
			pnl.List.LineSelected = function( lst, disp, data, line )
				PLUGIN.WorkingAdvert = data;
				exsto.Menu.OpenPage( PLUGIN.EditPage )
				exsto.Menu.EnableBackButton()
			end
			
			pnl.List.OnRowRightClick = function( lst, lineID, line )
				local menu = DermaMenu()
					menu:AddOption( "Enable/Disable", function()
						local sender = exsto.CreateSender( "ExToggleAdvert" )
							sender:AddString( line.Info.Data.ID )
						sender:Send()
					end )
					menu:AddOption( "Delete", function()
						local sender = exsto.CreateSender( "ExDeleteAdvert" )
							sender:AddString( line.Info.Data.ID )
						sender:Send()
					end )
				menu:Open()
			end
			
		-- Create new button.
		pnl.New = vgui.Create( "DImageButton", pnl )
			pnl.New:SetImage( "exsto/add.png" )
			pnl.New:SetSize( 32, 32 )
			pnl.New:SetPos( 225, 345 ) -- Absolute positioning, fuck me.
			pnl.New.DoClick = function( b )
				PLUGIN.ListPage:InputText( {
					Text = { COLOR.MENU, "Please input a ", COLOR.NAME, "unique ID", COLOR.MENU, " for the advert to be created.  This ", COLOR.NAME, "ID", COLOR.MENU, " is used when using console and chat commands to modify adverts." },
					Yes = function( val )
						PLUGIN.WorkingAdvert = { ID = val } 
						update( 5, val ) -- Bones
						PLUGIN.WorkingAdvert = nil
					end,
				} )
			end
			
	end
	
	local function editOnShowtime( obj )
		local pnl = obj.Content
		local loc
		for l, id in pairs( PLUGIN.Locations ) do
			if id == PLUGIN.WorkingAdvert.Location then loc = l break end
		end
		
		pnl.Cat.Header:SetText( PLUGIN.WorkingAdvert.Display )
		pnl.Display:SetValue( PLUGIN.WorkingAdvert.Display )
		pnl.Message:SetValue( PLUGIN.WorkingAdvert.Contents )
		pnl.Location:SetValue( loc )
		pnl.Delay:SetValue( PLUGIN.WorkingAdvert.Delay )
		
	end
	
	local function editInit( pnl )
		pnl.Cat = pnl:CreateCategory( "" )
		
		pnl.Cat:CreateTitle( "Display" )
		pnl.Cat:CreateHelp( "Sets the display name for the advert, for easer identification" )
		pnl.Display = pnl.Cat:CreateTextChoice()
		pnl.Display.OnTextChanged = function( e )
			update( 1, e:GetValue() )
		end
		
		pnl.Cat:CreateSpacer()
		
		pnl.Cat:CreateTitle( "Message" )
		pnl.Cat:CreateHelp( "The contents of the ad.  Colors can be designated by appending [c=r,g,b,a] before text.  Example: [c=100,0,0,255] Red Text" )
		pnl.Message = pnl.Cat:CreateTextChoice()
		pnl.Message.OnTextChanged = function( e )
			update( 2, e:GetValue() )
		end
		
		pnl.Cat:CreateSpacer()
		
		pnl.Cat:CreateTitle( "Location" )
		pnl.Cat:CreateHelp( "The location of the advertisement.  The following options are 'center' for center of the screen, 'chat' for the chat, and 'banner' for a top screen slide banner." )
		pnl.Location = pnl.Cat:CreateMultiChoice()
		pnl.Location.OnValueSet = function( e, val )
			update( 3, val )
		end
		for _, loc in ipairs( { "chat", "banner", "center" } ) do pnl.Location:AddChoice( loc, loc ) end
		
		pnl.Cat:CreateSpacer()
		
		pnl.Cat:CreateTitle( "Delay" )
		pnl.Cat:CreateHelp( "Sets the delay between advertisements." )
		pnl.Delay = pnl.Cat:CreateNumberChoice()
		pnl.Delay:SetMin( 0.1 )
		pnl.Delay:SetMax( 100 )
		pnl.Delay:SetUnit( "Delay (minutes)" )
		pnl.Delay.OnValueSet = function( e, val )
			update( 4, tostring( val ) )
		end
		
	end
		
	function PLUGIN:ReceiveAdverts( reader )
		self:Debug( "Received adverts from the server." , 1 ) 
		self.ServerAdverts = {} 
		for I = 1, reader:ReadShort() do
			local tmp = {
				ID = reader:ReadString();
				Display = reader:ReadString();
				Contents = reader:ReadString();
				Location = reader:ReadShort();
				Delay = reader:ReadShort();
				--Data = reader:ReadTable();
				Enabled = reader:ReadBool();
			}
			table.insert( self.ServerAdverts, tmp )
		end
		
		-- Should we enable the banner?
		self.Banner:SetVisible( false )
		for _, data in ipairs( self.ServerAdverts ) do
			if data.Location == 2 then self.Banner:SetVisible( true ) break end
		end
		
		-- Don't continue if they haven't accessed our page yet.
		if not IsValid( self.ListPage.Content ) then return end
		
		self.ListPage.Content.List:Populate()
		
		if PLUGIN.WorkingAdvert then -- Update the entry that hes on.
			for _, data in ipairs( self.ServerAdverts ) do
				if data.ID == PLUGIN.WorkingAdvert.ID then PLUGIN.WorkingAdvert = self.ServerAdverts[ _ ] break end
			end
			
			editOnShowtime( self.EditPage )
		end
	end
	PLUGIN:CreateReader( "ExSendAdverts", PLUGIN.ReceiveAdverts )
	
	function PLUGIN:StartBannerAd( reader )
		local id = reader:ReadString()
		local str = reader:ReadString()
		local msg = exsto.CreateColoredPrint( str )
		
		self:Debug( "Starting banner id '" .. id .. "' with message '" .. str .. "'", 1 )
		if not self.Banner:IsVisible() then self.Banner:SetVisible( true ) end
		
		-- Construct the length of this banner
		local w = 10
		surface.SetFont( "ExGenericText16" )
		for _, d in ipairs( msg ) do
			if type( d ) == "string" then w = w + surface.GetTextSize( d ) end
		end
		
		table.insert( self.Banner.Queue, { ID = id, Contents = msg, X = ScrW(), W = w, CanGo = #self.Banner.Queue == 0 and true or false } )
	end
	PLUGIN:CreateReader( "ExStartBannerAd", PLUGIN.StartBannerAd )
	
	function PLUGIN:StartCenterAd( reader )
		local id = reader:ReadString()
		local str = reader:ReadString()
		local msg = exsto.CreateColoredPrint( str )
		
		self:Debug( "Starting center ad id '" .. id .. "' with message '" .. str .. "'", 1 )
		
		local label = vgui.Create( "ExText", self.CenterZone )
			label:IgnoreSelfWide()
			label:SetMaxWide( self.CenterZone:GetWide() )
			label:SetFont( "ExGenericText18" )
			label:SetText( unpack( msg ) )
			label:SizeToContents()
			label:SetWide( label:GetProjectedWide() )
			label:SetVisible( false )
			
			-- Position
			local w, h = label:GetSize()
			
			label:SetPos( ( self.CenterZone:GetWide() / 2 ) - ( w / 2 ), ( 10 + self.CenterZone.HMOD ) )
			self.CenterZone.HMOD = self.CenterZone.HMOD + h + 5
			
			local id = table.insert( self.CenterZone.Labels, label )
			label.ID = id
			
		exsto.Animations.Create( label )
		label:SetVisible( true )
		timer.Simple( 8, function() -- This fucking sucks but whatever.  I no longer have a desire to work on it
			label:SetVisible( false )
			
			timer.Simple( 0.5, function()
				label:Remove() 
				table.remove( self.CenterZone.Labels, id )
				
				self.CenterZone.HMOD = 0
				for I = 1, #self.CenterZone.Labels do
					if IsValid( self.CenterZone.Labels[ I ] ) then
						self.CenterZone.Labels[ I ]:SetPos( ( self.CenterZone:GetWide() / 2 ) - ( w / 2 ), ( 10 + self.CenterZone.HMOD ) )
						self.CenterZone.HMOD = self.CenterZone.HMOD + h + 5
					end
				end
			end )
		end )
	end
	PLUGIN:CreateReader( "ExStartCenterAd", PLUGIN.StartCenterAd )
	
	function PLUGIN:Think()
	
	end

	function PLUGIN:Init()
		self.ListPage = exsto.Menu.CreatePage( "advertlist", advertInit )
			self.ListPage:SetTitle( "Adverts" )
			self.ListPage:OnShowtime( function( obj )
				exsto.CreateSender( "ExRequestAdverts" ):Send()
			end )
			self.ListPage:OnSearchTyped( function( e ) self.ListPage.Content.List:Populate( nil, e:GetValue() ) end )
			
		self.EditPage = exsto.Menu.CreatePage( "advertedit", editInit )
			self.EditPage:SetTitle( "Adverts" )
			self.EditPage:OnShowtime( editOnShowtime )
			self.EditPage:SetUnaccessable()
			self.EditPage:SetFlag( "advertlist" )
			self.EditPage:SetBackFunction( function( obj ) exsto.Menu.OpenPage( self.ListPage ) end )
			
		-- Create center holder
		self.CenterZone = vgui.Create( "DPanel" )
			self.CenterZone.Paint = function() end
			self.CenterZone:SetWide( ScrW() - ( ScrW() / 4 ) )
			self.CenterZone:SetTall( ScrH() - ( ScrH() / 1.5 ) )
			self.CenterZone:SetPos( ( ScrW() / 2 ) - ( self.CenterZone:GetWide() / 2 ), ( ( ScrH() / 2 ) - ( self.CenterZone:GetTall() / 2 ) ) - 200 )
			self.CenterZone.HMOD = 0
			self.CenterZone.Labels = {}
			
		-- Create the banner VGUI
		self.Banner = vgui.Create( "DPanel" )
			self.Banner:SetSkin( "Exsto" )
			self.Banner:SetSize( ScrW(), 30 )
			self.Banner:SetPos( 0, 0 )
			self.Banner.Queue = {}
			self.Banner:SetVisible( false )
			self.Banner.Think = function( b )
				if not b:IsVisible() then return end
				if #b.Queue == 0 then return end
				
				-- We're visible, meaning that there are banner advertisements.
				for i = 1, #b.Queue do
					if b.Queue[ i ] then
						if b.Queue[ i ].CanGo then -- We can slide to the left.  Do so.
							b.Queue[ i ].X = b.Queue[ i ].X - ( RealFrameTime() * 40 )
						end
						
						-- Check and send forth latter queues if they can go.
						if not b.Queue[ i ].CanGo and ( ( i - 1 ) != 0 ) and ( ( b.Queue[ i - 1 ].X + b.Queue[ i - 1 ].W ) < b:GetWide() ) then
							b.Queue[ i ].CanGo = true
						end
						
						-- Remove when they're gone
						if ( -1 * b.Queue[ i ].X ) > b.Queue[ i ].W then
							table.remove( b.Queue, i )
						end
					end
				end
			end
			self.Banner.PaintOver = function( b )
				surface.SetFont( "ExGenericText16" )
				
				-- Loop through the queue
				for i = 1, #b.Queue do
					
					-- We want to loop through our message contents, and start drawing each of the segments.
					local workingW, workingC = b.Queue[ i ].X, nil
					for I = 1, #b.Queue[ i ].Contents do
						if type( b.Queue[ i ].Contents[ I ] ) == "string" then
							draw.SimpleText( b.Queue[ i ].Contents[ I ], "ExGenericText16", workingW, 8, workingC, TEXT_ALIGN_LEFT )
							workingW = workingW + surface.GetTextSize( b.Queue[ i ].Contents[ I ] )
						else -- This is a color
							workingC = b.Queue[ i ].Contents[ I ]
						end
					end
				end
			end

			
		self.BannerLogo = vgui.Create( "DImage", self.Banner )
			self.BannerLogo:Dock( RIGHT )
			self.BannerLogo:SetSize( 128, 32 )
			self.BannerLogo:SetImage( "exsto/exlogo_qmenu.png" )
			
		self.Locations = {
			chat = 1;
			banner = 2;
			center = 3;
		}
		self.CenterQueue = {}
			
	end
	
end

PLUGIN:Register()