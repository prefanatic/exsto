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

-- Exsto List View

PANEL = {}

function PANEL:Init()
	self:DockMargin( 4, 4, 4, 4 )

end

-- TODO: Fade the line into the background w/ alpha 0.

function PANEL:Paint()
	surface.SetDrawColor( 228, 228, 228, 195 )
	surface.DrawLine( ( self:GetWide() / 2 ) - ( self:GetWide() / 3 ), self:GetTall() / 2, ( self:GetWide() / 2 ) + ( self:GetWide() / 3 ), self:GetTall() / 2 )
end

derma.DefineControl( "ExSpacer", "Exsto ListView", PANEL, "DPanel" )