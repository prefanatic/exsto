--[[
	Exsto
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

-- GOD DAMNITF

local qm = {
	Shadow = Material( "exsto/gradient.png" );
}

local function playerObjectClick( lst, lineID, line )
	timer.Simple( 0.01, function()
		-- TODO: Multiselect.  For now, just go.
		if line._PREVENTCLICK then return end
				
		qm.ExecTbl[ "PLAYER" ] = { line.Data.Ply }
		
		qm.Parent.ComWindow:Populate( "..." )
		
		qm.Parent.ComWindow:SetVisible( true )
		qm.Parent.ComWindow:SetPos( 4, 28 )
		
		qm.Parent.PlayerListScroller:SetPos( -qm.Parent:GetWide() - 2, 28 )
		
		-- Button stuff
		qm.Parent.BackButton._Disabled = false
		qm.Parent.BackButton:SetImage( "exsto/back_highlight.png" )
		qm.Parent.BackButton._WorkingIndex = -1
	end )
end

local function playerObjectRightClick( lst, lineID, line )
	-- Breaks exsto's modular design, but I don't care.
	if !exsto.Commands[ "kick" ] or !exsto.Commands[ "ban" ] then return end
		
	-- Prevent playerObjectClick from running because OnRowRightClick gets called with OnRowClick.... What the fuck!
	line._PREVENTCLICK = true
	timer.Simple( 0.02, function() line._PREVENTCLICK = false end )
	
	local menu = DermaMenu()
		menu:AddOption( "Kick", function() RunConsoleCommand( exsto.Commands[ "kick" ].CallerID, line.Data.Ply:Nick() ) qm.Parent.PlayerList:Update() end )
		menu:AddOption( "Ban", function() RunConsoleCommand( exsto.Commands[ "ban" ].CallerID, line.Data.Ply:Nick() ) qm.Parent.PlayerList:Update() end )
	menu:Open()
end

local function categoryPaint( cat )
	surface.SetFont( "ExGenericText19" )
	local w, h = surface.GetTextSize( cat.Header:GetValue() )
	
	surface.SetDrawColor( 195, 195, 195, 195 )
	surface.DrawLine( w + 10, ( cat.Header:GetTall() / 2 ), cat.Header:GetWide() - 5, ( cat.Header:GetTall() / 2 ) )
end

local function buttonBackClick( btn )
	if !btn._WorkingIndex then return end
	if btn._Disabled then return end
	
	if ( btn._WorkingIndex - 1 ) == 0 then -- We need to go back to the command list.
		local currentBox = qm.Parent.ComWindow.Objects[ btn._WorkingIndex ]
			currentBox:SetPos( qm.Parent:GetWide() + 2, 0 )
			
		-- Bring back the command list.
		qm.Parent.ComWindow.CommandList:SetPos( 0, 0 )
		qm.Parent.ComWindow:Clean()
		btn._WorkingIndex = -1
		return
	end
	
	if ( btn._WorkingIndex == -1 ) then -- We're on the command list, and we need to go to players.
		qm.Reset( true )
		return
	end
	
	-- If we made it through all those special instances, just move back a page.
	local currentBox = qm.Parent.ComWindow.Objects[ btn._WorkingIndex ]
	local prevBox = qm.Parent.ComWindow.Objects[ btn._WorkingIndex - 1 ]
		currentBox:SetPos( qm.Parent:GetWide() + 2, 0 )
		prevBox:SetPos( 0, 0 )
		prevBox:SetVisible( true )
		
		table.remove( qm.ExecTbl, btn._WorkingIndex - 1 )
		
		btn._WorkingIndex = btn._WorkingIndex - 1
		
	return
end

local function newPanelClick( btn )

	-- Lets create a derma menu of the pages that we have.+
	local pgs = exsto.Menu.GetPages();
	local menu = DermaMenu()
	
	for _, obj in ipairs( pgs ) do
		if obj:GetID() != "quickmenu" then -- We don't want to open ourself :P
			menu:AddOption( obj:GetTitle(), function() exsto.Menu.OpenPage( obj ) end )
		end
	end
	menu:Open()
end		

local function pntShadow( pnl )
	surface.SetMaterial( qm.Shadow )
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.DrawTexturedRect( 0, 0, pnl:GetWide(), 9 )
end

function exsto.InitQuickMenu( pnl )
	qm.Parent = pnl
	
	-- Create the buttons up top yo.
	pnl.BackButton = exsto.CreateImageButton( 6, 4, 32, 32, "back_norm.png", pnl )
		pnl.BackButton._Disabled = true
		pnl.BackButton.DoClick = buttonBackClick
		
	-- Create the new panel button
	--pnl.NewPanel = exsto.CreateButton( 0, 0, 26, 20, "+", pnl )
		--pnl.NewPanel:MoveRightOf( pnl.BackButton, 6 )
		--pnl.NewPanel.DoClick = newPanelClick
		
	-- Logo
	pnl.Logo = vgui.Create( "DImage", pnl )
		pnl.Logo:SetPos( pnl:GetWide() - 129, 1 )
		pnl.Logo:SetSize( 128, 32 )
		pnl.Logo:SetImage( "exsto/exlogo_qmenu.png" )
		
	-- Create search box
	pnl.Search = exsto.CreateTextEntry( 4, pnl:GetTall() - 30, pnl:GetWide() - 8, 24, pnl )
		pnl.Search.OnTextChanged = function( entry )
			-- If we're typing, we should lock the menu open.
			exsto.Menu.OpenLock = true
			
			local loc = qm.Parent.BackButton._WorkingIndex
			local disabled = qm.Parent.BackButton._Disabled
			
			if disabled then -- We're on the player list.  Search in it.
				qm.Parent.PlayerList:CreateContent( entry:GetValue():lower() )
			elseif loc == -1 then -- We're working in the command list.
				qm.Parent.ComWindow:Populate( "...", entry:GetValue():lower() )
			end
		end
		pnl.Search.OnEnter = function( entry )
			-- Reset the search
			entry:SetText( "" )
			entry:OnTextChanged()
		end
		pnl.Search.DoClick = function( entry )
			exsto.Menu.OpenLock = true
		end

	-- Create the player list
	pnl.PlayerListScroller = vgui.Create( "DScrollPanel", pnl )
		pnl.PlayerListScroller:SetPos( 4, 28 )
		pnl.PlayerListScroller:SetSize( pnl:GetWide() - 8, pnl:GetTall() - 65 )
		
	local function scrollHandler( p, dlta )
		print( 'ldkfjdsf', dlta )
		return pnl.PlayerListScroller:OnMouseWheeled( dlta )
	end
		
	pnl.PlayerList = vgui.Create( "DPanelList", pnl.PlayerListScroller )
		pnl.PlayerList:SetSize( pnl:GetWide() - 8, pnl:GetTall() - 65 )
		pnl.PlayerList:SetPos( 0, 0 )
		pnl.PlayerList:SetSpacing( 5 )
		pnl.PlayerList:SetPadding( 5 )
		pnl.PlayerList:EnableHorizontal( false )
		--pnl.PlayerList:EnableVerticalScrollbar( true )
		pnl.PlayerList.OnMouseWheeled = scrollHandler
		
		pnl.PlayerList.Paint = function( pnl )
			pnl:GetSkin().tex.Input.ListBox.Background( 0, 0, pnl:GetWide(), pnl:GetTall() );
		end
		
		pnl.PlayerList.PaintOver = pntShadow
		
		-- We need to format a table with ranks and all the players in that rank for the collapseable cats.
		pnl.PlayerList.Format = function( lst )
			lst.Objects = {} 
			
			-- Loop through players
			local rnk
			for _, v in ipairs( player.GetAll() ) do
				rnk = v:GetRank()
				
				-- Create a category for it.
				if !lst.Objects[ rnk ] then lst.Objects[ rnk ] = {} end
				
				-- Throw our player into that.
				table.insert( lst.Objects[ rnk ], { Ply = v, I = exsto.Ranks[ rnk ].Immunity } )
			end
		end
		
		pnl.PlayerList.ClearContent = function( lst )
			if !lst.Categories then lst.Categories = {} return end
			for rnk, pnl in pairs( lst.Categories ) do
				pnl:Remove()
			end
			lst.Categories = {}
		end
		
		-- We need to create the content for the player list with our formatted table.
		pnl.PlayerList.CreateContent = function( lst, search )
			lst:ClearContent()
			
			-- Loop through the formatted table
			for rank, plyTbl in SortedPairsByMemberValue( lst.Objects, "Immunity", true ) do
				
				-- Create the collapsible category for it.
				local cat = exsto.CreateCollapseCategory( 0, 0, lst:GetWide(), 50, exsto.Ranks[ rank ].Name, pnl.PlayerList )
					cat.Header:SetTextColor( Color( 0, 180, 255, 255 ) )
					cat.Header:SetFont( "ExGenericText19" )
					cat.Header.UpdateColours = function( self, skin ) end
					cat.Header.OnMousePressed = function( c )
						--cat:Toggle() -- Fuck you garry.
					end
					cat.Header.OnMouseWheeled = scrollHandler
					cat.Paint = categoryPaint
				
				-- Now, we need to go through and add our playes to it.
				cat.PlyList = exsto.CreateListView( 0, 0, 0, 0, cat )
					cat.PlyList:AddColumn( "" )
					cat.PlyList:SetHideHeaders( true )
					cat.PlyList:SetDataHeight( 30 )
					cat.PlyList:DisableScrollbar() -- Shouldn't need it.  We're going to resize based on content anyways.
					cat.PlyList.OnRowSelected = playerObjectClick
					cat.PlyList.OnRowRightClick = playerObjectRightClick -- Thank god for Garry making this override.  Half expected it not to exist.
					cat.PlyList.OnMouseWheeled = scrollHandler
					cat.PlyList.Paint = function() end
				
				local count = 0
				for _, data in ipairs( plyTbl ) do
					if string.find( data.Ply:Nick(), search or "" ) then
						local obj = cat.PlyList:AddLine( data.Ply:Nick() )
							obj.Columns[1]:SetFont( "ExGenericTextMidBold16" )
							obj.Data = data
						count = count + 34
					end
				end
				
				-- Set the list's size based off our content we just added to it.
				cat.PlyList:SetSize( cat:GetWide(), count )
				--cat.PlyList:SizeToContents()
				
				-- Set the contents of the collapsable to the list.
				cat:SetContents( cat.PlyList )
				cat:SetExpanded( true )
				--cat:SetTall( count )
				cat:SetTall( count + cat.Header:GetTall() )
				
				-- And add the category to the DIconLayout
				lst:AddItem( cat )
				
				lst.Categories[ rank ] = cat
				
			end
		end
		
		pnl.PlayerList.Update = function( lst )
			lst:Format()
			lst:CreateContent()
		end
		
		exsto.Animations.CreateAnimation( pnl.PlayerList )
		exsto.Animations.CreateAnimation( pnl.PlayerListScroller )
		
	qm.CreateCommandWindow( pnl )
	
end

function qm.Reset( bool, disableAnim )
	if bool then
		qm.Parent.PlayerListScroller.OldFuncs.SetPos( qm.Parent.PlayerListScroller, -qm.Parent:GetWide() - 2, 28 )
		qm.Parent.PlayerListScroller.Anims[ 1 ].Current = -qm.Parent:GetWide() - 2
		qm.Parent.PlayerListScroller.Anims[ 1 ].Last = -qm.Parent:GetWide() - 2
		qm.Parent.PlayerListScroller:SetPos( 4, 28 )
	else
		qm.Parent.PlayerListScroller.OldFuncs.SetPos( qm.Parent.PlayerListScroller, 4, 28 )
		qm.Parent.PlayerListScroller.Anims[ 1 ].Current = 4
		qm.Parent.PlayerListScroller.Anims[ 1 ].Last = 4
	end
	
	qm.Parent.PlayerList:Update()

	if disableAnim then
		qm.Parent.ComWindow.OldFuncs.SetPos( qm.Parent.ComWindow, qm.Parent:GetWide() + 2, 28 )
		qm.Parent.ComWindow.Anims[ 1 ].Current = qm.Parent:GetWide() + 2
		qm.Parent.ComWindow.Anims[ 1 ].Last = qm.Parent:GetWide() + 2
	else
		qm.Parent.ComWindow:SetPos( qm.Parent:GetWide() + 2, 28 )
	end
	
	qm.Parent.ComWindow:Cleanup()
	
	qm.ExecTbl = {}
	qm.Parent.SelectedItem = nil
	
	qm.Parent.BackButton._Disabled = true
	qm.Parent.BackButton:SetImage( "exsto/back_norm.png" )
	
	qm.Parent.Search:SetText( "" )
end
exsto.QuickMenuReset = qm.Reset

function qm.Execute()
	local call = qm.Parent.SelectedItem.CallerID
	local plys = table.Copy( qm.ExecTbl["PLAYER"] )
		qm.ExecTbl["PLAYER"] = nil
	
	for index, ply in ipairs( plys ) do
		RunConsoleCommand( call, ply:Nick(), unpack( qm.ExecTbl ) )
	end
	
	timer.Simple( 0.01, function() qm.Reset(true) end )
end

function qm.CreateCommandWindow( pnl )
	-- Create the command window.

	pnl.ComWindow = exsto.CreatePanel( pnl:GetWide() + 2, 28, pnl:GetWide() - 8, pnl:GetTall() - 65, Color( 255, 255, 255, 255 ), pnl )
	pnl.ComWindow:SetVisible( false )
	
	pnl.ComWindow.Objects = {}
	qm.ExecTbl = {}
	
	--pnl.ComHolder = exsto.CreateComboBox( 0, 0, pnl.ComWindow:GetWide(), pnl.ComWindow:GetTall(), pnl.ComWindow )
	
	pnl.ComWindow.Cleanup = function( pnl )
		for _, obj in ipairs( pnl.Objects ) do
			if obj and obj:IsValid() then
				if _ == #pnl.Objects then
					timer.Simple( 0.4, function() obj:Remove() end ) -- To remove after the animation is done.
				else
					obj:Remove() 
				end
			end
		end
		pnl.ExecTbl = {}
		pnl.Objects = {}
		pnl.FromCommandList = false
		
		if pnl.CommandList then
			pnl.CommandList:SetPos( 0, 0 )
		end
	end
	
	local function rowSelectFunc( combobox, lineID, line )
		if line.Type == "COMMAND" then -- If this is a command
			qm.Parent.SelectedItem = line.Data
			-- Check if there is anything for us to do.
			if #qm.Parent.SelectedItem.ReturnOrder == 1 then
				qm.Execute()
				return
			end
			
			combobox:SetPos( -combobox:GetWide() - 2, 0 )
			pnl.ComWindow:Clean()
			pnl.ComWindow:Populate( line.Data )
			pnl.ComWindow.Objects[ 1 ]:SetPos( 0, 0 )
			
			-- Set our button as active.
			pnl.BackButton._Disabled = false
			pnl.BackButton:SetImage( "exsto/back_highlight.png" )
			pnl.BackButton._WorkingIndex = 1
			
			combobox:ClearSelection()
			
			return
		end
		
		table.insert( qm.ExecTbl, line.Data )
		
		local nextComboBox = pnl.ComWindow.Objects[ combobox.Index + 1 ]
		
		if !nextComboBox then -- We've hit the last possible one.  Quit and execute.
			qm.Execute()
			return
		end

		if nextComboBox.Optional then
			-- TODO: Create button to execute and just throw the optionals in.
		end
		
		combobox:SetPos( -combobox:GetWide() - 2, 0 )
		nextComboBox:SetPos( 0, 0 )
		
		combobox:ClearSelection()
		
		-- Set our button as active.
		pnl.BackButton._Disabled = false
		pnl.BackButton:SetImage( "exsto/back_highlight.png" )
		pnl.BackButton._WorkingIndex = combobox.Index + 1
	end
	
	pnl.ComWindow.Clean = function( pnl )
		for _, obj in ipairs( pnl.Objects ) do
			obj:Remove() 
		end
		pnl.Objects = {}
	end
	
	pnl.ComWindow.Populate = function( pnl, data, search )
		if type( data ) == "string" and data == "..." then -- We need to create this list full of commands
			pnl.FromCommandList = true
			
			if !pnl.CommandList then
				pnl.CommandList = exsto.CreateListView( 0, 0, pnl:GetWide(), pnl:GetTall(), pnl )
					pnl.CommandList:AddColumn( "" )
					pnl.CommandList:SetHideHeaders( true )
					pnl.CommandList:SetDataHeight( 30 )
					pnl.CommandList.OnRowSelected = rowSelectFunc
					pnl.CommandList.PaintOver = pntShadow
					exsto.Animations.CreateAnimation( pnl.CommandList )
			else 
				pnl.CommandList:SetVisible( true )
				pnl.CommandList:Clear() 
			end
				
			local comboObj
			for id, comdata in SortedPairsByMemberValue( exsto.Commands, "DisplayName", false ) do
				if comdata.QuickMenu and string.find( comdata.DisplayName, search or "" ) then
					comboObj = pnl.CommandList:AddLine( comdata.DisplayName )
						comboObj.Columns[1]:SetFont( "ExGenericTextMidBold16" )
						comboObj.Type = "COMMAND"
						comboObj.Data = comdata
				end
			end				
			return
		end
		
		-- Create a proper return order w/o players
		local returnOrder = table.Copy( data.ReturnOrder )
		for _, arg in ipairs( data.ReturnOrder ) do
			if data.Args[ arg ] == "PLAYER" then table.remove( returnOrder, _ ) end
		end
		
		local argName, t, comboPnl, comboObj
		for I = 1, #returnOrder do
			argName = returnOrder[ I ]
			t = data.Args[ argName ]
			
			comboPnl = exsto.CreateListView( 0, 0, pnl:GetWide(), pnl:GetTall(), pnl )
				comboPnl:AddColumn( "" )
				comboPnl:SetHideHeaders( true )
				comboPnl:SetDataHeight( 30 )
				comboPnl.PaintOver = pntShadow
				comboPnl.Index = I

			for _, fillData in ipairs( data.ExtraOptionals[ argName ] ) do
				comboObj = comboPnl:AddLine( fillData.Display )
					comboObj.Columns[1]:SetFont( "ExGenericTextMidBold16" )
					comboObj.Type = t
					comboObj.Data = tostring( fillData.Data or fillData.Display )
			end
			
			comboPnl.OnRowSelected = rowSelectFunc
			table.insert( pnl.Objects, comboPnl )
		
			if data.Optional and data.Optional[ argName ] then comboPnl.Optional = true end
			if I != 1 or pnl.FromCommandList then comboPnl:SetPos( pnl:GetWide() + 1, 0 ) end -- If this isn't the first one, set it to the right.
			
			exsto.Animations.CreateAnimation( comboPnl )
		end
		
	end
	
	exsto.Animations.CreateAnimation( pnl.ComWindow )
end

local function playerObjectPaintOver( obj )
	-- TODO
end
