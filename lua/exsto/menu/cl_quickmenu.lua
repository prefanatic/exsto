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
	TopList = nil;
	MainList = nil;
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
				exsto.Menu.OpenPage( qm.TopList )
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
	for _, o in ipairs( pnl.Objects ) do
		for _, object in ipairs( o ) do
			object:Remove();
		end
	end
	pnl.Objects = {}
end

local function listOnShowtime( obj )
	local pnl = obj.Content
	
	-- Remove all our old stuff.
	clearContent( pnl )
	
	-- We want to abide only by the commands we have in the top list.  So lets localize some variables.
	local tops = qm.Data:ReadAll();
	for id, comData in SortedPairsByMemberValue( exsto.Commands, "DisplayName", false ) do
		if comData.QuickMenu and LocalPlayer():IsAllowed( id ) then
			local f = false
			for _, data in ipairs( tops ) do if data.Command == id then f = true end end
			
			-- If we're apart of the top list, construc the layout.
			if f then				
				local holder = {
					pnl.Cat:CreateSpacer();
					pnl.Cat:CreateTitle( comData.DisplayName );
					pnl.Cat:CreateHelp( "Placeholder help." );
					pnl.Cat:CreateButton( "Run" );
				}
				table.insert( pnl.Objects, holder )
			end
		end
	end
end

local function initTopList( pnl )
	pnl.Cat = pnl:CreateCategory( "Top Used" )
	
	pnl.More = vgui.Create( "ExQuickButton", pnl )
		pnl.More:Dock( BOTTOM )
		pnl.More:Text( "More..." )
		pnl.More:SetEvil()
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
		exsto.Menu.QM:Build()
		
	qm.TopList = exsto.Menu.CreatePage( "quicktoplist", initTopList )
		qm.TopList:SetTitle( "Top Used" )
		qm.TopList:SetBackFunction( function() exsto.Menu.OpenPage( exsto.Menu.QM ) exsto.Menu.DisableBackButton() end )
		qm.TopList:OnShowtime( listOnShowtime )
		
end