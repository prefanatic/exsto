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

-- Player View

PANEL = {}

function PANEL:Init()
	
	self:DockPadding( 2, 2, 2, 2 )
	
	-- Avatar image
	self.AvatarBG = self:Add( "DPanel" )
		self.AvatarBG:Dock( LEFT )
		self.AvatarBG:DockPadding( 2, 2, 2, 2 )
		self.AvatarBG:SetWide( 36 )
		
	self.Avatar = self.AvatarBG:Add( "AvatarImage" )
		self.Avatar:Dock( LEFT )
		
	self.Nick = self:Add( "DLabel" )
		self.Nick:SetText( "%NICK" )
		self.Nick:Dock( TOP )
	
	self.Rank = self:Add( "DLabel" )
		self.Rank:SetText( "%RANK" )
		self.Rank:Dock( TOP )

end

function PANEL:SetBanTable( tbl )
end

function PANEL:SetPlayer( ply )
	self.Avatar:SetPlayer( ply )
	self.Nick:SetText( ply:GetNick() )
	self.Rank:SetText( ply:GetRank() )
end

derma.DefineControl( "ExPlayerView", "Exsto PlayerView", PANEL, "DPanel" )