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
	
	--pnl.Paint = function() end 
	
	local shadow = Material( "exsto/gradient.png" )
	
	pnl.Holder = vgui.Create( "DPanelList", pnl )
		pnl.Holder:Dock( FILL )
		pnl.Holder:DockMargin( 4, 4, 4, 4 )
		pnl.Holder:SetSpacing( 12 )
		pnl.Holder:SetPadding( 25 )
		pnl.Holder:EnableHorizontal( true )
		pnl.Holder:EnableVerticalScrollbar( true )
		--[[pnl.Holder.PaintOver = function( p )
			surface.SetMaterial( shadow )
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.DrawTexturedRect( 0, 0, p:GetWide(), 9 )
		end]]
end

function exsto.BuildPageListIcons( obj )
	local pnl = pl.Pnl
	
	pnl.Holder:Clear()
	-- Loop through our pages and create icons :)
	for _, obj in pairs( exsto.Menu.Pages ) do
		if !obj._Hide then

			local button = vgui.Create( "ExPageIcon" )
				button:SetIcon( "exsto/settings.png" )
				button:SetPage( obj )
				button:SetSize( 95, 95 )
			pnl.Holder:AddItem( button )
		end
	end
	
	pnl.Holder:InvalidateLayout( true )

end
