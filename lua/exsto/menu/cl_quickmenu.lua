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

local qm = {
	Main = nil;
	List = nil;
	Starred = {};
}

local function clearContent( pnl )
	if !pnl.Categories then pnl.Categories = {} return end
	for rank, cat in pairs( pnl.Categories ) do
		cat:Remove()
	end
	pnl.Categories = {}
end

local function mainOnShowtime( obj )
	local pnl = obj.Content
	
	clearContent( pnl )
	
	-- Loop through our players to construct the ranks table.
	local tbl = {}
	for _, ply in ipairs( player.GetAll() ) do
		if !tbl[ ply:GetRank() ] then tbl[ ply:GetRank() ] = { Immunity = exsto.Ranks[ ply:GetRank() ].Immunity } end;
		table.insert( tbl[ ply:GetRank() ], { Player = ply } )
	end
	pnl.FormattedTable = tbl;
	
	-- And now we loop through that table to construct the categories n stuff.
	for rank, players in SortedPairsByMemberValue( tbl, "Immunity", true ) do
		local cat = pnl:CreateCategory( exsto.Ranks[ rank ].Name )
		
		cat.List = vgui.Create( "ExListView", cat )
			cat.List:DockMargin( 4, 0, 4, 0 )
			cat.List:Dock( TOP )
			cat.List:DisableScrollbar()
			cat.List:AddColumn( "" )
			cat.List.OnMouseWheeled = nil
			cat.List:SetHideHeaders( true )
			cat.List:SetQuickList()
			cat.List.LineSelected = function( l, disp, data, line )
				qm.WorkingPlayer = data.Player
				exsto.Menu.OpenPage( qm.List )
				exsto.Menu.EnableBackButton()
			end
			
		for _, data in ipairs( players ) do
			cat.List:AddRow( { data.Player:Nick() }, data )
		end
		
		cat.List:SetDirty( true )
		cat.List:InvalidateLayout( true )
		cat.List:SizeToContents()
		
		cat:InvalidateLayout( true )
		pnl.Categories[ rank ] = cat;
	end
end		

local function initQuickMenu( pnl )
	-- We have multiple player lists, constructed by our ranks.  So this function pretty much does nothing, as it happens in Showtime.
	qm.Main = obj
end

local function clearContent( pnl )
	if !pnl.Objects then pnl.Objects = {} return end
	pnl.LastState = {}
	for cat, o in pairs( pnl.Objects ) do
		pnl.LastState[ cat ] = o:GetExpanded();
		o:Remove()
	end
	pnl.Objects = {}
end

local function starredCommand( id )
	for _, data in ipairs( qm.Starred ) do
		if data.Command == id then return true end
	end
	return false
end

local function executeCommand()
	local data = qm.WorkingData
	
	-- Make sure the player is still valid
	if not IsValid( qm.WorkingPlayer ) then
		chat.AddText( exsto_CHAT, COLOR.NORM, "The player you were running the command on has ", COLOR.NAME, "left" )
		return
	end
	
	local execTbl = { data.CallerID, qm.WorkingPlayer:Nick() }

	for _, arg in ipairs( data.ReturnOrder ) do
		if _ != 1 then
			table.insert( execTbl, qm.WorkingExecute[ arg ] )
		end
	end
	
	RunConsoleCommand( unpack( execTbl ) )
end

local function commandClicked( list, display, data, line )
	if line._OMGRIGHTCLICKED then return end
	
	-- We just want to execute with all dem optionals filled in for us.  SO DO THAT.
	qm.WorkingData = data
	qm.WorkingExecute = { }
	
	-- But before we do that, make sure this isn't the rank command.
	if data.ID == "rank" then -- shit.
		exsto.Menu.OpenPage( qm.Argument )
		return
	end
	
	for count, arg in ipairs( data.ReturnOrder ) do
		qm.WorkingExecute[ arg ] = data.Optional[ arg ]
	end
	
	executeCommand()
	exsto.Menu.OpenPage( qm.List )
	exsto.Menu.DisableBackButton()

end

