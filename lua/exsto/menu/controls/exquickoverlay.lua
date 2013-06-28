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

PANEL = {}

function PANEL:Init()
	self:MaxFontSize( 16 )
	self:Dock( RIGHT )
	self:SetAlignX( TEXT_ALIGN_LEFT )
	self:SetTall( 40 )
	
	-- We've got two things.  We have the icon, which overlay the entire unexpanded button, and then the background button, which contains quick (which is this parent)
	self.Icon = self:Add( "DImageButton" )
		self.Icon:SetWide( 40 )
		self.Icon:SetDrawOnTop()
		self.Icon:Dock( RIGHT )
		self.Icon.Paint = function( s )
			local w, h = s:GetSize()
			surface.SetDrawColor( 100, 100, 100, 255 )
			surface.DrawRect( 0, 0, w, h )
		end
		
	exsto.Animations.Create( self )
end

function PANEL:Think()
	if self.Hovered then -- If the main Quick is hovered, keep us expanded.
		self:SetWide( 90 )
		return
	end
	
	if self.Icon.Hovered then -- If we aren't hovering on Quick, but we are on the icon, expand.
		self:SetWide( 90 )
		return
	end
	
	-- Resize down to the standard
	self:SetWide( 40 )
end

derma.DefineControl( "ExQuickOverlay", "Exsto Quickmenu Line Overlay", PANEL, "ExButton" )