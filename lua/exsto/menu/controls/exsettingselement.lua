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

-- Exsto Number Choice

PANEL = {}

function PANEL:Init()

	self.Choice = {
		NUMBER = 1;
		BOOLEAN = 2;
		TEXT = 3;
		MULTI = 4;
	}
	
	self:DockPadding( 4, 4, 4, 4 )

	-- Title label
	self.Header = self:Add( "DPanel" )
		self.Header.Paint = function() end
		self.Header:Dock( TOP )
	self.Title = self.Header:Add( "DLabel" )
		self.Title:Dock( LEFT )
		self.Title:SetFont( "ExGenericText18" )
		self.Title:SetText( "%TITLE" )
		self.Title:SetTextColor( Color( 0, 180, 255, 255 ) )
	
	-- Help text
	self.Help = self:Add( "ExText" )
		self.Help:SetFont( "ExGenericText14" )
		self.Help:SetText( "%HELP" )
		self.Help:Dock( TOP )
	

end

function PANEL:SetClientside()
	self.Clientside = true
end

function PANEL:SetMultiChoice()
	self.Active = self.Choice.MULTI;
	
	self.Button = self:Add( "ExVarMultiChoice" )
		self.Button:Dock( TOP )
		self.Button:SetTall( 40 )
		self.Button:SetHeaderSize( 40 )
		self.Button.OnValueSet = function( o, val ) self:OnValueSet( val ) end	
		
	--exsto.Animations.Create( self.Button )
end

function PANEL:SetBoolean( )
	self.Active = self.Choice.BOOLEAN;
	
	self.Button = self:Add( "ExBooleanChoice" )
		self.Button:Dock( TOP )
		self.Button:SetTall( 40 )
		self.Button:Text( "Status: " )
		self.Button.OnValueSet = function( o, val ) self:OnValueSet( val ) end
end

function PANEL:SetNumberEntry( txt )
	self.Active = self.Choice.NUMBER;
	
	self.Button = self:Add( "ExNumberChoice" )
		self.Button:Dock( TOP )
		self.Button:SetTall( 40 )
		self.Button:Text( txt )
		self.Button:SetDecimals( 0 )
		self.Button.OnValueSet = function( o, val ) self:OnValueSet( val ) end 
end

function PANEL:SetTextEntry()
	self.Active = self.Choice.TEXT;
	
	self.Button = self:Add( "DTextEntry" )
		self.Button:Dock( TOP )
		self.Button:SetTall( 40 )
		self.Button:SetFont( "ExGenericText14" )
		self.Button.OnTextChanged = function( o ) self:OnValueSet( o:GetValue() ) end
		self.Button.OnEnter = function( o ) self:OnValueSet( o:GetValue() ) end
end

function PANEL:SetMultipleOptions() self.Button:SetMultipleOptions() end

function PANEL:SetUnit( u ) self.Button:SetUnit( u ) end

function PANEL:AddChoice( disp, data ) self.Button:AddChoice( disp, data ) end

function PANEL:SetValue( val )
	self.Button:SetValue( val )
end

function PANEL:SetMin( val ) self.Button:SetMin( val ) end
function PANEL:SetMax( val ) self.Button:SetMax( val ) end

function PANEL:OnValueSet( val ) end

function PANEL:Paint()
	--surface.SetDrawColor( 195, 195, 195, 195 )
	--surface.DrawLine( 0, 0, self:GetWide(), 0 )
	--surface.DrawLine( 0, self:GetTall(), self:GetWide(), self:GetTall() )
end

function PANEL:SetTitle( txt )
	self.Title:SetText( self.Clientside and "Client: " .. txt or txt )
end

function PANEL:SetHelp( txt )
	self.Help:SetText( txt )
end

function PANEL:SizeToContents()
	self.Title:SizeToContents()
	self.Header:SizeToContents()
	
	self.Help:SizeToContents()
	
	self:SetTall( self.Title:GetTall() + self.Help:GetTall() + self.Button:GetTall() + 16 )
end

function PANEL:PerformLayout()
	self:SizeToContents()
end


derma.DefineControl( "ExSettingsElement", "Exsto Number Choice", PANEL, "DPanel" )