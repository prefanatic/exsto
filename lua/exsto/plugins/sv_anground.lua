--Exsto Prop Angle Rounding Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Prop Angle Round Plugin",
	ID = "anground",
	Desc = "A plugin that allows rounding prop angles to specified angles.",
	Owner = "Hobo",
})

function PLUGIN:Round( owner, p, y, r )
	Prop = owner:GetEyeTrace().Entity
	if !owner:IsAdmin() && ((FPP && Prop.Owner != owner) || (SPP && Prop:GetNWEntity("OwnerObj") != owner)) then
		return { owner,COLOR.NORM,"You are not the owner of this prop" }
	elseif Prop:GetClass() == "prop_physics" then
		local P = Prop:GetAngles().p
		local Y = Prop:GetAngles().y
		local R = Prop:GetAngles().r
		local rP = math.Round(P/p)*p
		local rY = math.Round(Y/y)*y
		local rR = math.Round(R/r)*r
		if P != rP && Y != rY && R != rR then
			Prop:SetAngles(Angle(rP,rY,rR))
			P = math.Round(P)
			Y = math.Round(Y)
			R = math.Round(R)
			return { owner,COLOR.NORM,"Angle rounded from",COLOR.NAME,P.." "..Y.." "..R,COLOR.NORM," to ",COLOR.NAME,rP..","..rY..","..rR }
		else
			return { owner,COLOR.NORM,"Angle is the same." }
		end
	end
	return { owner,COLOR.NORM,"Invalid Target." }
end		
PLUGIN:AddCommand( "round", {
	Call = PLUGIN.Round,
	Desc = "Rounds a prop's angle.",
	Console = { "anground" },
	Chat = { "!anground" },
    ReturnOrder = "Pitch-Yaw-Roll",
    Args = { Pitch = "NUMBER", Yaw = "NUMBER", Roll = "NUMBER" },
	Optional = { Pitch = 90, Yaw = 90, Roll = 90 }
})

PLUGIN:Register()