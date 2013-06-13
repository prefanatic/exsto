local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Chat Tags",
	ID = "chattags",
	Desc = "Rank Chat Tags",
	Owner = "Prefanatic",
} )

if SERVER then

	function PLUGIN:Init()
		util.AddNetworkString( "ExSendTagGamemode" )
		
		self.Enabled = exsto.CreateVariable( "ExChatTags", "Chat Tags", 0, "Enables rank chat tags on player chat." )
			self.Enabled:SetBoolean()
			self.Enabled:SetCategory( "Chat Tags" )
			
		self.ColorStyle = exsto.CreateVariable( "ExTagColorStyle", "Color Style", "auto", 
			"Changes the style of rank color for tags.\n 'complementary' : Sets the rank color complementary to the actual color.\n 'actual' : Sets it to the rank color.\n 'auto' : Automatically changes between complementary and actual based on gamemode." )
			self.ColorStyle:SetPossible( "complementary", "actual", "auto" )
			self.ColorStyle:SetCategory( "Chat Tags" )

	end
	
	function PLUGIN:ExGamemodeFound( gm )
		self.Gamemode = gm
	end
	
	function PLUGIN:ExInitSpawn( ply )
		-- Send down whatever gamemode we are running to the player.
		local sender = exsto.CreateSender( "ExSendTagGamemode", ply )
			sender:AddString( self.Gamemode )
		sender:Send()
	end

end

if CLIENT then

	function PLUGIN:Init()
		self.Gamemode = "UNKNOWN"
	end
	
	function PLUGIN:ReadGamemode( reader )
		self.Gamemode = reader:ReadString()
	end
	PLUGIN:CreateReader( "ExSendTagGamemode", PLUGIN.ReadGamemode )
	
	function PLUGIN:OnPlayerChat( ply, str, t, dead )
		if ply:EntIndex() == 0 then return end -- Console, don't care.
		
		self:Debug( "Speaking '" .. ply:Nick() .. "' with '" .. str .. "'", 3 )
		if exsto.GetServerValue( "ExChatTags" ) == 1 then
			local rankData = exsto.GetRankData( ply:GetRank() )
			local rcol = rankData.Color
			
			-- Decide what rank color we need.
			local srvVal = exsto.GetServerValue( "ExTagColorStyle" )
			if srvVal == "complementary" or ( srvVal == "auto" and self.Gamemode != "sandbox" ) then
				rcol = exsto.GenerateComplementaryColor( rankData.Color )
			end
				
			chat.AddText( rcol, "[", rankData.Name, "] ", team.GetColor( ply:Team() ), ply:Nick(), Color( 255, 255, 255, 255 ), ": ", str )
			return true
		end
	end
	
end

PLUGIN:Register()