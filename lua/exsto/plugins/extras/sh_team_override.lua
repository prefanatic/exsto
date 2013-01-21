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
	
	//print( GAMEMODE.Name )
	//if GAMEMODE.Name != "Sandbox" then exsto.Print( exsto_CONSOLE, "Team to Rank Plugin --> Gamemode is not Sandbox!  Not running!" ) return end
	
	PLUGIN.Teams = {}
	
	function PLUGIN:ExSetRank( ply )
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
		ply:SetTeam( info.Team )
	end

	function PLUGIN:ExRanksLoaded()
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
		
		for k,v in pairs( ranks ) do
			self.Teams[k] = {
				Name = v.Name,
				Short = v.Short,
				Color = v.Color,
				Team = index
			}
			
			team.SetUp( index, v.Name, v.Color )
			index = index + 1
		end

	end
	PLUGIN:BuildTeams()
	
elseif CLIENT then
	
	local function receive( reader )
		team.SetUp( reader:ReadShort(), reader:ReadString(), reader:ReadColor() )
	end
	exsto.CreateReader( "teamToRankSend", receive )

end

PLUGIN:Register()
