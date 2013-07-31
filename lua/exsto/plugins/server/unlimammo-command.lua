local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	ID = "unlimammo",
	Name = "Unlimited Ammo",
	Desc = "Creates the unlimited ammo commands.",
	Owner = "Prefanatic",
})

function PLUGIN:Tick()
	for _, ply in ipairs( player.GetAll() ) do
		if ply:Alive() and ply:GetActiveWeapon() != NULL and ply.ExUnlimAmmo then
			self:SetAmmo( ply )
		end
	end
end

function PLUGIN:SetAmmo( ply )
	local wep = ply:GetActiveWeapon()
	
	if wep == NULL then return end
	ply:GiveAmmo( ply:GetAmmoCount( wep:GetPrimaryAmmoType() ) + 1, wep:GetPrimaryAmmoType() )
	ply:GiveAmmo( ply:GetAmmoCount( wep:GetSecondaryAmmoType() ) + 1, wep:GetSecondaryAmmoType() )
	
end

function PLUGIN:UnlimitedAmmo( caller, target )
	local t = " has disabled unlimited ammo on "
	if !target.ExUnlimAmmo then
		target.ExUnlimAmmo = true
		t = " has enabled unlimited ammo on "
		self:SetAmmo( target )
	else
		target.ExUnlimAmmo = false
	end
	
	return {
		Activator = caller,
		Player = target,
		Wording = t,
	}
end
PLUGIN:AddCommand( "unlimitedammo", {
	Call = PLUGIN.UnlimitedAmmo,
	Desc = "Allows a player to set unlimited ammo for others.",
	Console = { "unlimammo", },
	Chat = { "!unlimammo" },
	ReturnOrder = "Target",
	Args = {Target="PLAYER"},
	Category = "Fun",
})
PLUGIN:RequestQuickmenuSlot( "unlimitedammo", "Unlimited Ammo" )

PLUGIN:Register()