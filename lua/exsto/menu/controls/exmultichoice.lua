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

-- Exsto Multichoice.  Kind of like the DComboBox but not.

PANEL = {}

function PANEL:Init()
	
	-- Create the list view for the choices we have.
	self.List = vgui.Create( "ExListView" )
		self.List:NoHeaders()
		self.List:SetTall( 0 )
		self.List:SetDrawOnTop( true )
		self.List.LineSelected = function( lst, disp, data, lineObj ) self:LineSelected( disp, data, lineObj ) end
		
	self.OnMouseWheeled = nil
		
	exsto.Animations.CreateAnimation( self.List )

end

function PANEL:SelectChoice( disp )
	self:LineSelected( { disp }, self.List:GetLineData( { disp } ), self.List:GetLineObj( { disp } ) )
end

function PANEL:OnClick() -- Extending off ExButton
	if self._Opened then -- Close I guess.
		self.List:SetTall( 0 )
		self._Opened = false
		return
	end
	
	-- Open our list!
	self.List:SizeToContents()
	self.List:MoveToFront()
	self._Opened = true
end

function PANEL:LineSelected( disp, data, lineObj )
	-- Set our button's text.
	self:Text( disp[ 1 ] )
	
	-- Close the list
	self.List:SetTall( 0 )
	
	-- Call the callback
	self:OnSelect( data )
end

function PANEL:AddChoice( disp, data )
	self.List:AddRow( { disp }, data )
end

function PANEL:PerformLayout()
	
	-- Reset our list to match where we moved.

	local x, y = self:LocalToScreen( 0, self:GetTall() )
	local w, h = self:GetSize()

	self.List:SetPos( x + 4, y + 4 )
	self.List:SetWide( w - 8 )
	self.List:MoveToFront()

end


derma.DefineControl( "ExMultiChoice", "Exsto Multichoice", PANEL, "ExButton" )