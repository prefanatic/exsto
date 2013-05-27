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

	if !json then
		local succ, err = pcall( require, "json" )
		if !succ then
			exsto.ErrorNoHalt( "Unable to load JSON module for Steam information!" )
			return
		end
	end

	self.APICaller = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=329C15985BA8A0501B3C2FECB4155354&steamids=%f"
	
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

function PANEL:GrabInformation( sid )
	exsto.Debug( "Fetching player statistics for '" .. sid .. "'", 1 )
	print( string.format( self.APICaller, sid ) ) 
	http.Fetch( string.format( self.APICaller, sid ), function( contents )
		exsto.Debug( "Retreived player statistics for '" .. sid .. "'", 1 )
		self.PlayerInfo = json.decode( contents )
	end )
end

function PANEL:SetBanTable( tbl )
end

function PANEL:SetPlayer( ply )
	self.Avatar:SetPlayer( ply )
	self.Nick:SetText( ply:GetNick() )
	self.Rank:SetText( ply:GetRank() )
end

derma.DefineControl( "ExPlayerView", "Exsto PlayerView", PANEL, "DPanel" )