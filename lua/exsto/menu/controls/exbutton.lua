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

-- Exsto Default Button

PANEL = {}

function PANEL:Init()
	self:Font( "ExGenericText" )
	self:MaxFontSize( 128 )
	self:TextPadding( 6 )
	self:SetText( "" )
	self:Text( "" )
	self:SetTextColor( Color( 0, 153, 176, 255 ) )
end

function PANEL:TextPadding( num )
	self._TextPadding = num
end

function PANEL:GetTextPadding()
	return self._TextPadding
end

function PANEL:MaxFontSize( num )
	self._MaxFontSize = num
end

function PANEL:GetMaxFontSize()
	return self._MaxFontSize
end

function PANEL:GetText()
	return self._Text
end

function PANEL:SetFontSize( num )
	self._FontSize = num
end

function PANEL:GetFontSize()
	return self._FontSize
end

function PANEL:Font( fnt )
	self._Font = fnt
end

function PANEL:GetFont()
	return self._Font
end

function PANEL:Text( txt )
	self._Text = txt
	self:SetFontStyle( "resize", self:GetFont() )
end

function PANEL:SetTextColor( col )
	self._Col = col
end

function PANEL:GetTextColor()
	return self._Col
end

function PANEL:SetFontStyle( t, exfont )
	if t == "resize" then
		
		-- Resize the font to fit our panel's size.
		local w, h = self:GetSize()
		
		local workingSize, tw, th = self:GetMaxFontSize()
		while true do
			surface.SetFont( exfont .. workingSize )
			tw, th = surface.GetTextSize( self:GetText() )
			
			-- Work with text padding
			tw = tw + ( self:GetTextPadding() * 2 )
			
			if ( tw < w ) or workingSize == 14 then break end -- If we are smaller than our size.
			
			-- Otherwise, lets go down to the next font size
			workingSize = workingSize - 1
		end
		
		self:SetFontSize( workingSize )
		
		-- We also should set a tmp to move the text down based off half its height
		self._YMod = th / 2
		
	end
	self._FontStyle = t
end

function PANEL:SetAlignX( c )
	self._AlignX = c
end

function PANEL:SetAlignY( c )
	self._AlignY = c
end

function PANEL:DoClick()
	-- TODO: Exsto click functions
	self:OnClick()
end

function PANEL:OnClick() end
function PANEL:OnPaint() end

function PANEL:Paint()

	local w, h = self:GetSize()

	-- Background
	if ( self.Depressed || self:IsSelected() || self:GetToggle() ) then
		self:GetSkin().tex.Button_Down( 0, 0, w, h );	
	elseif ( self:GetDisabled() ) then
		self:GetSkin().tex.Button_Dead( 0, 0, w, h );	
	elseif self.Hovered then
		self:GetSkin().tex.Button_Hovered( 0, 0, w, h );	
	else
		self:GetSkin().tex.Button( 0, 0, w, h );
	end
	
	-- Text
	local x = self:GetWide() / 2
	local y = self:GetTall() / 2
	
	--if self._AlignY == TEXT_ALIGN_TOP then y = y + self._YMod end
	
	draw.SimpleText( self:GetText(), self:GetFont() .. self:GetFontSize(), x, y, self:GetTextColor(), self._AlignX, self._AlignY )
	
	-- And finally our OnPaint
	self:OnPaint()
	
end

derma.DefineControl( "ExButton", "Exsto Button", PANEL, "DButton" )