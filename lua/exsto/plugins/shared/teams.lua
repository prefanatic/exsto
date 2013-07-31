-- Exsto
-- Rank over-ride team plugin.

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Team to Rank Plugin",
	ID = "team_override",
	Desc = "A plugin that over-rides the Garry's Mod teams with Exsto ranks.",
	Owner = "Prefanatic",
	Experimental = false,
} )

if SERVER then

	util.AddNetworkString( "teamToRankSend" )
	
	local function onchange( old, val )
		if val == 1 then -- We need to send this code out and push the ranks down.
			PLUGIN.OldTeamData = team.GetAllTeams();
			PLUGIN.OldTeams = {};
			
			PLUGIN:ExRanksLoaded()
			return true
		elseif val == 0 then
			PLUGIN:Unload( "Disabled in settings." )
			return true
		end
	end
	
	function PLUGIN:Init()
		-- Variables
		self.Enabled = exsto.CreateVariable( "ExTeamOverride",
			"Team Rank Colors",
			0,
			"Sets up sandbox teams to match Exsto's rank colors.\n - Allows for scoreboard and chat color names."
		)
			self.Enabled:SetCallback( onchange )
			self.Enabled:SetCategory( "Sandbox" )
			self.Enabled:SetBoolean()
		
		self.Teams = {}
		self.OldTeams = {}
		self.OldTeamData = team.GetAllTeams()
		
		if self.Enabled:GetValue() == 1 then
			self:ExRanksLoaded()
		else
			self:Unload( "Disabled in settings." )
		end
	
	end
	
	function PLUGIN:OnUnload()
		-- Reset the old team setup we had.
		for id, data in ipairs( self.OldTeamData ) do
			self:Debug( "Attempting to restore old team: " .. id .. " with name " .. data.Name, 1 )
			-- Serverside
			team.SetUp( id, data.Name, data.Color, data.Joinable )
			
			-- Clientside
			local sender = exsto.CreateSender( "teamToRankSend", player.GetAll() )
				sender:AddShort( id )
				sender:AddString( data.Name )
				sender:AddColor( data.Color )
				sender:AddBool( data.Joinable )
			sender:Send()
		end
		
		for _, data in ipairs( self.OldTeams ) do
			if data.Player and data.Player:IsValid() and data.Player:IsPlayer() then
				data.Player:SetTeam( data.Team )
			end
		end
		
	end
	
	function PLUGIN:ExSetRank( ply )
		if self.Enabled:GetValue() == 0 then return end
		
		local rank = ply:GetRank()
		local info = self.Teams[rank]

		if ply:GetNWString( "ExRankHidden" ) != "" then
			rank = ply:GetNWString( "ExRankHidden" )
		end

		if !info then ply:SetTeam( 1 ) return end
		
		for k,v in pairs( self.Teams ) do
			local sender = exsto.CreateSender( "teamToRankSend", ply )
				sender:AddShort( v.Team )
				sender:AddString( v.Name )
				sender:AddColor( v.Color )
			sender:Send()
		end
		table.insert( self.OldTeams, { Player = ply, Team = ply:Team() } )
		
		ply:SetTeam( info.Team )
	end
	
	function PLUGIN:ExInitSpawn( ply )
		self:ExSetRank( ply )
		self:Debug( "Updating new player joined rank team.", 1 )
	end

	function PLUGIN:ExRanksLoaded()
		if self.Enabled:GetValue() == 0 then return end
		
		-- We are apparently called by the resend rank hook
		self:BuildTeams() -- They need to be updated again with new ranks.
		
		for k, ply in pairs( player.GetAll() ) do
			for k,v in pairs( self.Teams ) do
				local sender = exsto.CreateSender( "teamToRankSend", ply )
					sender:AddShort( v.Team )
					sender:AddString( v.Name )
					sender:AddColor( v.Color )
				sender:Send()
			end
			self:ExSetRank( ply )
		end
	end

	function PLUGIN:BuildTeams()
		local ranks = exsto.Ranks
		local index = 1
		
		for k,v in SortedPairsByMemberValue( ranks, "Immunity", true ) do
			self.Teams[k] = {
				Name = v.Name,
				Short = v.ID,
				Color = v.Color,
				Team = index
			}
			
			team.SetUp( index, v.Name, v.Color )
			index = index + 1
		end

	end
	
elseif CLIENT then
	local function receive( reader )
		team.SetUp( reader:ReadShort(), reader:ReadString(), reader:ReadColor(), reader:ReadBool() or nil )
	end
	exsto.CreateReader( "teamToRankSend", receive )
end

PLUGIN:Register()
