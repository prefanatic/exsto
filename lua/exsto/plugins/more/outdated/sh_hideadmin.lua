local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	ID = "hideadmin",
	Name = "Hide/Show Admin",
	Desc = "Hides and shows admin ranks",
	Owner = "Prefanatic",
})

if SERVER then
	function PLUGIN:HideAdmin( caller, ply, rank )
		
		-- Grab the lowest rank we can get.
		local lowImmunity = 0
		local lowShort = rank
		
		if lowShort == "" then
			for short, data in pairs( exsto.Ranks ) do
				if tonumber( data.Immunity ) > tonumber( lowImmunity ) then
					lowImmunity = data.Immunity
					lowShort = short
				end
			end
		end

		if ply:GetNWString( "ExRankHidden" ) == "" then
			ply:SetNWString( "ExRankHidden", lowShort )
			return { caller, COLOR.NORM, "You have hidden ", COLOR.NAME, ply:Nick() .. "'s", COLOR.NORM, " rank!" }
		else
			ply:SetNWString( "ExRankHidden", "" )
			return { caller, COLOR.NORM, "You have re-showed ", COLOR.NAME, ply:Nick() .. "'s", COLOR.NORM, " rank!" }
		end
	end
	PLUGIN:AddCommand( "hideadmin", {
		Call = PLUGIN.HideAdmin,
		Desc = "Allows a player to hide others rank status.",
		Console = { "hiderank", },
		Chat = { "!hiderank" },
		ReturnOrder = "Target-Rank",
		Args = { Target = "PLAYER", Rank = "STRING" },
		Optional = { Rank = "" },
		Category = "Administration",
	})
else
	function PLUGIN:Init()
		local oldGetRank = exsto.Registry.Player.GetRank
		function exsto.Registry.Player.GetRank( self )
			if self:GetNWString( "ExRankHidden" ) != "" then
				return self:GetNWString( "ExRankHidden" )
			else
				return oldGetRank( self )
			end
		end
	end
end

PLUGIN:Register()