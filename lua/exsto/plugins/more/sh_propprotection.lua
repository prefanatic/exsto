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

-- And here we go!
local PLUGIN = exsto.CreatePlugin() 

PLUGIN:SetInfo({ 
	Name = "Prop Protection", 
	ID = "propprotection", 
	Desc = "Prop protection implementation for Exsto, using CPPI.", 
	Owner = "Prefanatic", 
} ) 


if SERVER then

	util.AddNetworkString( "ExUpdateFriend" )

	function PLUGIN:Init()
		-- Create flag for ignoring all prop protection.  Similar to admins.
		exsto.CreateFlag( "ignore-pp", "Allows user to bypass all prop protection.  Similar to admins." )
		
		-- Create our table to monitor our stuff with.
		self.Data = {}
	end
	
	-- Friend stuff.  plya is setting plyb as a friend.  But plyb doesn't have to be friends back :)
	function PLUGIN:SetFriends( plya, plybid )
		if !self:GetFriends( plya ) then self:Error( "Unable to load friend's table for '" .. plya:Nick() .. "'" ) return end -- Where is our table?  D:
		
		table.insert( plya.PPFriends, plybid )
	end
	
	function PLUGIN:RemoveFriend( plya, plybid ) -- :(
		if !self:GetFriends( plya ) then self:Error( "Unable to load friend's table for '" .. plya:Nick() .. "'" ) return end -- Where is our table?  D:

		for _, pid in ipairs( self:GetFriends( plya ) ) do
			if plybid == pid then table.remove( self:GetFriends( plya ), _ ) return end
		end
	end
	
	function PLUGIN:AreFriends( plya, plyb )
		for _, pid in ipairs( self:GetFriends( plya ) ) do
			if plyb:SteamID() == pid then return true end
		end
		return false
	end
	
	function PLUGIN.UpdateFriend( reader, l, ply )
		local t = reader:ReadString()
		
		if t == "add" then PLUGIN:SetFriends( ply, reader:ReadString() ) return end
		if t == "rem" then PLUGIN:RemoveFriend( ply, reader:ReadString() ) return end
		
		self:Debug( "Updating friends from client." )
	end
	exsto.CreateReader( "ExUpdateFriend", PLUGIN.UpdateFriend )
	
	function PLUGIN:GetFriends( ply ) return ply.PPFriends end

	-- Main handler for touching things.
	function PLUGIN:PlayerTouch( ply, ent )
		
		-- Lets see if he can bypass.
		if ply:IsAllowed( "ignore-pp" ) then return true end
		
		-- If we're monitoring this prop...
		if self.Data[ ent:EntIndex() ] then
			
			-- Is this his prop?
			if self.Data[ ent:EntIndex() ].Ply:SteamID() == ply:SteamID() then
				return true
			end
			
			-- Is the owner of the entity friends with us? <3
			if self:AreFriends( self.Data[ ent:EntIndex() ].Ply, ply ) then
				return true
			end
			
		end
		
		return false

	end
	
	-- Trace stuff
	function PLUGIN:PlayerTrace( ply )
		local t = util.TraceLine( util.GetPlayerTrace( ply ) )
		if !t.Entity or !t.Entity:IsValid() or t.Entity:IsPlayer() then return end
		return self:PlayerTouch( ply, t.Entity )
	end
	
	function PLUGIN:EntityTakeDamage( ent, inflictor, attacker, dmg, dmgInfo )
		if !ent:IsValid() or ent:IsPlayer() or !attacker:IsPlayer() then return end
		if !self:PlayerTouch( attacker, ent ) then dmgInfo:SetDamage( 0 ) end
	end
	function PLUGIN:PlayerUse( ply, ent ) return self:PlayerTouch( ply, ent ) end
	function PLUGIN:OnPhysgunReload( wep, ply ) return self:PlayerTrace( ply ) end
	function PLUGIN:PhysgunPickup( ply, ent ) return self:PlayerTouch( ply, ent ) end
	function PLUGIN:GravGunPunt( ply, ent ) return self:PlayerTouch( ply, ent ) end
	function PLUGIN:GravGunPickupAllowed( ply, ent ) return self:PlayerTouch( ply, ent ) end

	function PLUGIN:PlayerInitialSpawn( ply )
		
		-- Friends support
		ply.PPFriends = {}
	
	end
	
	function PLUGIN:MakeOwner( ply, ent )
		if ent:IsPlayer() then return false end -- Beep boop.

		self.Data[ ent:EntIndex() ] = {
			Ent = ent,
			Ply = ply,
		}
		
		self:Debug( "Giving '" .. ply:Nick() .. "' ownership over ent: " .. ent:EntIndex() )
	end
	
	function PLUGIN:EntityRemoved( ent )
		self.Data[ ent:EntIndex() ] = nil
	end
	
	function PLUGIN:PlayerSpawnedSENT( ply, ent ) self:MakeOwner( ply, ent ) end
	function PLUGIN:PlayerSpawnedVehicle( ply, ent ) self:MakeOwner( ply, ent ) end
	
	-- Gmode overrides.
	if exsto.Registry.Player.AddCount then
		PLUGIN.OldAddCount = exsto.Registry.Player.AddCount
		function exsto.Registry.Player:AddCount( t, ent )
			PLUGIN:MakeOwner( self, ent )
			PLUGIN.OldAddCount( self, t, ent )
		end
	end
	
	if cleanup then
		PLUGIN.OldCleanup = cleanup.Add
		function cleanup.Add( ply, t, ent )
			if ent and ent:IsValid() and ply:IsPlayer() then PLUGIN:MakeOwner( ply, ent ) end
			PLUGIN.OldCleanup( ply, t, ent )
		end
	end
	
	-- Unload stuff.
	function PLUGIN:OnUnload()
		
		-- Restore the over-rides we had.
		if exsto.Registry.Player.AddCount and self.OldAddCount then exsto.Registry.Player.AddCount = self.OldAddCount end
		if cleanup and self.OldCleanup then cleanup.Add = self.OldCleanup end
		
		-- TODO: Put the data table somewhere.  If we happen to load again, we need get all that information back ASAP.
	end
end

if CLIENT then
	function PLUGIN:Init()
		self.Friends = {}
	end
	
	-- Sends a friend change to the server.
	function PLUGIN:UpdateServer( id, t )
		local sender = exsto.CreateSender( "ExUpdateFriend" )
			sender:AddString( t )
			sender:AddString( id )
		sender:Send()
		
		self:Debug( "Pushing friend update to server." )
	end
	
	-- Handle new player changes 'n stuff.
	function PLUGIN:Think()
		if !self.Panel then return end
		if !self.Friends then return end
		if !self.PlyTable then self.PlyTable = player.GetAll() end
		
		if #player.GetAll() != #self.PlyTable then
			PLUGIN.Panel.PlayerList:Populate( PLUGIN.Friends )
			self.PlyTable = player.GetAll()
			self:Debug( "Updating player table." )
		end
	end
	
	Menu:CreatePage( {
		Title = "Prop Protection",
		Short = "pprotection",
		},
		function( panel )		
			PLUGIN.Panel = panel
			
			-- Player list view
			panel.PlayerList = exsto.CreateListView( 25, 25, 175, panel:GetTall() - 50, panel )
				panel.PlayerList:AddColumn( "" )
				panel.PlayerList:SetHideHeaders( true )
				panel.PlayerList:SetDataHeight( 30 )
				panel.PlayerList.Populate = function( pnl, exclTable )
					pnl:Clear()
					for _, p in ipairs( player.GetAll() ) do
						if !exclTable[ p:SteamID() ] and ( p:SteamID() != LocalPlayer():SteamID() ) then
							local obj = pnl:AddLine( p:Nick() )
								obj.Ply = p
						end
					end
				end
				
			-- Friends view
			panel.FriendsList = exsto.CreateListView( panel:GetWide() - 200, 25, 175, panel:GetTall() - 50, panel )
				panel.FriendsList:AddColumn( "" )
				panel.FriendsList:SetHideHeaders( true )
				panel.FriendsList:SetDataHeight( 30 )
				panel.FriendsList.Populate = function( pnl, tbl )
					pnl:Clear()
					for id, p in pairs( tbl ) do
						local obj = pnl:AddLine( p:Nick() )
							obj.Ply = p
					end
				end
				
			-- Add to button
			panel.AddTo = exsto.CreateButton( ( panel:GetWide() / 2 ) - ( 75 / 2 ), ( panel:GetTall() / 2 ) - 50, 75, 36, ">", panel )
				panel.AddTo.DoClick = function( pnl )
					local line = panel.PlayerList:GetLine( panel.PlayerList:GetSelectedLine() )
					if !line then return end
					
					PLUGIN:UpdateServer( line.Ply:SteamID(), "add" )
					PLUGIN.Friends[ line.Ply:SteamID() ] = line.Ply
					
					panel.PlayerList:Populate( PLUGIN.Friends )
					panel.FriendsList:Populate( PLUGIN.Friends )
				end
				
			-- Remove from button
			panel.RemoveFrom = exsto.CreateButton( ( panel:GetWide() / 2 ) - ( 75 / 2 ), ( panel:GetTall() / 2 ) + 50, 75, 36, "<", panel )
				panel.RemoveFrom.DoClick = function( pnl )
					local line = panel.FriendsList:GetLine( panel.FriendsList:GetSelectedLine() )
					if !line then return end
					
					PLUGIN:UpdateServer( line.Ply:SteamID(), "rem" )
					PLUGIN.Friends[ line.Ply:SteamID() ] = nil

					panel.PlayerList:Populate( PLUGIN.Friends )
					panel.FriendsList:Populate( PLUGIN.Friends )
				end
			
		end
	)
end


--[[

	CPPI Namespace.
	
]]
CPPI = {}
CPPI_DEFER = 100;
CPPI_NOTIMPLEMENTED = 101;

function CPPI.GetName() return "Exsto" end
function CPPI.GetVersion() return exsto.VERSION end
function CPPI.GetInterfaceVersion() return 1.1 end

-- Honestly why have this in the "interface"  Does it really do anything?
function CPPI.GetNameFromUID( id )
	for _, p in ipairs( player.GetAll() ) do
		if p:UserID() == id then return p:Nick() end
	end
	return nil
end

function exsto.Registry.Player:CPPIGetFriends()

end

function exsto.Registry.Entity:CPPIGetOwner()

end

if SERVER then

	function exsto.Registry.Entity:CPPISetOwner( ply )
	
	end
	
	function exsto.Registry.Entity:CPPISetOwnerUID( id )
	
	end
	
	function exsto.Registry.Entity:CPPICanTool( ply, tool )
	
	end
	
	function exsto.Registry.Entity:CPPICanPhysgun( ply )
	
	end
	
	function exsto.Registry.Entity:CPPICanPickup( ply )
	
	end
	
	function exsto.Registry.Entity:CPPICanPunt( ply )
	
	end
	
end

PLUGIN:Register()