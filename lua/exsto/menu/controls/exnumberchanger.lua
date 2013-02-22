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
	
	-- Create our wanger.  Heh.  Wanger.
	self.Slider = vgui.Create( "DNumSlider", self )
		self.Slider:Dock( FILL )
		self.Slider:DockMargin( 4, 2, 4, 2 )
		self.Slider:SetVisible( false )
		--self.Slider.Scratch:SetVisible( false )
		
	-- Now our overlay text box thing to allow us to change w/o the slider.
	self.Entry = vgui.Create( "DTextEntry", self )
		self.Entry:SetNumeric( true )
		self.Entry:Dock( RIGHT )
		self.Entry:SetWide( 45 )
	
end

-- Override ExButton's.  We now need to convert the button into the wanger.  Whoaurgoarghoa!
function PANEL:DoClick()
	self.Slider:SetVisible( not self.Slider:IsVisible() )
end

derma.DefineControl( "ExNumberChoice", "Exsto Number Choice", PANEL, "ExButton" )