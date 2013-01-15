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

--[[
	Exsto's Quick Menu
	-- Designed for https://dl.dropbox.com/u/3913710/Prefan/exsto3.png
]]

local qm = {
	Objects = {};
	ObjectCount = {};
	MainPanel = nil;
	ExecTbl = {};
	WorkingCommand = "";
	_ScrollBorder = 50;
}
exsto.QuickMenu = qm

function exsto.CreateQuickMenu( panel )
	qm.MainPanel = vgui.Create( "DIconLayout", panel )
		qm.MainPanel:SetSpaceX( 80 )
		qm.MainPanel:SetPos( 80, 0 )
		qm.MainPanel:SetSize( panel:GetWide() - 80, panel:GetTall() )
		qm.MainPanel:SetLayoutDir( LEFT )
		
		qm.MainPanel.FixSize = function( pnl )
			-- Little hacky way to set the size of this thing.
			local setW = 0
			for _, obj in pairs( pnl:GetChildren() ) do
				if obj:IsVisible() then
					local w, h = obj:GetSize()
					local x, y = obj:GetPos()
					
					setW = setW + w + 80
				end
			end
			pnl:SetWide( setW )
			
			-- Also, reset our position if our X is weird and we aren't bigger than the screen
			local x, y = pnl:GetPos()
			if x < 0 and ( setW < ScrW() ) then
				pnl:SetPos( 0, y )
			end
		end
	
	qm.CommandList = exsto.CreateQuickMenuList( 70, 10, "Commands", { MultiSelect = false, ObjectHeight = 34, Type = "COMMANDS"  }, exsto.Commands, qm.MainPanel )
	qm.PlayerList = exsto.CreateQuickMenuPlayers( 70 + 80 + 250, 10, qm.MainPanel )
		qm.PlayerList.LayoutLst:Populate()
		
	qm.MainPanel:Add( qm.CommandList )
	qm.MainPanel:Add( qm.PlayerList )
	qm.MainPanel:FixSize()
	
	-- Animations
	exsto.Animations.CreateAnimation( qm.MainPanel )
	exsto.Animations.CreateAnimation( qm.CommandList )
	exsto.Animations.CreateAnimation( qm.PlayerList ) 
		
end

function qm.ClearExecTbl()
	qm.ExecTbl = {}
end

function qm.Reset()
	-- Loop through and remove our players selected
	for _, obj in pairs( qm.PlayerList.LayoutLst:GetChildren() ) do
		obj._IsSelected = false
	end

	qm.ClearArguments()
	qm.ClearExecTbl()
	
	qm.PlayerList.WorkingPlayers = {}
	qm.PlayerList._Ready = false
	qm.CommandList._Ready = false
	qm.CommandList._SelectedLine = nil
	qm.WorkingCommand = nil
	
	qm.CommandList.ComboBox:ClearSelection()
	qm.PlayerList.LayoutLst:Populate()

	
	timer.Simple( 0.01, function() qm.MainPanel:FixSize() end )
end

function qm.Execute()
	local call = qm.WorkingCommand.CallerID
	local plys = table.Copy( qm.ExecTbl[ "PLAYER" ] )
		--qm.ExecTbl[ "PLAYER" ] = nil
		
	local tbl = {}
	-- Format the table.
	for I = 1, #qm.WorkingCommand.ReturnOrder do
		if qm.WorkingCommand.ReturnOrder[ I ] != "VICTIM" then
			table.insert( tbl, qm.ExecTbl[ qm.WorkingCommand.ReturnOrder[ I ] ] )
		end
	end
	
	for plyName, _ in pairs( plys ) do
		RunConsoleCommand( call, plyName, unpack( tbl ) )
	end
	
	qm.Reset()
end

