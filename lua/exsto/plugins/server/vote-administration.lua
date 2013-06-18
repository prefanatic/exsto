local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Vote Administration",
	ID = "voteadministration",
	Desc = "Allows clients to votekick and voteban.",
	Owner = "Prefanatic",
} )

function PLUGIN:Votekick( caller, ply )
	local admin = exsto.GetPlugin( "administration" );
	local voteapi = exsto.GetPlugin( "votefuncs" );

	if !admin or !voteapi then
		return { caller, COLOR.NORM, "Missing the proper plugin dependencies (administration/votefuncs)" }
	end

	self.VotePlayer = ply;
	voteapi:Vote( "votekick", "Kick player: " .. ply:Nick() .. "?", { "Yes", "No" }, 25, "chat" )
end
PLUGIN:AddCommand( "votekick", {
	Call = PLUGIN.Votekick,
	Desc = "Allows users to votekick.",
	Console = { "votekick" },
	Chat = { "!votekick" },
	ReturnOrder = "Victim",
	Args = { Victim = "PLAYER" },
	Category = "Administration",
})
PLUGIN:RequestQuickmenuSlot( "votekick", "Votekick" )

function PLUGIN:Voteban( caller, ply )
	local admin = exsto.GetPlugin( "administration" );
	local voteapi = exsto.GetPlugin( "votefuncs" );

	if !admin or !voteapi then
		return { caller, COLOR.NORM, "Missing the proper plugin dependencies (administration/votefuncs)" }
	end

	self.VotePlayer = ply;
	voteapi:Vote( "voteban", "Ban player: " .. ply:Nick() .. "?", { "Yes", "No" }, 25, "chat" )
end
PLUGIN:AddCommand( "voteban", {
	Call = PLUGIN.Voteban,
	Desc = "Allows users to voteban.",
	Console = { "voteban" },
	Chat = { "!voteban" },
	ReturnOrder = "Victim",
	Args = { Victim = "PLAYER" },
	Category = "Administration",
})
PLUGIN:RequestQuickmenuSlot( "voteban", "Voteban" )

function PLUGIN:ExVoteFinished( data )
	if data.ID == "voteban" or data.ID == "votekick" then
		if data.Won == -1 then return end
		
		if data.Won == 1 then -- Yes.
			local admin = exsto.GetPlugin( "administration" );
			if !admin then self:Print( "OHFUCKOHNO!" ) return end
			
			if data.ID == "votekick" then 
				exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "Votekick ", COLOR.NAME, "successful.", COLOR.NORM, "Kicking player: ", COLOR.NAME, self.VotePlayer:Nick() )
				admin:Kick( "Console", self.VotePlayer, "Kicked due to a majority vote" ) 
				return
			elseif data.ID == "voteban" then 
				exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "Voteban ", COLOR.NAME, "successful.", COLOR.NORM, "Banning player: ", COLOR.NAME, self.VotePlayer:Nick() )
				admin:Ban( "Console", self.VotePlayer, 10, "Banned due to a majority vote" ) 
				return 
			end
		end
	end
end

PLUGIN:Register()