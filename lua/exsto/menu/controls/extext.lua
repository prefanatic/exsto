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
end

function PANEL:SetFont( fnt )
	self._Font = fnt
end
function PANEL:GetFont() return self._Font or "ExGenericText14" end

function PANEL:GetLines() return self.Lines end
function PANEL:GetLineCount() return #self.Lines end
function PANEL:GetProjectedHeight() return #self.Lines * self.GreatestLineHeight end

function PANEL:SetText( txt )

	self:Clear( true )
	for _, line in ipairs( self:GetLines() ) do
		if line and line:IsValid() then line:Remove() end
	end
	
	-- Abide by the width of our panel so we create new lines downward.
	surface.SetFont( self:GetFont() )
	local words = string.Explode( " ", txt )
	local construct = {}
	
	local w, h, l, maxH, word = 0, 0, 1, 0
	for I = 1, #words do
		word = words[ I ]
		if !construct[ l ] then construct[ l ] = { _LINEW = 0 } end
		
		w, h = surface.GetTextSize( word )
		
		if word:find( "\n" ) then
			table.insert( construct[ l ], word:Replace( "\n", "" ) )
			l = l + 1 -- Increase the line level
		elseif w + construct[ l ]._LINEW > self:GetWide() then
			I = I - 1 -- Step backwards
			l = l + 1 -- Increase the level
		else
			construct[ l ]._LINEW = construct[ l ]._LINEW + w
			table.insert( construct[ l ], word )
		end
		
		if h > maxH then maxH = h end
	end
	
	-- Create our text objects for each line we have.
	for I = 1, #construct do
		local line = self:Add( "DLabel" )
			line:SetText( table.concat( construct[ I ], " " ) )
			line:SetWide( construct[ I ]._LINEW )
			line:SetFont( self:GetFont() )
		table.insert( self.Lines, line )
		self:AddItem( line )
	end
	
	self.GreatestLineHeight = maxH

	self:InvalidateLayout( true )
end

function PANEL:PerformLayout()
	print( "inval", self:GetProjectedHeight() )
	for _, l in ipairs( self.Lines ) do
		if l and l:IsValid() then
			l:SizeToContents()
			l:InvalidateLayout()
		end
	end
	self:SetTall( self:GetProjectedHeight() )
end

derma.DefineControl( "ExText", "Exsto Text", PANEL, "DPanelList" )