local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Rank Editor",
	ID = "rank-editor",
	Desc = "A plugin that allows management over rank creation.",
	Owner = "Prefanatic",
} )

if SERVER then

	function PLUGIN:Init()
		exsto.CreateFlag( "rankeditor", "Allows users to edit ranks in the menu." )
		
		util.AddNetworkString( "ExPushRankToSrv" )
		util.AddNetworkString( "ExRecImmuneChange" )
		util.AddNetworkString( "ExDelRankFromClient" )
		util.AddNetworkString( "ExUpImmunity" )
		
		self.Echo = exsto.CreateVariable( "ExEchoGroupChanges", "Echo Changes", 0, "Print messages to the chat to all players to notify of group editing in progress." )
			self.Echo:SetBoolean()
			self.Echo:SetCategory( "Group Editor" )
	end
	
	function PLUGIN:PrintEcho( msgTbl )
		if self.Echo:GetValue() == 1 then
			exsto.Print( exsto_CHAT_ALL, unpack( msgTbl ) )
		end
	end
	
	-- Security
	function PLUGIN:ExPushRankToSrv( reader )
		return reader:ReadSender():IsAllowed( "rankeditor" )
	end
	function PLUGIN:ExRecImmuneChange( reader )
		return reader:ReadSender():IsAllowed( "rankeditor" )
	end
	function PLUGIN:ExDelRankFromClient( reader )
		return reader:ReadSender():IsAllowed( "rankeditor" )
	end
	function PLUGIN:ExUpImmunity( reader )
		return reader:ReadSender():IsAllowed( "rankeditor" )
	end

	
	function PLUGIN:DeleteRank( reader )
		local id = reader:ReadString()
		local rank = exsto.Ranks[ id ]
		
		self:PrintEcho( { COLOR.NAME, reader:ReadSender():Nick(), COLOR.NORM, " has deleted the rank ", COLOR.NAME, rank.Name } )
		
		exsto.RankDB:DropRow( id, function() 
			exsto.aLoader.Initialize()
		end )
		
	end
	PLUGIN:CreateReader( "ExDelRankFromClient", PLUGIN.DeleteRank )
	
	function PLUGIN:CommitChanges( reader )
		local id = reader:ReadString()
		local ply = reader:ReadSender()
		
		-- Echo
		PLUGIN:PrintEcho( { COLOR.NAME, ply:Nick(), COLOR.NORM, " has updated the rank ", COLOR.NAME, exsto.Ranks[ id ] and exsto.Ranks[ id ].Name or id } )

		-- Write the data
		PLUGIN:WriteAccess( id, reader:ReadString(), reader:ReadString(), reader:ReadColor(), reader:ReadTable(), function( q, d )
			
			-- Reload Exsto's access controllers.  I really hope this doesn't break anything.
			exsto.aLoader.Initialize()
			
			-- If everything is successful, lets reload.
			if exsto.aLoader.Errors and table.Count( exsto.aLoader.Errors ) == 0 then
				
				-- Reload the rank editor.
				hook.Call( "ExOnRankCreate", nil, id )
			else
				-- We've got some errors.  We need to send these to the client and then notify the laddy who was making this rank he sucks.
				exsto.SendRankErrors( ply )
			end
			
		end )
	end
	PLUGIN:CreateReader( "ExPushRankToSrv", PLUGIN.CommitChanges )
	
	function PLUGIN:UpdateImmunity( reader )
		local id = reader:ReadString()
		local im = reader:ReadShort()
		
		self:Debug( "Updating immunity for '" .. id .. "' to '" .. im .. "'", 1 )
		exsto.RankDB:AddRow( {
			ID = id;
			Immunity = im;
		} )
	end
	PLUGIN:CreateReader( "ExUpImmunity", PLUGIN.UpdateImmunity )

	function PLUGIN.WriteImmunityData( reader )
		exsto.RankDB:AddRow( {
			ID = reader:ReadString();
			Immunity = reader:ReadShort();
		} )
	end
	--exsto.CreateReader( "ExRecImmuneChange", PLUGIN.WriteImmunityData )
	
	function PLUGIN:ExClientData( hook, ply, data )
		if hook == "ExRecImmuneChange" or hook == "ExRecRankData" then
			if !ply:IsAllowed( "rankeditor" ) then return false end
		end		
	end
	
	function PLUGIN:WriteImmunity( id, imm )
		exsto.RankDB:AddRow( {
			ID = id;
			Immunity = num;
		} )
	end
	
	function PLUGIN:WriteAccess( id, name, derive, color, flagsallow, callback )
		exsto.RankDB:AddRow( {
			Name = name;
			ID = id;
			Parent = derive;
			Color = von.serialize( color );
			FlagsAllow = von.serialize( flagsallow );
			Immunity = exsto.Ranks[ id ] and exsto.Ranks[ id ].Immunity or 10;
		}, callback )
	end

