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
		if !tbl[ ply:GetRank() ] then tbl[ ply:GetRank() ] = {} end;
		table.insert( tbl[ ply:GetRank() ], { Player = ply, Immunity = exsto.Ranks[ ply:GetRank() ].Immunity } )
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
	local starred = qm.Data:ReadAll()
	for _, data in ipairs( starred ) do
		if data.Command == id then return true end
	end
	return false
end

local function commandClicked( list, display, data, line )

end

local function commandRightClicked( list, display, data, line )
	if starredCommand( data.ID ) then -- We're starred.  Unstar us.
		qm.Data:DropRow( data.ID )
		qm.List.Content:Populate()
	else
		qm.Data:AddRow( {
			Command = data.ID;
			TimesUsed = 1;
		} )
		qm.List.Content:Populate()
	end
end

local function listOnShowtime( obj )
	local pnl = obj.Content
	pnl:Populate();	
end

local function initList( pnl )

	-- Throw this into a populate just because we need to run it when we change starred commands.
	pnl.Populate = function()
		-- Remove all our old stuff.
		clearContent( pnl )
		
		-- Create the categories and the commands we want to mess with.
		local tbl = {}
		for id, comData in pairs( exsto.Commands ) do
			if !tbl[ comData.Category ] and comData.QuickMenu then tbl[ comData.Category ] = {} end
			if comData.QuickMenu then table.insert( tbl[ comData.Category ], id ) end
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
		for _, data in ipairs( qm.Data:ReadAll() ) do
			local command = exsto.Commands[ data.Command ]
			cat.List:AddRow( { command.DisplayName }, command )
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
				cat.List:AddRow( { command.DisplayName }, command )
			end
			
			cat.List:SetDirty( true )
			cat.List:InvalidateLayout( true )
			cat.List:SizeToContents()
			
			cat:InvalidateLayout( true )
			cat:SetHideable( true )
			
			cat:SetExpanded( pnl.LastState[ cat ] or false )
			table.insert( pnl.Objects, cat )
		end
	end
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
	if #qm.Data:ReadAll() == 0 then
		local common = { "kick", "ban", "rank" }
		for _, id in ipairs( common ) do
			qm.Data:AddRow( {
				Command = id;
				TimesUsed = 0;
			} )
		end
	end
		
	exsto.Menu.QM = exsto.Menu.CreatePage( "quickmenu", initQuickMenu )
		exsto.Menu.QM:SetTitle( "Quick Menu" )
		exsto.Menu.QM:OnShowtime( mainOnShowtime )
		exsto.Menu.QM:SetIcon( "exsto/quickmenu.png" )
		exsto.Menu.QM:Build()
		
	qm.List = exsto.Menu.CreatePage( "quicklist", initList )
		qm.List:SetTitle( "Commands" )
		qm.List:SetBackFunction( function() exsto.Menu.OpenPage( exsto.Menu.QM ) exsto.Menu.DisableBackButton() end )
		qm.List:OnShowtime( listOnShowtime )
		
end