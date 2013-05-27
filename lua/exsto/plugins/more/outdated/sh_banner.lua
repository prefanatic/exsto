--Exsto Banner Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Banner Plugin",
	ID = "banner",
	Desc = "A plugin that enables a bar at the top for advertising or general use.",
	Owner = "Hobo",
})

if SERVER then
	
	util.AddNetworkString("BannerInfo")
	
	function PLUGIN:Init()
		BText = exsto.GetVar("bannertext").Value
	end
	
	local function BEnabledChange(enabled)
		PLUGIN:SendBannerInfo(player.GetAll(),enabled)
		return true
	end
	
	PLUGIN:AddVariable({
		Pretty = "Banner Enabled",
		Dirty = "banner",
		Default = true,
		Description = "If the banner is shown or not.",
		OnChange = BEnabledChange,
		Possible = {true,false}
	})
	PLUGIN:AddVariable({
		Pretty = "Banner Text",
		Dirty = "bannertext",
		Default = "Welcome to #hostname, enjoy your stay!",
		Description = "Sets the banner's default text.",
	})
	
	function PLUGIN:SendBannerInfo(ply, enabled)
		enabled = enabled or exsto.GetVar("banner").Value
		    //Sender args = Banner Enabled and Banner text.
		local sender = exsto.CreateSender("BannerInfo",ply)
		sender:AddBool(enabled)
		sender:AddString(BText)
		sender:Send()
	end

	function PLUGIN:ExClientPluginsReady(ply)
		self:BannerText(ply, BText)
	end

	function PLUGIN:BannerText(owner, text)
		BText = text
		BText = string.gsub(BText,"#hostname",GetConVarString("hostname")) //Not able to be retrieved from Client easily.
		BText = string.gsub(BText,"#maxplayers",game.MaxPlayers()) //Non-updated so we will sub it here.
		self:SendBannerInfo(player.GetAll())
		return { COLOR.NAME,owner:Nick(),COLOR.NORM," has changed the banner text to \"",COLOR.NAME,text,COLOR.NORM,"\"" }
	end
	PLUGIN:AddCommand( "bannertext", {
		Call = PLUGIN.BannerText,
		Desc = "Allows the user to change the banner's text.",
		Console = { "bannertext" },
		Chat = { "!bannertext" },
		ReturnOrder = "Message",
		Args = {Message = "STRING"},
		Category = "Utilities",
	})
	
	function PLUGIN:BannerEnabled(owner, enabled)
	// Default - Switch the banner to the opposite
		if enabled == "NOT" then
			enabled = not exsto.GetVar("banner").Value
		else 
			enabled = tobool(enabled)
		end
		exsto.SetVar("banner",enabled)
		self:SendBannerInfo(player.GetAll())
		return { COLOR.NAME,owner:Nick(),COLOR.NORM," has "..(enabled and "en" or "dis").."abled the banner." }
	end
	PLUGIN:AddCommand( "banner", {
		Call = PLUGIN.BannerEnabled,
		Desc = "Allows the user turn the banner on/off.",
		Console = { "banner" },
		Chat = { "!banner" },
		ReturnOrder = "Enabled",
		Args = {Enabled = "STRING"},
		Optional = { Enabled = "NOT" },
		Category = "Utilities",
	})


elseif CLIENT then
	
	function PLUGIN:Init()
		self.Enabled = self.Enabled or false
		self.Text = self.Text or "Welcome!"
	end
		
	function BannerInfo( reader )
		local NewVal = reader:ReadBool()
		PLUGIN.Enabled = NewVal
		PLUGIN.Text = reader:ReadString()
	end
	exsto.CreateReader("BannerInfo",BannerInfo)

	function PLUGIN:HUDPaint()
		if self.Enabled then
			local Font = "Trebuchet24"
			surface.SetFont(Font)
			local w,h = surface.GetTextSize(self.Text)
			fullh = h+10
			draw.RoundedBox(0,0,0,ScrW(),h+10,Color(50,50,50,200))
			X = ScrW()-((CurTime()*70-w)%(ScrW()))
			draw.SimpleText(self.Text,Font,X,(h+10)/2-h/2,Color(255,255,255,255))
			if (X < 0 or X+w > ScrW()) and w < (ScrW()-10) then
				draw.SimpleText(self.Text,Font,X+(X<0 and ScrW() or -ScrW()),(h+10)/2-h/2,Color(255,255,255,255))
			end
			local r,g,b = COLOR.EXSTO
			surface.SetDrawColor(r,g,b,255)
			surface.DrawLine(0,h+10,ScrW(),h+10)
		end
	end
	
end
 
PLUGIN:Register()