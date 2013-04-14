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

-- Exsto Boolean Choice

PANEL = {}

function PANEL:Init()
	self:SetValue( false )
	
	self:MaxFontSize( 20 )
	self:SetAlignX( TEXT_ALIGN_LEFT )
	self:SetMaxTextWide( 130 )
	self:SetTextColor( Color( 133, 133, 133, 255 ) )
	
	-- +17, +47, +47
	self.NormalColor = Color( 27, 184, 50, 255 )
	self.RedColor = Color( 193, 85, 85, 255 )
	self.Material = Material( "exsto/buttonsettings.png" )
	self.IconOn = Material( "exsto/green.png" )
	self.IconOff = Material( "exsto/red.png" )
end

function PANEL:DoClick()
	self:SetValue( not self:GetValue() )
	self:OnValueSet( self:GetValue() )
	self:OnClick( self:GetValue() )
end

function PANEL:OnClick()
end
function PANEL:OnValueSet()
end

function PANEL:SetValue( val )
	self._Value = tobool( val )
end

function PANEL:GetValue()
	return tobool( self._Value )
end

function PANEL:Paint()
	local w, h = self:GetSize()
	
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( self.Material )
	surface.DrawTexturedRect( 0, 0, w, h )

	-- Text
	local x = self:GetWide() / 2
	local y = self:GetTall() / 2
	
	if self._AlignX == TEXT_ALIGN_LEFT then x = self:GetTextPadding() end
	
	surface.SetFont( self:GetFont() .. self:GetFontSize() )
	local tw = surface.GetTextSize( self:GetText() )
	
	draw.SimpleText( self:GetText(), self:GetFont() .. self:GetFontSize(), x, y, self:GetTextColor(), self._AlignX, self._AlignY )
	draw.SimpleText( self._Value and "Enabled" or "Disabled", self:GetFont() .. self:GetFontSize(), tw + x + 5, y, self._Value and self.NormalColor or self.RedColor, self._AlignX, self._AlignY )
	
	surface.SetMaterial( self._Value and self.IconOn or self.IconOff )
	surface.DrawTexturedRect( w - 22, y - 8, 16, 16 )

end

derma.DefineControl( "ExBooleanChoice", "Exsto Boolean Choice", PANEL, "ExButton" )