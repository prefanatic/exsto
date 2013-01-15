-- Private Message plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Private Message",
	ID = "pm",
	Desc = "Allows PMing.",
	Owner = "Hobo",
} )

function PLUGIN:PM( from, to, msg )
    if from == to then
        return { exsto_CHAT,COLOR.NORM,"PM someone other than yourself." }
    else
        from:Print(exsto_CHAT,COLOR.GREEN,"[PM] > ",COLOR.NAME,to,COLOR.NORM,": "..msg)
        to:Print(exsto_CHAT,COLOR.GREEN,"[PM] < ",COLOR.NAME,from,COLOR.NORM,": "..msg)
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