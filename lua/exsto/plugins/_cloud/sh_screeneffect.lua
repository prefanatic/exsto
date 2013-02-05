--Exsto Screen Effect Plugin

if SERVER then
	local PLUGIN = exsto.CreatePlugin()
	
	util.AddNetworkString("ExEffects")

	PLUGIN:SetInfo({
		Name = "Screen Effect Plugin",
		ID = "scr-effect",
		Desc = "A plugin that allows random screen effects.",
		Owner = "Hobo",
	})

	function PLUGIN:Effect( owner, ply, effect )
		if ply.Effect && ply.Effect != "" then
			RP = RecipientFilter()
			RP:RemoveAllPlayers()
			RP:AddPlayer(ply)
			umsg.Start("ExEffects", RP)
				umsg.String(ply.Effect)
				umsg.Bool(false)
			umsg.End()
			RP:AddAllPlayers()
			
			ply.Effect = ""
			return { COLOR.NAME,owner:Nick(),COLOR.NORM," removed the effect on ",COLOR.NAME,ply:Nick(),COLOR.NORM,"." }	
		else
			local effect = string.lower(effect)
			if effect == "cartoon" then
				RP = RecipientFilter()
				RP:RemoveAllPlayers()
				RP:AddPlayer(ply)
				umsg.Start("ExEffects", RP)
					umsg.String("cartoon")
					umsg.Bool(true)
				umsg.End()
				RP:AddAllPlayers()
				
				ply.Effect = "cartoon"
			else
				return { owner,COLOR.NORM,"Invalid effect." }
			end
			return { COLOR.NAME,owner:Nick(),COLOR.NORM," put the ",COLOR.NAME,effect,COLOR.NORM," effect on ",COLOR.NAME,ply:Nick(),COLOR.NORM,"." }	
		end
	end		
	PLUGIN:AddCommand( "effect", {
		Call = PLUGIN.Effect,
		Desc = "Puts an effect on a player.",
		Console = { "effect" },
		Chat = { "!effect","!uneffect" },
		ReturnOrder = "Player-Effect",
		Args = { Player = "PLAYER", Effect = "STRING" },
		Optional = { Effect = "cartoon" }
	})
	
	function PLUGIN:Blind( owner, ply, amount )
		if not ply.Blind then
			ply:SendLua("hook.Add('HUDPaint','ExBlind',function() draw.RoundedBox(0,0,0,ScrW(),ScrH(),Color(255,255,255,"..amount..")) end)")
			ply.Blind = true
			return { COLOR.NAME,owner:Nick(),COLOR.NORM," blinded ",COLOR.NAME,ply:Nick(),COLOR.NORM," by ",COLOR.NAME,amount,COLOR.NORM,"." }
		else
			ply:SendLua("hook.Remove('HUDPaint','ExBlind')")
			ply.Blind = false
			return { COLOR.NAME,owner:Nick(),COLOR.NORM," unblinded ",COLOR.NAME,ply:Nick(),COLOR.NORM,"." }
		end
	end		
	PLUGIN:AddCommand( "blind", {
		Call = PLUGIN.Blind,
		Desc = "Blinds a player.",
		Console = { "blind" },
		Chat = { "!blind","!unblind" },
		ReturnOrder = "Player-Amount",
		Args = { Player = "PLAYER", Amount = "NUMBER" },
		Optional = { Amount = "255" }
	})
	
	function PLUGIN:Seiz( owner, ply, amount )
		if not ply.Seiz then
			ply:SendLua("hook.Add('HUDPaint','Seiz',function() local col = (math.floor(CurTime()*100) % 2) draw.RoundedBox(0,0,0,ScrW(),ScrH(),Color(col*255,col*255,col*255,"..amount..")) end)")
			ply.Seiz = true
			return { COLOR.NAME,owner:Nick(),COLOR.NORM," has given ",COLOR.NAME,ply:Nick(),COLOR.NORM," a seizure." }
		else
			ply:SendLua("hook.Remove('HUDPaint','Seiz')")
			ply.Seiz = false
			return { COLOR.NAME,owner:Nick(),COLOR.NORM," has removed ",COLOR.NAME,ply:Nick(),COLOR.NORM,"'s seizure." }
		end
	end		
	PLUGIN:AddCommand( "seizure", {
		Call = PLUGIN.Seiz,
		Desc = "May cause seizures.",
		Console = { "seizure" },
		Chat = { "!seizure","!unseizure" },
		ReturnOrder = "Player-Amount",
		Args = { Player = "PLAYER", Amount = "NUMBER" },
		Optional = { Amount = "255" }
	})
	
	function PLUGIN:Rave( owner, ply, amount )
		if not ply.Rave then
			ply:SendLua("hook.Add('HUDPaint','Rave',function() draw.RoundedBox(0,0,0,ScrW(),ScrH(),Color(math.random(255),math.random(255),math.random(255),"..amount..")) end)")
			ply.Rave = true
			return { COLOR.NAME,owner:Nick(),COLOR.NORM," has invited ",COLOR.NAME,ply:Nick(),COLOR.NORM," to rave." }
		else
			ply:SendLua("hook.Remove('HUDPaint','Rave')")
			ply.Rave = false
			return { COLOR.NAME,owner:Nick(),COLOR.NORM," has stopped ",COLOR.NAME,ply:Nick(),COLOR.NORM," ravin'." }
		end
	end		
	PLUGIN:AddCommand( "rave", {
		Call = PLUGIN.Rave,
		Desc = "Allows forcing of rave parties.",
		Console = { "rave" },
		Chat = { "!rave","!unrave" },
		ReturnOrder = "Player-Amount",
		Args = { Player = "PLAYER", Amount = "NUMBER" },
		Optional = { Amount = "150" }
	})

	PLUGIN:Register()
	
elseif CLIENT then
	function ExEffects(Type)
		local Effect = Type:ReadString()
		local Toggle = Type:ReadBool()
		if Toggle then
			if Effect == "cartoon" then
			hook.Add("RenderScreenSpaceEffects",Effect, function()
				DOF_SPACING = 8
				DOF_OFFSET = 9
				DOF_Start()
				
				DrawSobel(0.01)
			end)
			end
		else
			DOF_Kill()
			hook.Remove("RenderScreenSpaceEffect")
		end
	end
	usermessage.Hook("ExEffects",ExEffects)
end