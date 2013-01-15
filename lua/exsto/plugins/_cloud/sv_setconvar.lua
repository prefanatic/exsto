-- Console Variable changer plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Set ConVar",
	ID = "setconvar",
	Desc = "Set's console variables.",
	Owner = "Hobo",
} )

function PLUGIN:SetConVar( owner, var, value )
  local variable = GetConVar( var )
  
    if (string.Left(var,5) == "sbox_" || string.Left(var,5) == "wire_" || string.Left(var,3) == "sv_") && variable then
        RunConsoleCommand(var,value)
        return { COLOR.NAME, owner ,COLOR.NORM," set convar ",COLOR.NAME,var,COLOR.NORM," to ",COLOR.NAME,value,COLOR.NORM,"!" }
        
    elseif variable then
        return { owner, COLOR.NORM, "Unabled to change convar: ",COLOR.NAME,var,COLOR.NORM, "!" }
        
    else
        return { owner, COLOR.NORM, "There is no convar named ", COLOR.NAME, var, COLOR.NORM, "!" }
        
    end

end

PLUGIN:AddCommand( "setconvar", {
	Call = PLUGIN.SetConVar,
	Desc = "Changes minor convars. [sbox_,wire_,sv_]",
	FlagDesc = "Allows users to change minor ConVars.",
	Console = { "setconvar" },
	Chat = { "!setconvar" },
	ReturnOrder = "Variable-Value",
	Args = { Variable = "STRING", Value = "STRING" }
})

PLUGIN:Register()