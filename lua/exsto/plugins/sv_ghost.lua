--Exsto Ghost Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Ghost player Plugin",
	ID = "ghost",
	Desc = "A plugin that hides people.",
	Owner = "Hobo",
})

--Hook for checking weapon switches and colouring accordingly.
function PLUGIN:DoAnimationEvent(ply,event,data)

	local weap = ply:GetActiveWeapon()
	if weap then
		--event 38 is weapon switching
		if event == 38 then
			local r,g,b,a = weap:GetColor()
			if a != ply.GAlpha then
				weap:SetColor(255,255,255,ply.GAlpha or 255)
			end
		end
	end
	
end

function PLUGIN:Ghost( owner, ply, a )

	if !ply.Ghosted or a > 0 then
		ply:SetColor(255,255,255,a)
		ply:GetActiveWeapon():SetColor(255,255,255,a)
		ply:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ply.Ghosted = true
		ply.GAlpha = a
		ply:SetNWBool("HideTag",true)
		return { COLOR.NAME, owner:Nick(), COLOR.NORM, " has ghosted ",COLOR.NAME, ply:Nick(),COLOR.NORM,"." }
		
	elseif ply.Ghosted then
		ply:SetColor(255,255,255,255)
		ply:GetActiveWeapon():SetColor(255,255,255,255)
		ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
		ply.Ghosted = false
		ply.GAlpha = 255
		ply:SetNWBool("HideTag",false)
		return { COLOR.NAME, owner:Nick(), COLOR.NORM, " has unghosted ",COLOR.NAME, ply:Nick(),COLOR.NORM,"." }
	end
	
end		
PLUGIN:AddCommand( "ghost", {
	Call = PLUGIN.Ghost,
	Desc = "Hides players",
	Console = { "ghost" },
	Chat = { "!ghost" },
	ReturnOrder = "Player-Alpha",
	Args = {Player = "PLAYER", Alpha = "NUMBER"},
	Optional = {Alpha = 0},
	Category = "Fun",
})

function PLUGIN:FindGhosts( owner )

	local Ghosts = ""
	local players = player.GetAll()
	for i,ply in pairs (players) do
		if ply.Ghosted then
			Ghosts = Ghosts.. ply:Nick()..(i < table.Count(players) and ", " or "")
		end
	end
	
	if Ghosts == "" then
		return { owner,COLOR.NORM,"No ghosts found." }
	end
	return { owner,COLOR.NORM, "Current ghosted players are "..Ghosts }
	
end		
PLUGIN:AddCommand( "findghosts", {
	Call = PLUGIN.FindGhosts,
	Desc = "Lists hidden playes",
	Console = { "findghosts" },
	Chat = { "!findghosts" },
	Category = "Fun",
})

PLUGIN:Register()