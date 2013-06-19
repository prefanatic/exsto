local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "God Command",
	ID = "god",
	Desc = "A plugin that contains god!",
	Owner = "Prefanatic",
} )

function PLUGIN:PlayerSpawn( ply )
	if ply.God and ply.ForceGod then
		ply:GodEnable()
	end
end

function PLUGIN:UnGod( self, victim )
	if not victim.God then
		self:Print( exsto_CHAT, COLOR.NAME, victim:Nick(), COLOR.NORM, " is not godded." )
		return
	end
	
	victim:GodDisable()
	victim.God = false
	victim.ForceGod = false
	
	return {
		Activator = self,
		Player = victim,
		Wording = " has de-godded ",
	}
end
PLUGIN:AddCommand( "ungodmode", {
	Call = PLUGIN.UnGod,
	Desc = "Allows users to remove godmode on players.",
	Console = { "ungod" },
	Chat = { "!ungod" },
	Arguments = {
		{ Name = "Victim", Type = COMMAND_PLAYER };
	};
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "ungodmode", "Ungod" )

function PLUGIN:God( self, victim, force )
	if victim.God then
		self:Print( exsto_CHAT, COLOR.NAME, victim:Nick(), COLOR.NORM, " is already godded." )
		return
	end
	
	victim:GodEnable()
	victim.God = true
	victim.ForceGod = force
		
	return {
		Activator = self,
		Player = victim,
		Wording = force and " has perm-godded " or " has godded ",
	}
end
PLUGIN:AddCommand( "godmode", {
	Call = PLUGIN.God,
	Desc = "Allows users to set godmode on players.",
	Console = { "god" },
	Chat = { "!god" },
	Arguments = {
		{ Name = "Victim", Type = COMMAND_PLAYER };
		{ Name = "Force", Type = COMMAND_BOOLEAN, Optional = false };
	};
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "godmode", "God", {
	Force = {
		{ Display = "God After Killed", Data = true },
	},
} )

PLUGIN:Register()