function qm.Think() -- Fucking god damnit.
	if !qm.MainPanel then return end
	if !qm.PlayerList then return end
	if !qm.MainPanel:GetParent():IsVisible() then return end
	
	qm._MouseX, qm._MouseY = gui.MousePos()
	
	-- If the mouse is to the far left, lets try scrolling as far as we can go to the left.
	if qm._MouseX < qm._ScrollBorder then
		local x, y = qm.MainPanel:GetPos()
		local delta = ( qm._ScrollBorder - qm._MouseX ) 
		
		if x < 80 then
			qm.MainPanel:SetPos( x + delta, y )
		end
	elseif qm._MouseX > ( ScrW() - qm._ScrollBorder ) then
		local x, y = qm.MainPanel:GetPos()
		local w, h = qm.MainPanel:GetWide()
		local delta = ( ( ScrW() - qm._ScrollBorder ) - qm._MouseX ) 
		
		if ( x + w ) > ScrW() then
			qm.MainPanel:SetPos( x + delta, y )
		end
	end
	
	-- PlayerList updating stuff.
	--[[if !qm.PlayerList._PlyCount then qm.PlayerList._PlyCount = #player.GetAll() end
	
	if qm.PlayerList._PlyCount != #player.GetAll() then 
		qm.PlayerList.LayoutLst:Populate()
		qm.PlayerList._PlyCount = #player.GetAll()
	end]]
end
hook.Add( "Think", "ExQuickMenuThink", qm.Think )

function qm.CreateArguments( comData )
	local argName, t
	for I = 1, #comData.ReturnOrder do
		argName = comData.ReturnOrder[ I ]
		t = comData.Args[ argName ]
		
		if t != "PLAYER" then
		
			print( "checking " .. argName )
			print( qm.Objects[ argName ] )
			
			if !qm.Objects[ argName ] then
			
				qm.Objects[ argName ] = exsto.CreateQuickMenuList( 0, 0, argName, { MultiSelect = false, ObjectHeight = 34, Type = "ARGS" }, comData.ExtraOptionals[ argName ], qm.MainPanel )
				qm.Objects[ argName ].Argument = argName
				qm.Objects[ argName ].ReturnOrderNum = I - 1
				qm.Objects[ argName ]:SetVisible( false )
				qm.Objects[ argName ]:MoveLeftOf( ( I == 2 and qm.PlayerList ) or qm.Objects[ comData.ReturnOrder[ I - 1 ] ] )
				
				table.insert( qm.ObjectCount, { Arg = argName, Type = t } )
				
				exsto.Animations.CreateAnimation( qm.Objects[ argName ] )
				
			end
		end
	end
	
	-- Now, send out the first one!
	local argName = comData.ReturnOrder[ 2 ] -- Picking 2 because 1st will be players.
	
	print( "Setting" .. argName .. " as visible" )
	PrintTable( qm.Objects )
	qm.Objects[ argName ]:SetVisible( true )
	qm.MainPanel:Add( qm.Objects[ argName ] )
	qm.MainPanel:FixSize()
end

function qm.ClearArguments()
	for argName, data in pairs( qm.Objects ) do
		data:Remove()
	end
	
	qm.Objects = {}
	qm.ObjectCount = {}
	
	timer.Simple( 0.01, function()
		qm.MainPanel:FixSize()
	end )
end

