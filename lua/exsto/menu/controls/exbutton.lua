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
	self:MaxFontSize( 20 )
	self:TextPadding( 6 )
	self:Text( "" )
	self:SetTextColor( Color( 133, 133, 133, 255 ) )
	self:SetAlignX( TEXT_ALIGN_CENTER )
	self:SetAlignY( TEXT_ALIGN_CENTER )
	
	self.Material = Material( "exsto/buttonsettings.png" )
end

function PANEL:SetEvil()
	self:SetTextColor( Color( 193, 85, 85, 255 ) )
end

function PANEL:SetQuickMenu()
	self._QuickMenu = true
	self:SetTall( 40 )
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

function PANEL:SetMaxTextWide( num )

	self._MaxTextWidth = num
end

function PANEL:GetMaxTextWide()
	return self._MaxTextWidth
end

function PANEL:GetMaxFontSize()
	return self._MaxFontSize
end

function PANEL:GetText()
	return self.__TEXT or ""
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
	self:SetText( "" )
	self.__TEXT = txt
	self:InvalidateLayout( true )
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
		local w, h = self:GetMaxTextWide(), ( self:GetTall() - 14 )
			w = w or self:GetWide()
		
		local workingSize, tw, th = self:GetMaxFontSize()

		while true do
			surface.SetFont( exfont .. workingSize )
			tw, th = surface.GetTextSize( self:GetText() )
			
			-- Work with text padding
			tw = tw + ( self:GetTextPadding() * 2 )
			th = th + ( self:GetTextPadding() * 2 )

			
			if ( tw < w ) or workingSize == 14 then break end -- If we are smaller than our size.
			if ( th < h ) or workingSize == 14 then break end
			
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
function PANEL:OnValueSet( val ) end

function PANEL:HideText( val )
	self._HideText = val
end

function PANEL:Paint()

	local w, h = self:GetSize()

	-- Background
	if self._QuickMenu then
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( self.Material )
		surface.DrawTexturedRect( 0, 0, w, h )
	else
		if ( self.Depressed || self:IsSelected() || self:GetToggle() ) then
			self:GetSkin().tex.Button_Down( 0, 0, w, h );	
		elseif ( self:GetDisabled() ) then
			self:GetSkin().tex.Button_Dead( 0, 0, w, h );	
		elseif self.Hovered then
			self:GetSkin().tex.Button_Hovered( 0, 0, w, h );	
		else
			self:GetSkin().tex.Button( 0, 0, w, h );
		end
	end
	
	if !self._HideText then
		
		-- Text
		local x = self:GetWide() / 2
		local y = self:GetTall() / 2
		
		if self._AlignX == TEXT_ALIGN_LEFT then x = self:GetTextPadding() end
		
		--if self._AlignY == TEXT_ALIGN_TOP then y = y + self._YMod end
		
		draw.SimpleText( self:GetText(), self:GetFont() .. self:GetFontSize(), x, y, self:GetTextColor(), self._AlignX, self._AlignY )
		
	end
	
	-- And finally our OnPaint
	self:OnPaint()
	
end

function PANEL:PerformLayout()
	self:SetFontStyle( "resize", self:GetFont() )
end

derma.DefineControl( "ExButton", "Exsto Button", PANEL, "DButton" )