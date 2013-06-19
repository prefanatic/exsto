-- Say plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Say",
	ID = "say",
	Desc = "Makes a player forcefully speak.",
	Owner = "Hobo",
} )

function PLUGIN:Say( owner, ply, text )
	text = string.gsub(text,";","")
    if not text then
        return { owner,COLOR.NORM, "You need to enter text for the player to say." }
    else
        local match = 0
        for i,com in pairs(exsto.Commands) do
            for k,comm in pairs(com.Chat) do
                if string.match( text, comm, 1, true ) then match = 1 end
            end
        end
        if owner == ply then
            return { owner,COLOR.NORM, "There is no reason to target yourself." }
        elseif tobool(match) && !owner:IsSuperAdmin() then
            return { owner,COLOR.NORM, "You are not allowed to make other people run commands." }
        else
            ply:ConCommand("say "..text)
        end
    end	
end

PLUGIN:AddCommand( "say", {
	Call = PLUGIN.Say,
	Desc = "Forces a player to talk.",
	FlagDesc = "Allows users to force a player to talk.",
	Console = { "say" },
	Chat = { "!say" },
	ReturnOrder = "Player-Text",
	Args = { Player = "PLAYER",Text = "STRING" }
})

PLUGIN:Register()