elseif CLIENT then

	local function updateDerives( avoid )
		local pnl = PLUGIN.Page.Content
		if !pnl then return end
		
		pnl.Derive:Clear()
		for ID, data in pairs( exsto.Ranks ) do
			if ID != "srv_owner" and ( avoid and ID != avoid ) then 
				pnl.Derive:AddChoice( data.ID .. " (" .. data.Name .. ")" )
			end
		end
		pnl.Derive:AddChoice( "NONE" )
	end

	local function updateContent( rank, updating )
		local pnl = PLUGIN.Page.Content
		
		if updating and PLUGIN.WorkingRank then -- We need to hook back into what we just were using.
			PLUGIN.WorkingRank = exsto.Ranks[ PLUGIN.WorkingRank.ID ]
		else
			PLUGIN.WorkingRank = rank 
		end
		
		local parentName = exsto.Ranks[ rank.Parent ] and exsto.Ranks[ rank.Parent ].Name or "UNKNOWN"
		
		updateDerives( rank.ID )
		
		pnl.RankSelect:SetValue( rank.Name )
		pnl.RankSelect:SetToolTip( "Exsto Identifier: " .. rank.ID )
		pnl.RankName:SetText( rank.Name )
		pnl.Derive:SetValue( rank.Parent .. " (" .. parentName .. ")" )
		pnl.RankColor:SetColor( rank.Color )
		pnl.RankText:SetTextColor( rank.Color )
		pnl.Flags:Populate( rank )
		
		pnl.OverlayPanel:SetVisible( false )
		
		-- Set the delete button accordingly.  We need to make sure NOBODY derives off us.
		pnl.DeleteRank._Disabled = false
		pnl.DeleteRank:SetImage( "exsto/trash.png" )
		
		for id, rdata in pairs( exsto.Ranks ) do
			if rdata.Parent == rank.ID then -- Oh noes
				pnl.DeleteRank._Disabled = true
				pnl.DeleteRank:SetImage( "exsto/trash_disabled.png" )
				return
			end
		end
	end

	local function refreshEditor()
		local pnl = PLUGIN.Page.Content
		if !pnl then return end
		
		local derive = pnl.Derive:GetValue()
		
		pnl.RankSelect:Clear()
		pnl.OverlayPanel:SetVisible( true )
		-- Populate the RankSelect with our ranks.
		for ID, data in SortedPairsByMemberValue( exsto.Ranks, "Immunity", false )  do
			if ID != "srv_owner" then 
				pnl.RankSelect:AddChoice( data.Name, data ) 
			end
		end
		
		updateDerives()
		
		if PLUGIN.WorkingRank then
			updateContent( PLUGIN.WorkingRank, true )
		end

	end

	function PLUGIN:ExReceivedRanks()
		-- Called when exsto receives client ranks.
		self.Updating = false
		refreshEditor()
	end

	-- Error checking.  We should do simple stuff here.  The majority of the error checking will take place on the server.
	local function errors( rank, pnl )
		-- TODO: Print notification that this occurs.
		if pnl.RankName:GetValue() == "" then return true end
		return false
	end

	--[[ UPDATE PUSHING FUNCTIONS ]]
	local function pushUpdate()
		local rank = PLUGIN.WorkingRank
		local pnl = PLUGIN.Page.Content
		if !rank then return end -- We weren't working with anything.
		if errors( rank, pnl ) then return end
		
		PLUGIN.Updating = true

		PLUGIN:Debug( "Updating rank content for '" .. rank.Name .. "'" )
		local sender = exsto.CreateSender( "ExPushRankToSrv" )
			sender:AddString( rank.ID )
			sender:AddString( rank.Name )
			sender:AddString( rank.Parent )
			sender:AddColor( pnl.RankColor:GetColor() )
			sender:AddTable( rank.FlagsAllow )
		sender:Send()
		
		-- Also, immunity.  If this is a new rank or somethin.
		if !rank.Immunity then
			local sender = exsto.CreateSender( "ExRecImmuneChange" )
				sender:AddString( rank.ID )
				sender:AddShort( 10 )
			sender:Send()
		end
	end
	
	local function editorRankSelected( box, index, value, data )
		if box._IgnoreSelect then box._IgnoreSelect = false return end
		
		box.WorkingID = index
		
		-- Push the rank update to server, if we did so.
		if !PLUGIN.Updating then
			pushUpdate()
		end
		
		updateContent( data )
	end
	
	local function flagIndicator( line )
		if !PLUGIN.WorkingRank then return end
		surface.SetDrawColor( 255, 255, 255, 255 )
		if line.Info.Data.Status == "allowed" then surface.SetMaterial( PLUGIN.Materials.Green ) end
		if line.Info.Data.Status == "open" then surface.SetMaterial( PLUGIN.Materials.Red ) end
		if line.Info.Data.Status == "locked" then surface.SetMaterial( PLUGIN.Materials.Grey ) end
		
		surface.DrawTexturedRect( 5, (line:GetTall() / 2 ) - 3, 8, 8 )
	end
	
	local function flagHandler( lst, display, data, line )
		local status = line.Info.Data.Status
		-- if our status is open, allow it!
		if status == "open" then
			line.Info.Data.Status = "allowed"
			table.insert( PLUGIN.WorkingRank.FlagsAllow, line.Info.Display[1] )
		elseif status == "allowed" then -- otherwise, open it up.
			line.Info.Data.Status = "open"
			for _, flag in ipairs( PLUGIN.WorkingRank.FlagsAllow ) do
				if flag == line.Info.Display[1] then table.remove( PLUGIN.WorkingRank.FlagsAllow, _ ) end
			end
		end
		
	end
	
	local function flagPopulate( lst, rank )

		lst:Clear()
		local status = "open"
		for flag, desc in SortedPairs( exsto.Flags ) do
			-- Do some flag status checking first.
			if table.HasValue( exsto.GetRankFlags( rank.ID ), flag ) then status = "allowed" end
			if table.HasValue( exsto.GetInheritedFlags( rank.ID ), flag ) then status = "locked" end
			
			local line = lst:AddRow( { flag }, {Desc = desc, Status = status } )
				line:SetToolTip( desc )
			status = "open" -- reset.  Why didn't I realize this earlier :/
		end
	end
	
	local function createNewRank()		
		PLUGIN.Page:InputText( {
			Text = { COLOR.MENU, "Please create an ", COLOR.NAME, "unique ID", COLOR.MENU, " for your rank.  It must not contain any spaces, and it should be accurate based on the rank you are creating.  ", COLOR.NAME, "This cannot be changed later." },
			Yes = function( val ) 
				val = val:lower():Replace( " ", "_" )
				
				exsto.Ranks[ val ] = {
					Name = "Type a name!";
					ID = val;
					Parent = "NONE";
					Color = COLOR.NAME;
					FlagsAllow = {};
				}
		
				PLUGIN.WorkingRank = exsto.Ranks[ val ];
				refreshEditor()		
			end,
			No = function() end
		} )
	end

	local function deleteRank( self )
		if self._Disabled then
			-- TODO: Tooltips!
			return
		end
		
		-- Otherwise, delete this asshole.
		local sender = exsto.CreateSender( "ExDelRankFromClient" )
			sender:AddString( PLUGIN.WorkingRank.ID )
		sender:Send()
		
		-- Prempt.  Remove the rank clientside and refresh to save time.
		exsto.Ranks[ PLUGIN.WorkingRank.ID ] = nil;
		PLUGIN.WorkingRank = nil;
		refreshEditor()
	end

	local function editorInit( pnl )
		-- Build our layout.
		local cat = pnl:CreateCategory( "Rank Editor" )
		pnl:DisableScroller()
		pnl.Holder = vgui.Create( "DPanel", cat )
			pnl.Holder.Paint = function() end
			pnl.Holder:Dock( TOP )
			pnl.Holder:DockMargin( 4, 0, 4, 0 )
			pnl.Holder:SetTall( pnl:GetTall() - 35 )

		pnl.Header = vgui.Create( "DPanel", pnl.Holder )
			pnl.Header:Dock( TOP )
			pnl.Header:SetTall( 32 )
			pnl.Header.Paint = function() end
			
		pnl.RankSelect = vgui.Create( "ExComboBox", pnl.Header )
			pnl.RankSelect:SetValue( "Select a rank" )
			pnl.RankSelect:Dock( FILL )
			pnl.RankSelect.OnSelect = editorRankSelected
			pnl.RankSelect:SetToolTip( "Select a rank." )
			pnl.RankSelect:SetFont( "ExGenericText14" )

		pnl.DeleteRank = vgui.Create( "DImageButton", pnl.Header )
			pnl.DeleteRank:SetImage( "exsto/trash_disabled.png" )
			pnl.DeleteRank:SetWide( 32 )
			pnl.DeleteRank:DockMargin( 2, 0, 0, 0 )
			pnl.DeleteRank:Dock( RIGHT )
			pnl.DeleteRank.DoClick = deleteRank
			pnl.DeleteRank:SetToolTip( "Delete a rank." )
			
		pnl.CreateRank = vgui.Create( "DImageButton", pnl.Header )
			pnl.CreateRank:SetImage( "exsto/add.png" )
			pnl.CreateRank:SetWide( 32 )
			pnl.CreateRank:DockMargin( 3, 0, 2, 0 )
			pnl.CreateRank:Dock( RIGHT )
			pnl.CreateRank.DoClick = createNewRank
			pnl.CreateRank:SetToolTip( "Create a rank." )
			
		pnl.RankName = vgui.Create( "DTextEntry", pnl.Holder )
			pnl.RankName:Dock( TOP )
			pnl.RankName:SetTall( 31 )
			pnl.RankName:DockMargin( 0, 4, 0, 0 )
			pnl.RankName:SetTextInset( 10, 0 )
			pnl.RankName:SetToolTip( "Rank name." )
			pnl.RankName:SetFont( "ExGenericText14" )
			pnl.RankName.OnTextChanged = function( entry )
				pnl.RankSelect:SetValue( entry:GetValue() )
				PLUGIN.WorkingRank.Name = entry:GetValue()
			end
			pnl.RankName.OnEnter = function( entry ) pushUpdate() end
				
		
		pnl.Derive = vgui.Create( "DComboBox", pnl.Holder )
			pnl.Derive:SetTall( 32 )
			pnl.Derive:Dock( TOP )
			pnl.Derive:DockMargin( 0, 4, 0, 0 )
			pnl.Derive:SetToolTip( "Set parent." )
			pnl.Derive:SetFont( "ExGenericText14" )
			pnl.Derive.OnSelect = function( d, index, val, data )
				PLUGIN.WorkingRank.Parent = string.Explode( " ", val )[1]
				pushUpdate()
			end
			
		pnl.ColorHolder = vgui.Create( "DPanel", pnl.Holder )
			pnl.ColorHolder:SetTall( 76 )
			pnl.ColorHolder:Dock( TOP )
			pnl.ColorHolder:DockMargin( 6, 4, 6, 0 )
			pnl.ColorHolder.Paint = function() end

		pnl.RankColor = vgui.Create( "DColorMixer", pnl.ColorHolder )
			pnl.RankColor:Dock( FILL )
			pnl.RankColor:DockMargin( 0, 0, 12, 0 )
			pnl.RankColor:SetPalette( false )
			pnl.RankColor:SetAlphaBar( false )
			pnl.RankColor.ValueChanged = function( mixer, col )
				pnl.RankText:SetTextColor( col )
			end
		
		pnl.RankText = vgui.Create( "DLabel", pnl.ColorHolder )
			pnl.RankText:SetText( "ABC\n\nabc\n\n123" )
			pnl.RankText:SetFont( "ExGenericText15" )
			pnl.RankText:SizeToContents()
			pnl.RankText:Dock( RIGHT )
			
		pnl.Flags = vgui.Create( "ExListView", pnl.Holder )
			pnl.Flags:Dock( FILL )
			pnl.Flags:DockMargin( 0, 4, 0, 0 )
			pnl.Flags:SetDataHeight( 22 )
			pnl.Flags:SetTextInset( 25 )
			pnl.Flags:NoHeaders()
			pnl.Flags:LinePaintOver( flagIndicator )
			pnl.Flags.LineSelected = flagHandler
			pnl.Flags.Populate = flagPopulate
			
		pnl.OverlayPanel = vgui.Create( "DPanel", pnl.Holder )
			pnl.OverlayPanel:SetSize( pnl:GetWide(), pnl:GetTall() - 10 )
			pnl.OverlayPanel:MoveBelow( pnl.Header, 1 )
			pnl.OverlayPanel.Paint = function( slf )
				surface.SetDrawColor( 255, 255, 255, 100 )
				surface.DrawRect( 0, 0, slf:GetWide(), slf:GetTall() )
			end
			
		cat:InvalidateLayout( true )
			
		refreshEditor()
	end
	
	local function updateImm( obj )
		local pnl = obj.Content
		
		pnl.List:Clear()
		for id, rank in SortedPairsByMemberValue( exsto.Ranks, "Immunity", false ) do
			if id != "srv_owner" then
				print( rank.Immunity, id )
				local btn = pnl.List:Add( "ExButton" )
					btn:Text( rank.Name )
					btn.ID = id
					btn:Dock( TOP )
					btn:DockMargin( 0, 0, 0, 4 )
					btn:SetTall( 47 )
					btn:MaxFontSize( 44 )
			end
		end
		pnl.List:InvalidateLayout( true )
		pnl.Cat:InvalidateLayout( true )
	end
	
	local function immunityInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Immunity" )
		
		pnl.List = vgui.Create( "DIconLayout", pnl.Cat )
			pnl.List:Dock( TOP )
			pnl.List:DockMargin( 4, 0, 4, 4 )
			pnl.List:SetSpaceY( 20 )
			pnl.List:MakeDroppable( "ImmunityDrop", false )
			pnl.List.OnModified = function()
				local imm = 1
				for _, obj in ipairs( pnl.List:GetChildren() ) do
					local sender = exsto.CreateSender( "ExUpImmunity" )
						sender:AddString( obj.ID )
						sender:AddShort( imm )
					sender:Send()
					
					print( imm, obj.ID )
					
					imm = imm + 1
				end
			end
	end

	function PLUGIN:Init()
		self.Page = exsto.Menu.CreatePage( "rankeditor", editorInit )
			self.Page:SetTitle( "Rank Editor" )
			self.Page:OnBackstage( pushUpdate )
			self.Page:SetIcon( "exsto/rank.png" )
			
		self.ImmunityPage = exsto.Menu.CreatePage( "immunity", immunityInit )
			self.ImmunityPage:SetFlag( "rankeditor" )
			self.ImmunityPage:SetTitle( "Immunity" )
			self.ImmunityPage:SetChildOf( self.Page )
			self.ImmunityPage:OnShowtime( updateImm )
			
		self.Materials = {
			Green = Material( "exsto/green.png" );
			Red = Material( "exsto/red.png" );
			Grey = Material( "exsto/grey.png" );
		}
			
		self.WorkingRank = nil
	end

end

PLUGIN:Register()