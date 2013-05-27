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
	
	local function OnAFKTimeChange(old,time)
		afkTime = tonumber( time ) * 60
		return true
	end
	
	exsto.CreateFlag("afkkkickignore","Makes the group immune to the AFK Plugin's auto-kicker")
	
	function PLUGIN:Init()
		self.AFKTime = exsto.CreateVariable( "ExAFKDelay",
			"Mark Delay",
			5,
			"Time until a player is marked AFK."
		)
		self.AFKTime:SetCategory( "AFK" )
		self.AFKTime:SetCallback( OnAFKTimeChange )
		self.AFKTime:SetUnit( "Time (minutes)" )
		
		self.AFKAction = exsto.CreateVariable( "ExAFKAction",
			"Action",
			"message",
			"Action to be taken when a player goes AFK.\n - 'message' : State the player is AFK.\n - 'kick' : Kick the player.\n - 'off' : As stated."
		)
		self.AFKAction:SetCategory( "AFK" )
		self.AFKAction:SetPossible( "message", "kick", "off" )
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
				if ply.lastMoved and (time - ply.lastMoved) > self.AFKTime:GetValue()*60 then
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
		local time = (PLUGIN.AFKTime:GetValue()*60)-CurTime()+timeMoved
		local mode = PLUGIN.AFKAction:GetValue()
		
		if time < 0 then
			if !ply.isAFK then
				if mode == "kick" and !ply:HasFlag("afkkickignore") then
					ply:Kick("You have been kicked for being afk")
				elseif mode == "message" then
					ply:SendLua("GAMEMODE:AddNotify(\"You have been marked as AFK.\", NOTIFY_ERROR, 10)")
					exsto.Print(exsto_CHAT_ALL, COLOR.NAME, ply:Name(), COLOR.NORM, " has been marked as AFK!")
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
	
	function PLUGIN:OnPlayerChat( ply, text, teamChat, playerIsDead )
		timeMoved = CurTime()
		if isAFK then
			SendAFKInfo()
			isAFK = false
		end	
	end
end
 
PLUGIN:Register()