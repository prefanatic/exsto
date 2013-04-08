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
	self:SetTextIndent( 5 )
	self:SetDataHeight( 32 )

end

function PANEL:SetTextIndent( num )
	self._Indent = num
end

function PANEL:NoHeaders()
	self:SetHideHeaders( true )
	self:AddColumn( "" )
end

function PANEL:SetFont( fnt )
	self._Font = fnt
end

function PANEL:LinePaintOver( func )
	self._LinePaintOver = func
end

function PANEL:AddRow( cols, data )
	
	local line = self:AddLine( unpack( cols ) )
	table.insert( self.Data, { Data = data, Display = { unpack( cols ) }, Obj = line } ) -- It will match up with the lineID.  I think.  :I
	
	-- Reference so we don't have to search for the line's data
	line.Info = self.Data[ #self.Data ]
	
	for i, label in ipairs( line.Columns ) do
		label:SetTextInset( 25, 0 )
		label:SetFont( "ExGenericTextNoBold14" )
	end
	
	if self._LinePaintOver then
		line.PaintOver = self._LinePaintOver
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

function PANEL:OnRowSelected( lineID, line )
	local disp = self.Data[ lineID ].Display
	local data = self.Data[ lineID ].Data
	
	self:LineSelected( disp, data, line )
end
--[[
function PANEL:PerformLayout()
	-- Loop through all our lines and their columns AND THEIR LABELSSSS!!!111
	for id, line in ipairs( self:GetLines() ) do
		if line.Columns then
			for i, label in ipairs( line.Columns ) do
				label:SetTextInset( self._Indent or 5, 0 )
			end
		end
	end
end]]

derma.DefineControl( "ExListView", "Exsto ListView", PANEL, "DListView" )