local function commandRightClicked( list, display, data, line )
	line._OMGRIGHTCLICKED = 1
	timer.Simple( 0.1, function() if IsValid( line ) then line._OMGRIGHTCLICKED = 0 end end ) -- Because gayre doesn't have any of this standard?
	
	if starredCommand( data.ID ) then -- We're starred.  Unstar us.
		qm.Data:DropRow( data.ID )
		for _, d in ipairs( qm.Starred ) do
			if data.ID == d.Command then table.remove( qm.Starred, _ ) end
		end
		qm.List.Content:Populate()
	else
		qm.Data:AddRow( {
			Command = data.ID;
			TimesUsed = 1;
		} )
		local f = false
		for _, d in ipairs( qm.Starred ) do
			if data.ID == d.Command then
				f = true
				qm.Starred[ _ ].TimesUsed = qm.Starred[ _ ].TimesUsed + 1;
			end
		end
		if not f then
			table.insert( qm.Starred, { Command = data.ID, TimesUsed = 1 }  );
		end
		qm.List.Content:Populate()
	end
end

local function listOnShowtime( obj )
	local pnl = obj.Content
	pnl:Populate();	
end

local function quickOnClick( obj )
	qm.WorkingData = obj.CommandData
	qm.WorkingExecute = { }
	
	exsto.Menu.OpenPage( qm.Argument )
end

local function initList( pnl )

	-- Throw this into a populate just because we need to run it when we change starred commands.
	pnl.Populate = function()
		-- Remove all our old stuff.
		clearContent( pnl )
		
		-- Create the categories and the commands we want to mess with.
		local tbl = {}
		for id, comData in pairs( exsto.Commands ) do
			if LocalPlayer():IsAllowed( id ) then
				if !tbl[ comData.Category ] and comData.QuickMenu then tbl[ comData.Category ] = {} end
				if comData.QuickMenu then table.insert( tbl[ comData.Category ], id ) end
			end
		end
		
		-- Create the starred category.
		local cat = pnl:CreateCategory( "Starred" )
		
		cat.List = vgui.Create( "ExListView", cat )
			cat.List:DockMargin( 4, 0, 4, 0 )
			cat.List:Dock( TOP )
			cat.List:DisableScrollbar()
			cat.List:AddColumn( "" )
			cat.List.OnMouseWheeled = nil
			cat.List:SetHideHeaders( true )
			cat.List:SetQuickList()
			cat.List.LineSelected = commandClicked
			cat.List.LineRightSelected = commandRightClicked
			
		-- Add the starred to this list.
		for _, data in ipairs( qm.Starred ) do
			local command = exsto.Commands[ data.Command ]
			if LocalPlayer():IsAllowed( command.ID ) then
				local line = cat.List:AddRow( { command.DisplayName }, command )
				
				if table.Count( command.ExtraOptionals ) > 0 then
					-- Overlay our quick button
					line.Quick = vgui.Create( "ExButton", line )
						line.Quick:Dock( RIGHT )
						line.Quick:Text( "More Args" )
						line.Quick.OnClick = quickOnClick
						line.Quick.CommandData = command
				end
			end
			
			--exsto.Animations.Create( line.Quick )
		end
		
		cat.List:SetDirty( true )
		cat.List:InvalidateLayout( true )
		cat.List:SizeToContents()
		
		cat:InvalidateLayout( true )
		cat:SetHideable( true )
		table.insert( pnl.Objects, cat )
		
		-- Now we want to add in the rest of the commands, categorized.
		for cat, commands in pairs( tbl ) do
			local cat = pnl:CreateCategory( cat )
			cat.List = vgui.Create( "ExListView", cat )
				cat.List:DockMargin( 4, 0, 4, 0 )
				cat.List:Dock( TOP )
				cat.List:DisableScrollbar()
				cat.List:AddColumn( "" )
				cat.List.OnMouseWheeled = nil
				cat.List:SetHideHeaders( true )
				cat.List:SetQuickList()
				cat.List.LineSelected = commandClicked
				cat.List.LineRightSelected = commandRightClicked
				
			for _, id in ipairs( commands ) do
				local command = exsto.Commands[ id ]
				local line = cat.List:AddRow( { command.DisplayName }, command )
				
				if table.Count( command.ExtraOptionals ) > 0 then
					-- Overlay our quick button
					line.Quick = vgui.Create( "ExButton", line )
						line.Quick:Dock( RIGHT )
						line.Quick:Text( "More Args" )
						line.Quick.OnClick = quickOnClick
						line.Quick.CommandData = command
				end
				
				--exsto.Animations.Create( line.Quick )
			end
			
			cat.List:SetDirty( true )
			cat.List:InvalidateLayout( true )
			cat.List:SizeToContents()
			cat.List:SortByColumn( 1 )
			
			cat:InvalidateLayout( true )
			cat:SetHideable( true )
			cat:Toggle()
			
			--cat:SetExpanded( pnl.LastState[ cat ] or false )
			table.insert( pnl.Objects, cat )
		end
	end
