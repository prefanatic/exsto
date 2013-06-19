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
	
	self:SetTextColor( COLOR.MENU )
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
function PANEL:IgnoreSelfWide() self.IgnoreWide = true end
function PANEL:SetMaxWide( m ) self.MaxW = m end
function PANEL:SetProjectedWide( w ) self.ProjectedWide = w end
function PANEL:GetProjectedWide() return self.ProjectedWide end

function PANEL:ConstructLines( ... )
	-- Abide by the width of our panel so we create new lines downward.
	surface.SetFont( self:GetFont() )

	-- This might be werid.  I'm implementing color support.  So, yeah.
	local w, h, l, tW, tH, tbl, c = 0, 0, 1, 0, 0, {}, nil
	for _, d in pairs( {...} ) do
		if not tbl[ l ] then tbl[ l ] = {} end
		if type( d ) == "string" then
			local exp = string.Explode( " ", d )
			
			for _, word in ipairs( exp ) do
				w, h = surface.GetTextSize( word .. " " )
				
				-- Handle going over in w
				if ( not self.IgnoreWide and ( w + tW ) > self:GetWide() ) or ( self.IgnoreWide and ( w + tW ) > self.MaxW ) then
					-- We can't fit, so segregate downwards.
					l = l + 1
					tW = w -- Reset our tW to this new one.
					tH = tH + h + 2
					tbl[ l ] = {} -- Reset our line.
					table.insert( tbl[ l ], { X = 0, Y = tH, W = w, H = h, L = l, T = word, C = c } )
				else -- If we can throw it in, then do so!
					table.insert( tbl[ l ], { X = tW, Y = tH, W = w, H = h, L = l, T = word, C = c } )
					tW = tW + w
				end
			end
			self:SetProjectedWide( tW )
		elseif type( d ) == "table" then -- We've got a color.
			c = d
		end
	end

	return tbl
end

local function nilFunc() end

function PANEL:SetText( ... )
	local arg = {...}
	if type( arg[1] ) == "string" and table.Count( arg ) == 1 then
		arg = { self:GetTextColor(), arg[1] }
	end

	self._TEXT = arg

	for _, line in ipairs( self:GetLines() ) do
		if IsValid( line ) then line:Remove() end
	end
	self.Lines = {}
	
	local construct = self:ConstructLines( unpack( arg ) )
	
	-- K, construct done.  We get back lines, and inside the line table, are the separate DLabel shit
	
	for line, data in ipairs( construct ) do
		-- Create the label holder.
		local hold = self:Add( "DPanel" )
			hold.Paint = nilFunc
			hold:Dock( TOP )
		
		for labelID, labelD in ipairs( data ) do
			
			local line = hold:Add( "DLabel" )
				line:SetPos( labelD.X, 0 )
				line:SetTextColor( labelD.C )
				line:SetFont( self:GetFont() )
				line:SetText( labelD.T )
				line:SizeToContents()
				
			-- Eh.
			hold:SetTall( labelD.H )
		end
		
		table.insert( self.Lines, hold )
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
		
		self:SetText( unpack( self._TEXT ) )
	end
	
end


derma.DefineControl( "ExText", "Exsto Text", PANEL, "DPanel" )