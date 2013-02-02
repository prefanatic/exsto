-- Private Message plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Private Message",
	ID = "pm",
	Desc = "Allows PMing.",
	Owner = "Hobo/Prefanatic",
} )

function PLUGIN:PM( from, to, msg )
    if from == to then
        return { exsto_CHAT, COLOR.NORM, "You cannot pm ", COLOR.NAME, "yourself", COLOR.NORM, "!" }
    else
        from:Print(exsto_CHAT,COLOR.EXSTO,"[PM] To ",COLOR.NAME,to,COLOR.NORM,": "..msg)
        to:Print(exsto_CHAT,COLOR.EXSTO,"[PM] From ",COLOR.NAME,from,COLOR.NORM,": "..msg)
        return
    end
end

PLUGIN:AddCommand( "pm", {
	Call = PLUGIN.PM,
	Desc = "Allows PMing",
	FlagDesc = "Allows users to PM another.",
	Console = { "pm" },
	Chat = { "!pm" },
	ReturnOrder = "Player-Message",
	Args = { Player = "PLAYER", Message = "STRING" }
})

PLUGIN:Register()