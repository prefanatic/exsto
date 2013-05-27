--Exsto Count Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Entity Count Plugin",
	ID = "entcount",
	Desc = "A plugin that allows counting of entities.",
	Owner = "Hobo",
})

function PLUGIN:Count( owner, ply, class )
	Count = ply:GetCount(class)
	return { owner,COLOR.NAME,ply:Nick(),COLOR.NORM," has "..Count,COLOR.NAME," "..class }
end		
PLUGIN:AddCommand( "count", {
	Call = PLUGIN.Count,
	Desc = "Counts players stuff",
	Console = { "count" },
	Chat = { "!count" },
    ReturnOrder = "Player-Class",
    Args = { Player = "PLAYER", Class = "STRING" },
	Optional = { Class = "props" },
	Category = "Utilities",
})

PLUGIN:Register()