--Exsto Banner Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "AFK Plugin",
	ID = "afk",
	Desc = "A plugin that enables a afk marking and automatic kicking.",
	Owner = "Hobo",
})

if SERVER then
	
	util.AddNetworkString("RequestAFKInfo")
	util.AddNetworkString("ReceiveAFKInfo")
	
	local afkTime
	
	local function OnAFKTimeChange(time)
		afkTime = time * 60
		return true
	end
	
	PLUGIN:AddVariable({
		Pretty = "AFK Time",
		Dirty = "afktime",
		Default = 5,
		Description = "Sets the minutes until a player is marked AFK.",
		OnChange = OnAFKTimeChange,
	})
	PLUGIN:AddVariable({
		Pretty = "AFK Action",
		Dirty = "afkaction",
		Default = "message",
		Description = "Action to be taken when a player is afk.",
		Possible = {"message","kick","off"},
	})
	
	function PLUGIN:Init()
		afkTime = exsto.GetVar("afktime").Value-- * 60
	end
	
	function PLUGIN:ExInitSpawn(ply)
		ply.lastMoved = CurTime()
		ply.isAFK = false
	end
	
	local lastThink = CurTime()
	function PLUGIN:Think()
		local time = CurTime()
		if (time - lastThink) > 1 then
			for _, ply in ipairs(player.GetAll()) do
				if (time - ply.lastMoved) > afkTime then
					CheckAFK(ply)
				end
			end
			lastThink = time
		end
	end
	
	function CheckAFK(ply)
		local sender = exsto.CreateSender("RequestAFKInfo", ply)
		sender:AddBool(ply.isAFK)
		sender:Send()
	end
	
	function ReceiveAFKInfo(msg)
		local ply = msg:ReadEntity()
		local timeMoved = msg:ReadShort()
		local time = afkTime-CurTime()+timeMoved
		local mode = exsto.GetVar("afkaction").Value
		
		if time < 0 then
			if !ply.isAFK then
				if mode == "message" then
					ply:SendLua("GAMEMODE:AddNotify(\"You have been marked as AFK.\", NOTIFY_ERROR, 10)")
					exsto.Print(exsto_CHAT_ALL, COLOR.NAME, ply:Name(), COLOR.NORM, " has been marked as AFK!")
				elseif mode == "kick" then
					ply:Kick("You have been kicked for being afk")
				end
				ply.isAFK = true	
			end
			
		else
			if ply.isAFK then
				if mode == "message" then
					exsto.Print(exsto_CHAT_ALL, COLOR.NAME, ply:Name(), COLOR.NORM, " is no longer AFK!")
				end
				ply.isAFK = false		
			end
			ply.lastMoved = timeMoved
		end
	end
	exsto.CreateReader("ReceiveAFKInfo",ReceiveAFKInfo)
	
	
elseif CLIENT then
	
	local isAFK = 			false
	local cursorPos = 		0
	local oldCursorPos = 	1
	local timeMoved = 		0
	
	function RequestAFKInfo(msg)
		isAFK = msg:ReadBool() or true
		SendAFKInfo()
	end
	exsto.CreateReader("RequestAFKInfo",RequestAFKInfo)
	
	function SendAFKInfo()
		local sender = exsto.CreateSender("ReceiveAFKInfo")
		sender:AddEntity(LocalPlayer())
		sender:AddShort(timeMoved)
		sender:Send()
	end
	
	function PLUGIN:Think() -- Detect Cursor movements
		cursorPos = input.GetCursorPos()
		if cursorPos != oldCursorPos then
			oldCursorPos = cursorPos
			timeMoved = CurTime()
			if isAFK then
				SendAFKInfo()
				isAFK = false
			end
		end
	end
	
	function PLUGIN:KeyPress(ply, key) -- Detect Key Presses
		timeMoved = CurTime()
		if isAFK then
			SendAFKInfo()
			isAFK = false
		end
	end
end
 
PLUGIN:Register()