local function commandClickHandler()
	print( #qm.ObjectCount, "QM Object Count" )
	if #qm.ObjectCount != 0 then qm.ClearArguments() end

	-- We also need to input the player into the arguments table.
	qm.ExecTbl[ "PLAYER" ] = qm.PlayerList.WorkingPlayers

	-- Check if that is all we need to do to run this command.
	print( #qm.WorkingCommand.ReturnOrder, "Return order #" )
	if #qm.WorkingCommand.ReturnOrder == 1 then -- Assume this is for the player.
		qm.Execute()
		qm.ClearArguments()
		return
	end
		
	qm.CreateArguments( qm.WorkingCommand ) 
end

local function onRowSelected( box, lineID, line )
	qm.CommandList._Ready = true
	qm.CommandList._SelectedLine = line
	
	PrintTable( qm.Objects )
	
	-- If this is a command, set us as working with it.
	if line.Type == "COMMANDS" then
		qm.WorkingCommand = line.Data
		if qm.PlayerList._Ready then 
			commandClickHandler()
		end
		return
	end
	
	-- If we're an argument being clicked on...
	if line.Type == "ARGS" then
		
		-- Input us into the executable table.
		qm.ExecTbl[ box:GetParent().Argument ] = line.Data;
		
		-- If there is something else for us to move onto...
		if qm.ObjectCount[ box:GetParent().ReturnOrderNum + 1 ] then
		
			local obj = qm.Objects[ qm.ObjectCount[ box:GetParent().ReturnOrderNum + 1 ].Arg ]
				obj:SetVisible( true )
				
			qm.MainPanel:Add( obj )
			
			-- Little hacky way to set the size of this thing.
			qm.MainPanel:FixSize()
			
			-- Also, auto-set the pos to scale into the latter arguments.
			if qm.MainPanel:GetWide() > ScrW() then
				local x = ( qm.MainPanel:GetWide() - ScrW() )
				local _, y = qm.MainPanel:GetPos()
				
				qm.MainPanel:SetPos( -x, y )
			end
		
		-- If there is nothing for us to move onto, execute.
		else 
			qm.Execute()
		end
	
	end

end

function qm.SearchFunc( search )
	local val = search:GetValue()
	if !val then return end
	
	print( "VAL: ", val )
	
	qm.PlayerList.LayoutLst:Populate( val ) -- Dear lord, please let this not cause lag.
end

function exsto.CreateQuickMenuPlayers( x, y, parent )
	local pnl = exsto.CreatePanel( x, y, 180, parent:GetTall(), nil, parent )
		pnl.m_bBackground = false
		pnl.WorkingPlayers = {}
		
	pnl.CatLabel = exsto.CreateLabel( 0, 0, "Players", "ExGenericText48", pnl )
		pnl.CatLabel:SetTextColor( Color( 255, 255, 255, 255 ) )
		
	pnl.LayoutLst = vgui.Create( "DIconLayout", pnl )
		pnl.LayoutLst:SetSpaceX( 4 )
		pnl.LayoutLst:SetSpaceY( 4 )
		pnl.LayoutLst:SetPos( 0, 50 )
		pnl.LayoutLst:SetSize( pnl:GetWide(), pnl:GetTall() - 50 )
		pnl.LayoutLst.SelectCol = Color( 255, 0, 0, 100 )
		pnl.LayoutLst.InactiveCol = Color( 0, 0, 0, 50 )
		
		local function playerListPressed( ppnl, mcode )
			if pnl.WorkingPlayers[ ppnl.Ply ] then -- We already have him selected.  Remove
				print( "we have him" )
				pnl.WorkingPlayers[ ppnl.Ply ] = nil;
				ppnl._IsSelected = false
				
				local c = 0
				for ply, _ in pairs( pnl.WorkingPlayers ) do
					if ply and _ != nil then
						c = c + 1
					end
				end
				
				-- If we have no players selected, we need to say we're no longer ready	
				if c == 0 then 
					pnl._Ready = false 
					qm.ClearArguments();
				end
				
				qm.CommandList:FormatForPlayers( pnl.WorkingPlayers )
				return
			end
			
			print( "adding him." )
			
			pnl.WorkingPlayers[ ppnl.Ply ] = true;
			ppnl._IsSelected = true
			pnl._Ready = true
			
			-- If the command list is ready for arguments now...
			if qm.CommandList._Ready then
				commandClickHandler()
				return
			end
			
			qm.CommandList:FormatForPlayers( pnl.WorkingPlayers )
		end
	
		
		local function playerListPaint( ppnl )
			draw.RoundedBox( 4, 0, 0, ppnl:GetWide(), ppnl:GetTall(), ppnl._IsSelected and exsto.GetRankColor( ppnl.PlyObj:GetRank() ) or pnl.LayoutLst.InactiveCol )
		
			-- Rank color
			draw.RoundedBox( 4, 4, 4, 36, 36, exsto.GetRankColor( ppnl.PlyObj:GetRank() ) )
		end
		
		pnl.LayoutLst.Populate = function( l, searchParam )
			local count = 0
			l:Clear()
			
			-- Hack fix.
			l:SetTall( l:GetParent():GetTall() )
			
			for _, v in ipairs( player.GetAll() ) do
				if v:Nick():find( searchParam or "" ) then
					if ( count + 50 ) > l:GetTall() then -- We need to resize.
						l:GetParent():SetWide( l:GetWide() + 180 )
						l:SetWide( l:GetWide() + 180 )
						l:Layout()
						qm.MainPanel:Layout()
						
						count = 0
					end
					
					local ppnl = vgui.Create( "DPanel", l )
						ppnl:SetSize( 165, 44 )
						ppnl.Ply = v:Nick()
						ppnl.PlyObj = v
						ppnl.OnMousePressed = playerListPressed
						ppnl.Paint = playerListPaint
						
					local avatar = vgui.Create( "AvatarImage", ppnl )
						avatar:SetPos( 6, 6 )
						avatar:SetSize( 32, 32 )
						avatar:SetPlayer( v )
						
					local lbl = vgui.Create( "DLabel", ppnl )
						lbl:SetSize( ppnl:GetWide() - 35, 44 )
						lbl:MoveRightOf( avatar, 8 )
						lbl:SetFont( "ExGenericTextNoBold20" )
						lbl:SetText( v:Nick() )
						lbl:SetTextColor( Color( 190, 190, 190, 255 ) )
						
					l:Add( ppnl )
					count = count + ppnl:GetTall() + 10
				end
			end
			
			qm.MainPanel:Layout()
			qm.MainPanel:FixSize()
			l._PlyCount = #player.GetAll()

		end
		
	return pnl
end

local function linePaint( obj )

end
	
function exsto.CreateQuickMenuList( x, y, title, buildData, fill, parent )
	local pnl = exsto.CreatePanel( x, y, 250, parent:GetTall(), nil, parent )
		pnl.m_bBackground = false
	pnl.CatLabel = exsto.CreateLabel( 0, 0, title, "ExGenericText48", pnl )
		pnl.CatLabel:SetTextColor( Color( 255, 255, 255, 255 ) )

	pnl.ComboBox = exsto.CreateComboBox( 0, 50, pnl:GetWide(), parent:GetTall() - 20, pnl )
		local column = pnl.ComboBox:AddColumn( title )
		pnl.ComboBox:SetHideHeaders( true )
		pnl.ComboBox:SetHeaderHeight( 50 )
		pnl.ComboBox:SetMultiSelect( buildData.MultiSelect or false )
		pnl.ComboBox:SetDataHeight( buildData.ObjectHeight or 17 )
		pnl.ComboBox.OnRowSelected = onRowSelected
		
		pnl.ComboBox.Paint = function() end
		
		pnl.ComboBox.Populate = function( box, f )
			local obj
			for _, data in ipairs( f ) do
				obj = box:AddItem( data.Display )
					obj.Type = data.Type or type( data.Display )
					obj.Data = data.Data or data.Display
					obj.Columns[1]:SetFont( "ExGenericText34" )
					obj.Paint = linePaint
			end
			box.FillData = f
		end
		
		pnl.ComboBox.ResetBox = function( box )
			box:Clear()
			box:Populate( box.FillData )
		end
		
		pnl.ComboBox.MakeFillClean = function( box, tbl, t )
			local cleanedTable = {}
			for _, v in pairs( tbl ) do
				if t == "PLAYER" then
					table.insert( cleanedTable, { Display = v:Nick(), Type = t, Data = v:Nick() } )
				elseif t == "COMMANDS" then
					if v.QuickMenu then
						table.insert( cleanedTable, { Display = _, Type = t, Data = v } )
					end
				elseif t == "ARGS" then
					table.insert( cleanedTable, { Display = v.Display, Type = t, Data = v.Data } )
				end
			end
			return cleanedTable
		end
		
		pnl.ComboBox:Populate( pnl.ComboBox:MakeFillClean( fill, buildData.Type ) )
		
		pnl.FormatForPlayers = function( pnl, plTbl )
			-- TODO: Eventually, we'll have non-player run commands here.  Look through the command table and weed out the commands that don't run on plys.
		end
		
	return pnl
end