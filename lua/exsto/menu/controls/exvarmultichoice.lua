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

-- Exsto Text Choice

PANEL = {}

function PANEL:Init()

	self.Choices = {}
	self.Expanded = false
	self.Material = Material( "exsto/buttonsettings.png" )

	self:MaxFontSize( 20 )
	self:SetAlignX( TEXT_ALIGN_LEFT )
	self:SetMaxTextWide( 130 )

	-- We have a list that contains the possible choices we have for a variable.		
	self.List = self:Add( "ExListView" )
		self.List:SetPos( 0, 40 )
		self.List:DisableScrollbar()
		self.List:AddColumn( "" )
		self.List:SetHideHeaders( true )
		self.List.LineSelected = function( o, disp, data, l )
			self:DoClick()
			self:SetValue( data )
			self:OnValueSet( data )
		end
		
	--exsto.Animations.Create( self )

end

function PANEL:SetMultipleOptions()
	self._MultiSelect = true
	self.List:SetMultiSelect()
end

function PANEL:OnValueSet( val ) end

function PANEL:Clear()
	self.Choices = {}
	self.List:Clear()
end

function PANEL:OnSelect( index, name, data )
	self:SetValue( name )
end

function PANEL:AddChoice( name, data )
	table.insert( self.Choices, { Name = name, Data = data } )
	
	self.List:AddRow( { name }, data )
end

function PANEL:SetValue( val ) self._Value = val self:Text( val ) end
function PANEL:GetValue() return self._Value end

-- Override ExButton's.  We now need to convert the button into the wanger.  Whoaurgoarghoa!
function PANEL:DoClick()
	if !self.Expanded then
		print( "Expanding", self:GetTall() )
		self.StoredH = self:GetTall()
		
		self.List:SizeToContents()
		self:SetTall( self.List:GetTall() + 4 + 40 )
		self.Expanded = true
	else
		print( "Reset", self.StoredH )
		self:SetTall( self.StoredH )
		self.Expanded = false
	end
end

function PANEL:Paint()
local w, h = self:GetSize()
	
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( self.Material )
	surface.DrawTexturedRect( 0, 0, w, h )

	-- Text
	local x = self:GetWide() / 2
	local y = self:GetTall() / 2
	
	if self._AlignX == TEXT_ALIGN_LEFT then x = self:GetTextPadding() end
	
	draw.SimpleText( self:GetText(), self:GetFont() .. self:GetFontSize(), x, y, self:GetTextColor(), self._AlignX, self._AlignY )

end

function PANEL:PerformLayout()
	if self.Expanded then
		self.List:SetPos( 0, self:GetTall() - self.List:GetTall() )
		self.List:SizeToContents()
		self.List:SetWide( self:GetWide() - 1 )
	else
		self.List:SetPos( 0, 40 )
	end
	ExButton.PerformLayout( self )
end

derma.DefineControl( "ExVarMultiChoice", "Exsto Multi Choice", PANEL, "ExButton" )