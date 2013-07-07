local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "TTT Commands",
	ID = "tttcom",
	Desc = "Provides some Trouble in Terror Town specific commands.",
	Owner = "Prefanatic",
	CleanUnload = true;
} )

function PLUGIN:Init()
	self.StartSlays = {}
end

function PLUGIN:ExGamemodeFound( gm )
	if gm != "terrortown" then
		self:Debug( "Running under a non terrortown gamemode.  Unloading!", 1 )
		self:Unload()
	end
end

function PLUGIN:SetTraitor( caller, ply )
	ply:SetRole( ROLE_TRAITOR )
	SendFullStateUpdate()
	
	caller:Print( exsto_CHAT, COLOR.NAME, ply:Nick(), COLOR.NORM, " has been set to a ", COLOR.NAME, "traitor." )
end
PLUGIN:AddCommand( "settraitor", {
	Call = PLUGIN.SetTraitor,
	Console = { "traitor" },
	Chat = { "!traitor" },
	Desc = "Sets a player as traitor.";
	Arguments = {
		{ Name = "Player", Type = COMMAND_PLAYER };
	};
	Category = "TTT";
} )
PLUGIN:RequestQuickmenuSlot( "settraitor", "Traitor" ) 

function PLUGIN:SetDetective( caller, ply )
	ply:SetRole( ROLE_DETECTIVE )
	SendFullStateUpdate()
	
	caller:Print( exsto_CHAT, COLOR.NAME, ply:Nick(), COLOR.NORM, " has been set to a ", COLOR.NAME, "detective." )
end
PLUGIN:AddCommand( "setdetective", {
	Call = PLUGIN.SetDetective,
	Console = { "detective" },
	Chat = { "!detective" },
	Desc = "Sets a player as detective.";
	Arguments = {
		{ Name = "Player", Type = COMMAND_PLAYER };
	};
	Category = "TTT";
} )
PLUGIN:RequestQuickmenuSlot( "setdetective", "Detective" ) 

function PLUGIN:SetInnocent( caller, ply )
	ply:SetRole( ROLE_INNOCENT )
	SendFullStateUpdate()
	
	caller:Print( exsto_CHAT, COLOR.NAME, ply:Nick(), COLOR.NORM, " has been set to an ", COLOR.NAME, "innocent." )
end
PLUGIN:AddCommand( "setinnocent", {
	Call = PLUGIN.SetInnocent,
	Console = { "innocent" },
	Chat = { "!innocent" },
	Desc = "Sets a player as innocent.";
	Arguments = {
		{ Name = "Player", Type = COMMAND_PLAYER };
	};
	Category = "TTT";
} )
PLUGIN:RequestQuickmenuSlot( "setinnocent", "Innocent" ) 

function PLUGIN:SetCredits( caller, ply, credits )
	ply:SetCredits( credits )
	caller:Print( exsto_CHAT, COLOR.NAME, ply:Nick(), COLOR.NORM, "'s credits have been set to ", COLOR.NAME, tostring( credits ) )
end
PLUGIN:AddCommand( "setcredits", {
	Call = PLUGIN.SetCredits,
	Console = { "setcredits" },
	Chat = { "!setcredits" },
	Desc = "Sets the credits of a player.";
	Arguments = {
		{ Name = "Player", Type = COMMAND_PLAYER };
		{ Name = "Credits", Type = COMMAND_NUMBER };
	};
	Category = "TTT";
} )
PLUGIN:RequestQuickmenuSlot( "setcredits", "Set Credits", {
	Credits = {
		{ Display = "1 Credit", Data = 1 };
		{ Display = "3 Credits", Data = 3 };
		{ Display = "5 Credits", Data = 5 };
		{ Display = "10 Credits", Data = 10 };
	};
} ) 

function PLUGIN:TTTBeginRound()
	self:Debug( "TTT Round begin.  Slaying designated players.", 1 )
	
	for _, p in ipairs( self.StartSlays ) do
		p:Kill()
	end
	self.StartSlays = {}
end

function PLUGIN:SlayOnStart( caller, ply )
	table.insert( self.StartSlays, ply )
	exsto.Print( exsto_CHAT_ALL, COLOR.NAME, ply:Nick(), COLOR.NORM, " will be slain at the start of the next round." )
end
PLUGIN:AddCommand( "roundslay", {
	Call = PLUGIN.SlayOnStart,
	Console = { "roundslay" },
	Chat = { "!roundslay" },
	Desc = "Slays a player at the start of the next round.";
	Arguments = {
		{ Name = "Player", Type = COMMAND_PLAYER };
	};
	Category = "TTT";
} )
PLUGIN:RequestQuickmenuSlot( "roundslay", "Slay on Round Start" ) 

function PLUGIN:RemoveSlayOnStart( caller, ply )
	for _, p in ipairs( self.StartSlays ) do
		if p == ply then
			table.remove( self.StartSlays, _ )
			exsto.Print( exsto_CHAT_ALL, COLOR.NAME, ply:Nick(), COLOR.NORM, " will no longer be slain next round." )
			return
		end
	end
	
	caller:Print( exsto_CHAT, COLOR.NAME, ply:Nick(), COLOR.NORM, " is not set to be slain for the next round." )
end
PLUGIN:AddCommand( "remroundslay", {
	Call = PLUGIN.RemoveSlayOnStart,
	Console = { "remroundslay" },
	Chat = { "!remroundslay" },
	Desc = "Removes a previously set player from being slain at the next round.";
	Arguments = {
		{ Name = "Player", Type = COMMAND_PLAYER };
	};
	Category = "TTT";
} )
PLUGIN:RequestQuickmenuSlot( "remroundslay", "Remove Round Slay" ) 

PLUGIN:Register()