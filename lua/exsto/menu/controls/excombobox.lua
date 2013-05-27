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

end

PANEL.OldClick = DComboBox.DoClick
function PANEL:DoClick()
	self:OldClick()
	
	if self:IsMenuOpen() then
		self.PostTextColor = self:GetTextColor()
		self:SetTextColor( Color( 255, 255, 255, 255 ) )
	else
		self:SetTextColor( self.PostTextColor )
	end
end

derma.DefineControl( "ExComboBox", "Exsto Combobox", PANEL, "DComboBox" )