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

-- Our hook into the menu!
function exsto.InitPageList( pnl )

	pnl.Scroller = vgui.Create( "DScrollPanel", pnl )
	pnl.Holder = pnl.Scroller:Add( "DIconLayout" )	
		pnl.Holder:Dock( TOP )
		pnl.Holder:SetLayoutDir( LEFT )
		pnl.Holder:SetSpaceX( 12 )
		pnl.Holder:SetSpaceY( 12 )
		pnl.Holder:SetBorder( 25 )
	
	-- Loop through our pages and create icons :)
	for _, obj in pairs( exsto.Menu.Pages ) do
		if !obj._Hide then
		
			local button = pnl.Holder:Add( "ExPageIcon" )
				button:SetIcon( "exsto/icon_test.png" )
				button:SetPage( obj )
				button:SetSize( 95, 95 )
		
		end
	end
	
	pnl.Scroller:Dock( FILL )
	pnl.Scroller:InvalidateLayout( true )
	pnl.Holder:InvalidateLayout( true )

end