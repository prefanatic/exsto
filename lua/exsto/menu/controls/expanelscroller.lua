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

	self.Objects = {}
	
	self.Material = Material( "exsto/gradient.png" )
	
	self.List = vgui.Create( "DCategoryList", self )
		self.List:Dock( FILL )
		self.List:DockMargin( 4, 0, 4, 0 )
		self.List.pnlCanvas:DockPadding( 2, 5, 2, 5 )
		self.List.VBar:SetWide( 3 )
		self.List.PaintOver = function( pnl )
			surface.SetMaterial( self.Material )
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.DrawTexturedRect( 0, 0, pnl:GetWide(), 9 )
		end
		self.List.Paint = function( pnl )
			pnl:GetSkin().tex.Input.ListBox.Background( 0, 0, pnl:GetWide(), pnl:GetTall() );
		end

	self._VBarDisabled = false
	
end

function PANEL:Paint()
	
end

function PANEL:Think()
	--if self.List.VBar:IsVisible() and self._VBarDisabled then print( "Fixing vbar" ) self:DisableScroller() end
	--if !self.List.VBar:IsVisible() and !self._VBarDisabled then print( "drgu" ) self.List.VBar:SetEnabled( true ) end
end

function PANEL:DisableScroller()
	--self.List.VBar:SetEnabled( false )
	self.List.VBar:SetVisible( false )
	self.List.VBar.Enabled = false
	self._VBarDisabled = true
end

-- Deprecating
function PANEL:Add( obj, catName )
	if !self.Objects[ catName ] then self.Objects[ catName ] = {} end
	
	local cat = self.Categories[ catName ]

	table.insert( self.Objects[ catName ], obj )
end

local function categoryPaint( cat )
	surface.SetFont( "ExGenericText19" )
	local w, h = surface.GetTextSize( cat.Header:GetValue() )
	
	surface.SetDrawColor( 195, 195, 195, 195 )
	surface.DrawLine( w + 10, ( cat.Header:GetTall() / 2 ), cat.Header:GetWide() - 5, ( cat.Header:GetTall() / 2 ) )
end


function PANEL:CreateCategory( catName )
	self.Categories = self.Categories or {}

	local cat = self.List:Add( catName )
		cat.Header:SetTextColor( Color( 0, 180, 255, 255 ) )
		cat.Header:SetFont( "ExGenericText19" )
		cat.Header.UpdateColours = function( self, skin ) end
		--cat.Header.OnMousePressed = function( c )
			--cat:Toggle() -- Fuck you garry.
		--end
		cat.Paint = categoryPaint
		
		cat.CreateSpacer = function( c )
			local spacer = vgui.Create( "ExSpacer", c )
				spacer:Dock( TOP )
				spacer:SetTall( 1 )
		end
		
	cat:DockPadding( 0, 0, 0, 4 )
		
	self.Categories[ catName ] = cat
	
	return cat
end

function PANEL:PerformLayout()

end
	

derma.DefineControl( "ExPanelScroller", "Exsto Panel Scroller", PANEL, "DPanel" )