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
		qm.Parent.ComWindow:SetPos( 4, 0 )
		
		qm.Parent.PlayerList:SetPos( -qm.Parent:GetWide() - 2, 0 )
		
		-- Button stuff
		qm.Object:EnableBack()
		qm.Parent._WorkingIndex = -1
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
	surface.SetFont( "ExGenericText20" )
	local w, h = surface.GetTextSize( cat.Header:GetValue() )
	
	surface.SetDrawColor( 195, 195, 195, 195 )
	surface.DrawLine( w + 15, ( cat.Header:GetTall() / 2 ), cat.Header:GetWide() - 5, ( cat.Header:GetTall() / 2 ) )
end

local function buttonBackClick( btn )
	if !qm.Parent._WorkingIndex then return end
	
	if ( qm.Parent._WorkingIndex - 1 ) == 0 then -- We need to go back to the command list.
		local currentBox = qm.Parent.ComWindow.Objects[ qm.Parent._WorkingIndex ]
			currentBox:SetPos( qm.Parent:GetWide() + 2, 0 )
			
		-- Bring back the command list.
		qm.Parent.ComWindow.CommandList:SetPos( 0, 0 )
		qm.Parent.ComWindow:Clean()
		qm.Parent._WorkingIndex = -1
		return
	end
	
	if ( qm.Parent._WorkingIndex == -1 ) then -- We're on the command list, and we need to go to players.
		qm.Reset( true )
		return
	end
	
	-- If we made it through all those special instances, just move back a page.
	local currentBox = qm.Parent.ComWindow.Objects[ qm.Parent._WorkingIndex ]
	local prevBox = qm.Parent.ComWindow.Objects[ qm.Parent._WorkingIndex - 1 ]
		currentBox:SetPos( qm.Parent:GetWide() + 2, 0 )
		prevBox:SetPos( 0, 0 )
		prevBox:SetVisible( true )
		
		table.remove( qm.ExecTbl, qm.Parent._WorkingIndex - 1 )
		
		qm.Parent._WorkingIndex = qm.Parent._WorkingIndex - 1
		
	return
end

local function pntShadow( pnl )
	surface.SetMaterial( qm.Shadow )
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.DrawTexturedRect( 0, 0, pnl:GetWide(), 9 )
end

local function onShowtime()
	exsto.QuickMenuReset( false, true )
end

local function searchTyped( entry )
	local loc = qm.Parent._WorkingIndex
	
	if exsto.Menu.BackButton._Disabled then -- We're on the player list.  Search in it.
		qm.Parent.PlayerList:CreateContent( entry:GetValue():lower() )
	elseif loc == -1 then -- We're working in the command list.
		qm.Parent.ComWindow:Populate( "...", entry:GetValue():lower() )
	end
end

local function searchEntered( entry )
	-- Reset the search
	entry:SetText( "" )
	entry:OnTextChanged()
end

