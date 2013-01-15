local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Nodex Commands",
	ID = "nodex",
	Desc = "Nodex shit.",
	Owner = "Prefanatic",
} )

exsto.CreateFlag( "ecs", "Allows basic ECS controls." )
exsto.CreateFlag( "ecs-advanced", "Allows more advanced ECS controls." )
exsto.CreateFlag( "ecs-admin", "Allows administrative ECS controls." )

function _R.Player:query( item )
	return self:IsAllowed( item )
end

function PLUGIN:Godme( self )

	if self.God then
		self:GodDisable()
		self.God = false
		
		return {
			COLOR.NAME, self:Nick(), COLOR.NORM, " has un-godded himself!"
		}
		
	else
		self:GodEnable()
		self.God = true
			
		return {
			COLOR.NAME, self:Nick(), COLOR.NORM, " has godded himself!"
		}
		
	end
	
end
PLUGIN:AddCommand( "godme", {
	Call = PLUGIN.Godme,
	Desc = "Allows users to god-mode themselves",
	Console = { "godme" },
	Chat = { "!godme" },
	Args = { },
})

PLUGIN:Register()
