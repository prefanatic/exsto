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
	self.Icons = {
			Red = Material( "exsto/red.png" );
			Green = Material( "exsto/green.png" );
		}

	self:MaxFontSize( 20 )
	self:SetAlignX( TEXT_ALIGN_LEFT )
	self:SetMaxTextWide( 130 )

	-- We have a list that contains the possible choices we have for a variable.		
	self.List = self:Add( "ExListView" )
		self.List:SetPos( 0, 40 )
		self.List:DisableScrollbar()
		self.List:AddColumn( "" )
		self.List:SetHideHeaders( true )
		self.List.Paint = function() end
		self.List.LineSelected = function( o, disp, data, l )
			if self._MultiSelect then -- We don't want to close, just keep selecting additional.
				l._SELECTED = not l._SELECTED
				local ret = {}
				for _, line in ipairs( o:GetLines() ) do
					if line._SELECTED then
						table.insert( ret, line.Info.Data )
					end
				end
				self:SetValue( ret )
				self:OnValueSet( string.Implode( ",", ret ) )
				return
			end
			self:DoClick()
			self:SetValue( data )
			self:OnValueSet( data )
		end
		
	--exsto.Animations.Create( self )

end

function PANEL:SetHeaderSize( n ) self._HeaderSize = n end

function PANEL:SetMultipleOptions()
	self._MultiSelect = true
	self.List:SetMultiSelect( true )
	self.List:SetTextInset( 25 )
	
	self.List:LinePaintOver( function( line )
		surface.SetDrawColor( 255, 255, 255, 255 )
		
		if line._SELECTED then surface.SetMaterial( self.Icons.Green ) else surface.SetMaterial( self.Icons.Red ) end
		
		surface.DrawTexturedRect( 5, (line:GetTall() / 2 ) - 3, 8, 8 )
	end )
	
	-- Our data coming in is going to be a table from now on.  D:
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
	
	local line = self.List:AddRow( { name }, data )
end

function PANEL:SetValue( val ) 
	if type( val ) == "table" and self._MultiSelect then
	
		-- Select the lines that this value is set to.
		for _, line in ipairs( self.List:GetLines() ) do
			for _, value in ipairs( val ) do
				if line.Info.Data == value then line._SELECTED = true end
			end
		end
			
		val = string.Implode( ",", val )
	end
	self._Value = val 
	self:Text( val ) 
end
function PANEL:GetValue() return self._Value end

-- Override ExButton's.  We now need to convert the button into the wanger.  Whoaurgoarghoa!
function PANEL:DoClick()
	if !self.Expanded then
		self.List:SizeToContents()
		self:SetTall( self.List:GetTall() + 4 + self._HeaderSize )
		self.Expanded = true
	else
		self:SetTall( self._HeaderSize )
		self.Expanded = false
	end
end

function PANEL:Paint()
	local w, h = self:GetSize()
	
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( self.Material )
	surface.DrawTexturedRect( 0, 0, w, self._HeaderSize )

	-- Text
	local x = self:GetWide() / 2
	local y = self._HeaderSize / 2
	
	if self._AlignX == TEXT_ALIGN_LEFT then x = self:GetTextPadding() end
	
	draw.SimpleText( self:GetText(), self:GetFont() .. self:GetFontSize(), x, y, self:GetTextColor(), self._AlignX, self._AlignY )

end

function PANEL:PerformLayout()
	if self.Expanded then
		self.List:SetPos( 0, self:GetTall() - self.List:GetTall() )
		self.List:SizeToContents()
		self.List:SetWide( self:GetWide() - 1 )
	else
		self.List:SetPos( 0, self._HeaderSize )
	end
	ExButton.PerformLayout( self )
end

derma.DefineControl( "ExVarMultiChoice", "Exsto Multi Choice", PANEL, "ExButton" )