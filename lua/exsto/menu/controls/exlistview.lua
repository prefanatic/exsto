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

-- Exsto List View

PANEL = {}

function PANEL:Init()

	-- Data for OnRowSelected
	self.Data = {}
	self:SetTextInset( 5 )
	self:SetDataHeight( 32 )
	
	self:SetTextColor( Color( 85, 85, 85, 255 ) )
	self:SetTextHoverColor( Color( 255, 255, 255 ) )
	
	self.Materials = {
		Red = Material( "exsto/red.png" );
		Green = Material( "exsto/green.png" );
	}

end

function PANEL:Clear()
	self.Data = {};
	DListView.Clear( self )
end

function PANEL:EnableOverlay( txt, icon )
	self.OverlayEnabled = true
	self.OverlayIcon = icon
	self.OverlayText = txt
end

function PANEL:SetQuickList( cat )
	self.Paint = function() end
	self.OnMouseWheeled = nil
	self.CatParent = cat
end

function PANEL:Validate()	
	self:SetDirty( true )
	self:InvalidateLayout( true )
	
	self:SizeToContents()
	
	self.CatParent:InvalidateLayout( true )
end

function PANEL:SetEnableDisable()
	local function lineOver( line )
		surface.SetDrawColor( 255, 255, 255, 255 )
		if not line.Info.Data.Enabled then surface.SetMaterial( self.Materials.Red ) else surface.SetMaterial( self.Materials.Green ) end
		surface.DrawTexturedRect( 5, (line:GetTall() / 2 ) - 3, 8, 8 )
	end
	self:LinePaintOver( lineOver )
end

function PANEL:SetTextColor( col ) self._TextCol = col end
function PANEL:SetTextHoverColor( col ) self._TextHover = col end

function PANEL:NoHeaders()
	self:SetHideHeaders( true )
	self:AddColumn( "" )
end

function PANEL:SetFont( fnt )
	self._Font = fnt
end

function PANEL:SetTextInset( x, y )
	self._TINX = x or 0
	self._TINY = y or 0
end
function PANEL:GetTextInset() return self._TINX, self._TINY end

function PANEL:GetFont() return self._Font or "ExGenericTextNoBold14" end

function PANEL:LinePaintOver( func )
	self._LinePaintOver = func
end

-- So gay things don't happen.
local function mouseClick( l, mcode )
	if mcode == MOUSE_RIGHT then
		l:GetListView():OnRowRightClick( l:GetID(), l )
		l:OnRightClick()
		return
	end
	l:GetListView():OnClickLine( l, true )
	l:OnSelect()
end

local function lineThink( l )
	if !l.Hovered and l.HoverThinked then l.Columns[ 1 ]:SetTextColor( l:GetListView()._TextCol ) l.HoverThinked = false end
	if l.Hovered and !l.HoverThinked then l.Columns[ 1 ]:SetTextColor( l:GetListView()._TextHover ) l.HoverThinked = true end
	if l.__OLDTHINK then
		return l.__OLDTHINK()
	end
end

function PANEL:AddRow( cols, data )
	
	local line = self:AddLine( unpack( cols ) )
	table.insert( self.Data, { Data = data, Display = { unpack( cols ) }, Obj = line } ) -- It will match up with the lineID.  I think.  :I
	
	-- Reference so we don't have to search for the line's data
	line.Info = self.Data[ #self.Data ]
	
	for i, label in ipairs( line.Columns ) do
		label:SetTextInset( self:GetTextInset() )
		label:SetFont( "ExGenericText16" )
	end
	
	if self._LinePaintOver then
		line.PaintOver = self._LinePaintOver
	end
	
	-- I hate this :(
	line.__OLDTHINK = line.Think
	line.Think = lineThink
	
	-- This also, is deeply tragic.  Modify the line's OnMousePressed behavior, because fuck everything.
	line.OnMousePressed = mouseClick
	
	if self.OverlayEnabled then -- We've got an overlay to do
		line.Overlay = vgui.Create( "ExQuickOverlay", line )
			line.Overlay:Dock( RIGHT )
			line.Overlay:Text( self.OverlayText )
	end
	
	return line

end

function PANEL:GetLineDataFromObj( obj )
	for id, linedata in ipairs( self.Data ) do
		if linedata.Obj == obj then return linedata.Data end
	end
	return nil
end

function PANEL:GetLineData( disp )
	for id, linedata in ipairs( self.Data ) do
		if linedata.Display == disp then return linedata.Data end
	end
	return nil
end

function PANEL:GetLineObj( disp )
	for id, linedata in ipairs( self.Data ) do
		if linedata.Display == disp then return self:GetLine( id ) end
	end
	return nil
end	

function PANEL:LineSelected( disp, data, lineobj )
	
end

function PANEL:LineRightSelected( disp, data, lineobj )
end

function PANEL:OnRowSelected( lineID, line )
	local disp = self.Data[ lineID ].Display
	local data = self.Data[ lineID ].Data
	
	self:LineSelected( disp, data, line )
end

function PANEL:OnRowRightClick( lineID, line )
	local disp = self.Data[ lineID ].Display
	local data = self.Data[ lineID ].Data
	
	self:LineRightSelected( disp, data, line )
end

function PANEL:PerformLayout()
	DListView.PerformLayout( self )
	if IsValid( self.VBar ) then
		self.VBar:SetPos( self:GetWide() - 3, 0 )
		self.VBar:SetSize( 3, self:GetTall() )
		self.VBar:SetUp( self.VBar:GetTall() - self:GetHeaderHeight(), self.pnlCanvas:GetTall() )
		
		self.pnlCanvas:SetWide( self:GetWide() )
	end
end


derma.DefineControl( "ExListView", "Exsto ListView", PANEL, "DListView" )