function exsto.InitQuickMenu( pnl )
	qm.Parent = pnl
	qm.Object = exsto.Menu.GetPageByID( "quickmenu" )
	
	qm.Object:SetBackFunction( buttonBackClick )
	qm.Object:OnShowtime( onShowtime )
	
	qm.Object:SetSearchable( true )
	qm.Object:OnSearchTyped( searchTyped )
	qm.Object:OnSearchEntered( searchEntered )
	
	pnl.Paint = function() end

	pnl.PlayerList = vgui.Create( "ExPanelScroller", pnl )
		pnl.PlayerList:SetPos( 0, 0 )
		pnl.PlayerList:SetSize( pnl:GetWide() - 2, pnl:GetTall() - 37 )
		
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
			
			if table.Count( lst.Objects ) <= 0 then -- What the fuck?
				qm.Object:Error( "Player list objects counted to be 0.  This most likely means that no ranks currently exist on the client!  This shouldn't happen anymore.  If it does, please report." )
				return
			end
			
			-- Loop through the formatted table
			for rank, plyTbl in SortedPairsByMemberValue( lst.Objects, "Immunity", true ) do
				
				local cat = lst:CreateCategory( exsto.Ranks[ rank ].Name )
				
				-- Now, we need to go through and add our playes to it.
				cat.PlyList = vgui.Create( "ExListView", cat )
					cat.PlyList:Dock( TOP )
					cat.PlyList:NoHeaders()
					cat.PlyList:SetDataHeight( 30 )
					cat.PlyList:DisableScrollbar() -- Shouldn't need it.  We're going to resize based on content anyways.
					cat.PlyList.OnRowSelected = playerObjectClick
					cat.PlyList.OnRowRightClick = playerObjectRightClick -- Thank god for Garry making this override.  Half expected it not to exist.
					cat.PlyList.OnMouseWheeled = scrollHandler
					cat.PlyList.Paint = function() end
				
				for _, data in ipairs( plyTbl ) do
					if string.find( data.Ply:Nick():lower(), search or "" ) then
						local obj = cat.PlyList:AddLine( data.Ply:Nick() )
							obj.Columns[1]:SetFont( "ExGenericText16" )
							obj.Data = data
					end
				end
				
				cat.PlyList:SetDirty( true )
				cat.PlyList:InvalidateLayout( true )
				cat.PlyList:SizeToContents()
				
				cat:InvalidateLayout()
				lst.Categories[ rank ] = cat
				
			end
		end
		
		pnl.PlayerList.Update = function( lst )
			lst:Format()
			lst:CreateContent()
		end
		
		pnl.PlayerList._OLDTHINK = pnl.PlayerList.Think
		pnl.PlayerList._OLDTHINKCOUNTER = CurTime()
		pnl.PlayerList.Think = function( lst )
			if ( #player.GetAll() != lst._OldPlayers ) or ( CurTime() > lst._OLDTHINKCOUNTER ) then
				lst._OldPlayers = #player.GetAll() 
				lst._OLDTHINKCOUNTER = CurTime() + 2;
				lst:Update()
			end
			lst._OLDTHINK()
		end
				
		
	exsto.Animations.CreateAnimation( pnl.PlayerList )
	qm.CreateCommandWindow( pnl )
	
end

function qm.Reset( bool, disableAnim )
	if bool then
		qm.Parent.PlayerList.OldFuncs.SetPos( qm.Parent.PlayerList, -qm.Parent:GetWide() - 2, 0 )
		qm.Parent.PlayerList.Anims[ 1 ].Current = -qm.Parent:GetWide() - 2
		qm.Parent.PlayerList.Anims[ 1 ].Last = -qm.Parent:GetWide() - 2
		qm.Parent.PlayerList:SetPos( 0, 0 )
	else
		qm.Parent.PlayerList.OldFuncs.SetPos( qm.Parent.PlayerList, 0, 0 )
		qm.Parent.PlayerList.Anims[ 1 ].Current = 0
		qm.Parent.PlayerList.Anims[ 1 ].Last = 0
	end
	
	qm.Parent.PlayerList:Update()

	if disableAnim then
		qm.Parent.ComWindow.OldFuncs.SetPos( qm.Parent.ComWindow, qm.Parent:GetWide() + 2, 0 )
		qm.Parent.ComWindow.Anims[ 1 ].Current = qm.Parent:GetWide() + 2
		qm.Parent.ComWindow.Anims[ 1 ].Last = qm.Parent:GetWide() + 2
	else
		qm.Parent.ComWindow:SetPos( qm.Parent:GetWide() + 2, 0 )
	end
	
	qm.Parent.ComWindow:Cleanup()
	
	qm.ExecTbl = {}
	qm.Parent.SelectedItem = nil
	
	qm.Object:DisableBack()
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

	pnl.ComWindow = exsto.CreatePanel( pnl:GetWide() + 2, 0, pnl:GetWide() - 8, pnl:GetTall() - 37, Color( 255, 255, 255, 255 ), pnl )
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
			qm.Object:EnableBack()
			qm.Parent._WorkingIndex = 1
			
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
		qm.Object:EnableBack()
		qm.Parent._WorkingIndex = combobox.Index + 1
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
				if comdata.QuickMenu and string.find( comdata.DisplayName:lower(), search or "" ) and LocalPlayer():IsAllowed( id ) then
					comboObj = pnl.CommandList:AddLine( comdata.DisplayName )
						comboObj.Columns[1]:SetFont( "ExGenericText16" )
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
				
			-- Hardcode: If we're working on the ranks, completely reconstruct the ExtraOptionals w/ our ranks.
			if data.ID == "rank" then
				local tmp = {}
				for id, rank in pairs( exsto.Ranks ) do
					table.insert( tmp, { Display = rank.Name, Data = id } )
				end
				data.ExtraOptionals[ "Rank" ] = tmp;
			end

			for _, fillData in ipairs( data.ExtraOptionals[ argName ] ) do
				comboObj = comboPnl:AddLine( fillData.Display )
					comboObj.Columns[1]:SetFont( "ExGenericText16" )
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