end

local function clearContent( pnl )
	for _, o in ipairs( pnl.Objects or {} ) do
		for _, object in ipairs( o ) do object:Remove() end
	end
	pnl.Objects = {}
end

local function argOnShowtime( obj )
	local pnl = obj.Content
	local data = qm.WorkingData
	
	-- Clear old set
	clearContent( pnl )
	
	pnl.Cat.Header:SetText( data.DisplayName )
	
	local help = pnl.Cat:CreateHelp( "Select the arguments you want to change, and click on execute to send it off." )
	local spacer = pnl.Cat:CreateSpacer()
	
	-- We need to construct our little cool things based on the return order of this command.
	for count, argument in pairs( data.ReturnOrder ) do
		if count != 1 then -- 1 is going to be the victim for us.  No need to look at it.
			local title = pnl.Cat:CreateTitle( argument );
			local multi = pnl.Cat:CreateMultiChoice();
			
			-- Little hack.  I think I inject "rank" in somewhere, so lets just populate our extraoptionals with the possible ranks.
			if data.ID == "rank" then
				local t = {}
				for id, rank in pairs( exsto.Ranks ) do
					table.insert( t, { Display = rank.Name, Data = rank.ID } )
				end
				data.ExtraOptionals[ argument ] = t
				data.Optional[ argument ] = ""
			end
			
			for count, data in pairs( data.ExtraOptionals[ argument ] ) do
				multi:AddChoice( data.Display, data.Data or data.Display )
			end
			
			multi.OnValueSet = function( s, d ) 
				qm.WorkingExecute[ argument ] = d
			end
			
			multi:SetValue( data.Optional[ argument ] )
			qm.WorkingExecute[ argument ] = data.Optional[ argument ]
			
			local spacer = pnl.Cat:CreateSpacer();
			
			table.insert( pnl.Objects, { title, multi, spacer } )
		end
	end
	
	local b = pnl.Cat:CreateButton( "Execute" )
		b.OnClick = function( s )
			executeCommand()
			exsto.Menu.OpenPage( qm.List )
			exsto.Menu.DisableBackButton()
		end
		
	table.insert( pnl.Objects, { b, help, spacer } )
	
	pnl.Cat:InvalidateLayout( true )
end

local function initArgs( pnl )
	pnl.Cat = pnl:CreateCategory( "%COMMAND_ID" )
	
end

function exsto.InitQuickMenu()
	-- Top list data saving shit.
	qm.Data = FEL.CreateDatabase( "exsto_data_quickmenu" )
		qm.Data:SetDisplayName( "Quickmenu Data" )
		qm.Data:ConstructColumns( {
			Command = "TEXT:primary:not_null";
			TimesUsed = "INTEGER";
		} )
		
	-- Check to see if we have anything in data.  If we don't, inject a few commonly used commands.
	qm.Data:GetAll( function( q, d )
		if not d then
			local common = { "kick", "ban", "rank" }
			for _, id in ipairs( common ) do
				qm.Data:AddRow( {
					Command = id;
					TimesUsed = 0;
				} )
				table.insert( qm.Starred, { Command = id, TimesUsed = 0 } )
			end
		else
			qm.Starred = d;
		end
	end )

	exsto.Menu.QM = exsto.Menu.CreatePage( "quickmenu", initQuickMenu )
		exsto.Menu.QM:SetTitle( "Quick Menu" )
		exsto.Menu.QM:OnShowtime( mainOnShowtime )
		exsto.Menu.QM:SetIcon( "exsto/quickmenu.png" )
		exsto.Menu.QM:Build()
		
	qm.List = exsto.Menu.CreatePage( "quicklist", initList )
		qm.List:SetTitle( "Commands" )
		qm.List:SetFlag( "quickmenu" )
		qm.List:SetBackFunction( function() exsto.Menu.OpenPage( exsto.Menu.QM ) exsto.Menu.DisableBackButton() end )
		qm.List:OnShowtime( listOnShowtime )
		qm.List:SetUnaccessable()
		
	qm.Argument = exsto.Menu.CreatePage( "quickargument", initArgs )
		qm.Argument:SetTitle( "Arguments" )
		qm.Argument:SetFlag( "quickmenu" )
		qm.Argument:SetBackFunction( function() exsto.Menu.OpenPage( qm.List ) end )
		qm.Argument:OnShowtime( argOnShowtime )
		qm.Argument:SetUnaccessable()
		
end