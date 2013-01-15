-- Prefan Access Controller
-- GIMP Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Gimp",
	ID = "gimp",
	Desc = "A plugin that allows player gimping!",
	Owner = "Prefanatic",
} )

PLUGIN.Sayings = {
	"You smell like me.",
	"Fucking is so fucking awesome.",
	"I sense that you all love me, very, very much.",
	"Seeing is believing.",
	"You look :)",
	"How do I speak llama?",
	"Semper ubi sub ubi!",
	"I realize the truth in your opinion, and swiftly deny it.",
	"I know everything.",
	"Ban me, please.",
	"I hope I'm not gimped.",
	"This server sucks lolol.",
	"Garry is my hero!",
}

function PLUGIN:Init()
	if !file.Exists( "exsto_gimps.txt", "DATA" ) then
		file.Write( "exsto_gimps.txt", string.Implode( "\n", self.Sayings ) )
	else
		self.Sayings = string.Explode( "\n", file.Read( "exsto_gimps.txt" ) )
	end
end

function PLUGIN:AddGimp( owner, message )
	filex.Append( "exsto_gimps.txt", message .. "\n" )
	
	return { owner, COLOR.NORM, "Adding message to ", COLOR.NAME, "gimp data!" }
end
PLUGIN:AddCommand( "addgimp", {
	Call = PLUGIN.AddGimp,
	Desc = "Allows users to add gimp messages.",
	Console = { "addgimp" },
	Chat = { "!addgimp" },
	ReturnOrder = "Message",
	Args = {Message = "STRING"},
	Category = "Chat",
})

function PLUGIN:Gimp( owner, ply )

	local style = " has gimped "
	
	if self:IsGimped( ply ) then
		ply.Gimped = false
		style = " has un-gimped "
	else
		ply.Gimped = true
	end
	
	return {
		Activator = owner,
		Player = ply,
		Wording = style,
	}

end
PLUGIN:AddCommand( "gimp", {
	Call = PLUGIN.Gimp,
	Desc = "Allows users to gimp other players.",
	Console = { "gimp", "ungimp" },
	Chat = { "!gimp", "!ungimp" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
	Category = "Chat",
})
PLUGIN:RequestQuickmenuSlot( "gimp", "Gimp" )

function PLUGIN:Mute( owner, ply )

	local style = " has un-muted "
	if self:IsMuted( ply ) then
		self:SetMute( ply, false )
		ply:SendLua("timer.Destroy(\""..ply:UniqueID().."\")")
	else
		style = " has muted "
		self:SetMute( ply, true )
		ply:SendLua("timer.Create(\""..ply:UniqueID().."\",0.05,0,RunConsoleCommand,\"-voicerecord\")")
	end
		
	return {
		Activator = owner,
		Player = ply,
		Wording = style,
	}
	
end
PLUGIN:AddCommand( "mute", {
	Call = PLUGIN.Mute,
	Desc = "Allows users to mute other players.",
	Console = { "mute" },
	Chat = { "!mute" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
	Category = "Chat",
})
PLUGIN:RequestQuickmenuSlot( "mute", "Mute" )

function PLUGIN:Gag( owner, ply )

	local style = " has gagged "
	
	if ply.Gagged then
		ply.Gagged = false	
		style = " has un-gagged "
	else
		ply.Gagged = true
	end
		
	return {
		Activator = owner,
		Player = ply,
		Wording = style,
	}
	
end
PLUGIN:AddCommand( "gag", {
	Call = PLUGIN.Gag,
	Desc = "Allows users to gag other players.",
	Console = { "gag" },
	Chat = { "!gag" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
	Category = "Chat",
})
PLUGIN:RequestQuickmenuSlot( "gag", "Gag" )

function PLUGIN:SetMute( ply, bool )
	ply.Gagged = bool
end

function PLUGIN:IsMuted( ply )
	if ply.Gagged then return true end
end

function PLUGIN:IsGimped( ply )
	if ply.Gimped then return true end
end

function PLUGIN:IsGagged( ply )
	if ply.Muted then return true end
end

function PLUGIN:PlayerCanHearPlayersVoice( listen, talker )
	return self:IsMuted( talker )
end

function PLUGIN:PlayerSay( ply, text )
	if self:IsGimped( ply ) then
		for i,com in pairs(exsto.Commands) do
			for k,comm in pairs(com.Chat) do
				if string.match( text, comm, 1, true ) then return exsto.ChatMonitor( ply, text ) end -- Pretty ghetto way of doing it, but whatever.
			end
		end
		return self.Sayings[ math.random( 1, #PLUGIN.Sayings ) ]
	end
	if self:IsGagged( ply ) then
		for i,com in pairs(exsto.Commands) do
			for k,comm in pairs(com.Chat) do
				if string.match( text, comm, 1, true ) then return exsto.ChatMonitor( ply, text ) end
			end
		end
		return ""
	end
end

PLUGIN:Register()
