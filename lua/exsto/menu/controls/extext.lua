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

-- Exsto Panel Scroller

PANEL = {}

function PANEL:Init()
	self.Lines = {}
	
	self:SetTextColor( Color( 133, 133, 133, 255 ) )
end

function PANEL:Paint() end

function PANEL:SetTextColor( col ) self.TextColor = col end
function PANEL:GetTextColor() return self.TextColor end

function PANEL:SetFont( fnt )
	self._Font = fnt
end
function PANEL:GetFont() return self._Font or "ExGenericTextNoBold14" end

function PANEL:GetLines() return self.Lines end
function PANEL:GetLineCount() return #self.Lines end
function PANEL:GetProjectedHeight() return #self.Lines * self.GreatestLineHeight end

function PANEL:ConstructLines( txt )
	-- Abide by the width of our panel so we create new lines downward.
	surface.SetFont( self:GetFont() )
	local words = string.Explode( " ", txt )
	local tbl = {}
	
	local w, h, l, tW, word = 0, 0, 1, 0
	for I = 1, #words do
		word = words[ I ]
		if !tbl[ l ] then tbl[ l ] = {} end
		
		w, h = surface.GetTextSize( word )
		w = w + 4
		
		if word:find( "\n" ) then
			table.insert( tbl[ l ], word:Replace( "\n", "" ) )
			l = l + 1 -- Increase the line level
			tW = 0
		elseif w + tW > self:GetWide() then
			l = l + 1
			
			tW = w
			tbl[ l ] = {}
			table.insert( tbl[ l ], word )
		else
			tW = tW + w
			table.insert( tbl[ l ], word )
		end
		
	end
	
	return tbl
end

function PANEL:SetText( txt )

	self._TEXT = txt

	for _, line in ipairs( self:GetLines() ) do
		if IsValid( line ) then line:Remove() end
	end
	self.Lines = {}
	
	local construct = self:ConstructLines( txt )

	-- Create our text objects for each line we have.
	for I = 1, #construct do
		local line = self:Add( "DLabel" )
			line:Dock( TOP )
			line:SetText( table.concat( construct[ I ], " " ) )
			line:SetTextColor( self:GetTextColor() )
			line:SetFont( self:GetFont() )
			line:SizeToContents()
		table.insert( self.Lines, line )
	end
	
	-- Set our H
	local h = 0
	for _, line in ipairs( self:GetLines() ) do
		h = h + line:GetTall()
	end
	self:SetTall( h + 4 )

end

function PANEL:PerformLayout()
	local w, h = self:GetWide()
	
	if w != self._W or h != self._H then -- We changed sizes!
		self._W = w
		self._H = h
		
		self:SetText( self._TEXT )
	end
	
end

derma.DefineControl( "ExText", "Exsto Text", PANEL, "DPanel" )