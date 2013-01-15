-- Exsto

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Entities",
	ID = "entspawn",
	Desc = "A plugin that allows !ent_spawn",
	Owner = "Prefanatic",
} )

function PLUGIN:EntSpawn( owner, class )
	
	if type( owner ) != "Player" then
		self:Print( "You cannot spawn entities through RCON or the dedicated console." )
		return
	end
	
	local ent = ents.Create( class )
	
	local hit = owner:GetEyeTrace().HitPos
		hit.z = hit.z + 30
		
	ent:SetPos( hit )
	ent:Spawn()
	ent:Activate()
	
	undo.Create( "exsto_spawned_ent" )
		undo.AddEntity( ent )
		undo.SetPlayer( owner )
	undo.Finish()
	
	return {
		Activator = owner,
		Object = class,
		Wording = " has created entity "
	}
	
end
PLUGIN:AddCommand( "entspawn", {
	Call = PLUGIN.EntSpawn,
	Desc = "Allows users to spawn entities (regardless of admin status)",
	Category = "Administration",
	Console = { "ent" },
	Chat = { "!ent" },
	ReturnOrder = "Class",
	Args = {Class = "STRING"},
})

PLUGIN:Register()