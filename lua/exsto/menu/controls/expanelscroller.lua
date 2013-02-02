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

	-- Icon Layout
	self.Layout = vgui.Create( "DPanelList", self )
		self.Layout:SetPos( 0, 0 )
		self.Layout:SetSpacing( 5 )
		self.Layout:SetPadding( 5 )
		self.Layout:EnableHorizontal( false )
		self.Layout.Material = Material( "exsto/gradient.png" )
		self.Layout.PaintOver = function( pnl )
			surface.SetMaterial( pnl.Material )
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.DrawTexturedRect( 0, 0, pnl:GetWide(), 9 )
		end
		self.Layout.Paint = function( pnl )
			pnl:GetSkin().tex.Input.ListBox.Background( 0, 0, pnl:GetWide(), pnl:GetTall() );
		end
end

function PANEL:Add( obj, catName )
	if !self.Objects[ catName ] then self.Objects[ catName ] = {} end
	
	local cat = self.Categories[ catName ]

	cat:SetContents( obj )
	cat:SetTall( obj:GetTall() )
	cat:SetExpanded( true )

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
	
	local cat = vgui.Create( "DCollapsibleCategory", self.Layout )
		cat:SetSize( self:GetWide(), 50 )
		cat:SetLabel( catName )
		cat:SetExpanded( false )
		cat.Header:SetTextColor( Color( 0, 180, 255, 255 ) )
		cat.Header:SetFont( "ExGenericText19" )
		cat.Header.UpdateColours = function( self, skin ) end
		cat.Header.OnMousePressed = function( c )
			--cat:Toggle() -- Fuck you garry.
		end
		cat.Paint = categoryPaint
		
	--[[local cat = vgui.Create( "DLabel", self.Layout )
		cat:SetText( catName )
		cat:SetTextColor( Color( 0, 180, 255, 255 ) )
		cat:SetFont( "ExGenericText19" )
		cat:SizeToContents()]]
		
	self.Layout:AddItem( cat )
		
	self.Categories[ catName ] = cat
end

function PANEL:PerformLayout()
	print( self:GetSize() )
	self.Layout:SetSize( self:GetWide(), self:GetTall() )
	for catName, cat in pairs( self.Categories ) do
		cat:InvalidateLayout()
	end
end
	

derma.DefineControl( "ExPanelScroller", "Exsto Panel Scroller", PANEL, "DPanel" )