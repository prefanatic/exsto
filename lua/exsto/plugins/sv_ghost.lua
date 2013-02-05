--Exsto Ghost Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Ghost player Plugin",
	ID = "ghost",
	Desc = "A plugin that hides people.",
	Owner = "Hobo",
})

--Hook for checking weapon switches and colouring accordingly.
function PLUGIN:Think()

	for _, ply in ipairs(player.GetAll()) do

		if ply:GetActiveWeapon() then weap = ply:GetActiveWeapon() end
		if weap and weap:IsValid() and weap != ply.LastWeap then
			if ply.Ghosted and weap:GetNWBool("Shadow", true) then
				weap:DrawShadow(false)
				weap:SetNWBool("Shadow", false)
			elseif !ply.Ghosted and !weap:GetNWBool("Shadow", true) then
				weap:DrawShadow(true)
				weap:SetNWBool("Shadow", true)
			end
			ply.LastWeap = weap
		end
		
	end
	
end

function PLUGIN:Ghost( owner, ply )

	if !ply.Ghosted then
		if ply:GetModel() != "models/m_anm.mdl" then ply.OldModel = ply:GetModel() end
		ply:SetModel("models/m_anm.mdl")
		ply:GetActiveWeapon():DrawShadow(false)
		ply:GetActiveWeapon():SetNWBool("Shadow", false)
		ply.Ghosted = true
		ply:SetCollisionGroup(COLLISION_GROUP_DEBRIS) -- TODO: Find what doesn't collide with players
		ply:SetNWBool("HideTag",true)
		return { COLOR.NAME, owner:Nick(), COLOR.NORM, " has ghosted ",COLOR.NAME, ply:Nick(),COLOR.NORM,"." }
		
	elseif ply.Ghosted then
		ply:SetModel(ply.OldModel)
		ply.Ghosted = false
		ply:GetActiveWeapon():SetRenderMode(1)
		ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
		ply:SetNWBool("HideTag",false)
		return { COLOR.NAME, owner:Nick(), COLOR.NORM, " has unghosted ",COLOR.NAME, ply:Nick(),COLOR.NORM,"." }
	end
	
end		
PLUGIN:AddCommand( "ghost", {
	Call = PLUGIN.Ghost,
	Desc = "Hides players",
	Console = { "ghost" },
	Chat = { "!ghost" },
	ReturnOrder = "Player",
	Args = {Player = "PLAYER"},
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