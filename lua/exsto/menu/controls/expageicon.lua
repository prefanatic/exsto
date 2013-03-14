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
	self.Colors = {
		Hover = Color( 65, 139, 223, 255 );
		Sad = Color( 218, 218, 218, 255 );
		IconSad = Color( 255, 255, 255, 255 );
		IconHover = Color( 255, 255, 255, 255 );
	};
	self.Background = Material( "exsto/iconbg.png" )
	
	self:Text( "" )
end

function PANEL:DoClick()
	if !self._Page then return end
	exsto.Menu.OpenPage( self._Page );
end

function PANEL:Paint()

	-- Background
	surface.SetDrawColor( self.Colors.Sad );
	if self.Hovered then
		surface.SetDrawColor( self.Colors.Hover );
	end
	
	surface.SetMaterial( self.Background );
	surface.DrawTexturedRect( 0, 0, self:GetWide(), self:GetTall() );
	
	-- Icon
	surface.SetDrawColor( self.Colors.IconSad );
	if self.Hovered then
		surface.SetDrawColor( self.Colors.IconHover );
	end
	
	surface.SetMaterial( self._Mat )
	surface.DrawTexturedRect( 0, 0, 64, 64 )
	
end	

function PANEL:SetIcon( iMat ) self._Mat = Material( iMat ) end;
function PANEL:SetPage( obj ) self._Page = obj end;

derma.DefineControl( "ExPageIcon", "Exsto Page Icon", PANEL, "ExButton" )