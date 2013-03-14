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

local pl = {}

-- Our hook into the menu!
function exsto.InitPageList( pnl )
	pl.Pnl = pnl
	pnl:SetSpacing( 12 )
	pnl:SetPadding( 25 )
	pnl:EnableHorizontal( true )
	pnl:EnableVerticalScrollbar( true )
	
--[[
	pnl.Holder = vgui.Create( "DIconLayout", pnl )	
		pnl.Holder:SetPos( 0, 0 )
		pnl.Holder:SetTall( pnl:GetTall() )
		pnl.Holder:SetWide( pnl:GetWide() ) print( pnl:GetWide() ) print( pnl:GetTall() )
		pnl.Holder:SetLayoutDir( LEFT )
		pnl.Holder:SetSpaceX( 12 )
		pnl.Holder:SetSpaceY( 12 )
		pnl.Holder:SetBorder( 25 )]]
end

function exsto.BuildPageListIcons( obj )
	local pnl = pl.Pnl
	-- Loop through our pages and create icons :)
	for _, obj in pairs( exsto.Menu.Pages ) do
		if !obj._Hide then

			local button = vgui.Create( "ExPageIcon" )
				button:SetIcon( "exsto/settings.png" )
				button:SetPage( obj )
				button:SetSize( 95, 95 )
			pnl:AddItem( button )
		end
	end

end
