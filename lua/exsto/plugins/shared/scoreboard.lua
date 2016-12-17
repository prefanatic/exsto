-- Exsto
-- Scoreboard Plugin

local PLUGIN = exsto.CreatePlugin()
PLUGIN:SetInfo({
	Name = "Scoreboard",
	ID = "scoreboard",
	Desc = "A plugin that allows to use a custom scoreboard!",
	Owner = "Patcher56",
} )

if SERVER then

	timer.Simple(1, function()
		PLUGIN.GetCount = exsto.Registry.Player.GetCount
		function exsto.Registry.Player:GetCount(limit, minus)
			if limit == "props" then
				timer.Simple(.1, function() PLUGIN.GetCount(self, limit, 0) end)
			end
			return PLUGIN.GetCount(self, limit, minus)
		end
	end)

elseif CLIENT then

	PLUGIN.TexHeader = surface.GetTextureID( "gui/scoreboard_header" )
	PLUGIN.TexMiddle = surface.GetTextureID( "gui/scoreboard_middle" )
	PLUGIN.TexBottom = surface.GetTextureID( "gui/scoreboard_bottom" )
	
	PLUGIN.Width = 687
	
	surface.CreateFont("ExstoScoreboardHeader", {
		font = "coolvetica",
		size = 30,
		weight = 400,
		antialias = true,
		additive = false,
	})
	
	surface.CreateFont( "ScoreboardText", {
		font = "Trebuchet",
		size = 15,
		weight = 200,
		antialias = true,
		additive = false
	})
	surface.CreateFont( "ScoreboardTextHeader", {
		font = "Trebuchet",
		size = 17,
		weight = 1000,
		antialias = true,
		additive = false
	})
	surface.CreateFont( "InfoText", {
		font = "coolvetica",
		size = 22,
		weight = 0,
		antialias = true,
		additive = false
	})
		surface.CreateFont( "InfoTextBold", {
		font = "coolvetica",
		size = 22,
		weight = 5000,
		antialias = true,
		additive = false
	})
end



function PLUGIN:ScoreboardShow()
	if ( GAMEMODE.IsSandboxDerived and exsto.DebugEnabled ) then
		self.DrawScoreboard = true
		return true
	end
end

function PLUGIN:ScoreboardHide()
	if ( self.DrawScoreboard ) then
		self.DrawScoreboard = false
		return true
	end
end

function PLUGIN:DrawTexturedRect( tex, x, y, w, h )
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetTexture( tex )
	surface.DrawTexturedRect( x, y, w, h )
end

function PLUGIN:QuickTextSize( font, text )
	surface.SetFont( font )
	return surface.GetTextSize( text )
end

function PLUGIN:FormatTime( raw )
	if ( raw < 60 ) then
		return math.floor( raw ) .. " secs"
	elseif ( raw < 3600 ) then
		if ( raw < 120 ) then return "1 min" else return math.floor( raw / 60 ) .. " mins" end
	elseif ( raw < 3600*24 ) then
		if ( raw < 7200 ) then return "1 hour" else return math.floor( raw / 3600 ) .. " hours" end
	else
		if ( raw < 3600*48 ) then return "1 day" else return math.floor( raw / 3600 / 24 ) .. " days" end
	end
end

function PLUGIN:DrawInfoBar()
	// Background
	
	surface.SetDrawColor( 89, 144, 222, 150 )
	surface.DrawRect( self.X + 15, self.Y + 50, self.Width - 30, 35 )
	
	surface.SetDrawColor( 89, 144, 222, 255 )
	surface.DrawOutlinedRect( self.X + 15, self.Y + 50, self.Width - 30, 35 )
	
	// Content
	local x = self.X + 24
	local y = self.Y + 80
	draw.SimpleText( "Currently playing ", "InfoText", x, y, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	x = x + self:QuickTextSize( "InfoText", "Currently playing " )
	draw.SimpleText( "on the map ", "InfoText", x, y, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	x = x + self:QuickTextSize( "InfoText", "on the map " )
	draw.SimpleText( game.GetMap(), "InfoTextBold", x, y, Color( 40, 100, 200, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	x = x + self:QuickTextSize( "InfoTextBold", game.GetMap() )
	draw.SimpleText( ", with ", "InfoText", x, y, Color( 0, 0, 0, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	x = x + self:QuickTextSize( "InfoText", ", with " )
	draw.SimpleText( #player.GetAll(), "InfoTextBold", x, y, Color( 40, 100, 200, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	x = x + self:QuickTextSize( "InfoTextBold", #player.GetAll() )
	local s = ""
	if ( #player.GetAll() > 1 ) then s = "s" end
	draw.SimpleText( " player" .. s .. ".", "InfoTextBold", x, y, Color( 40, 100, 200, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
end

function PLUGIN:DrawUsergroup( playerinfo, title,  y )
	-- local playersFound = false
	-- for _, pl in pairs( playerinfo ) do
		-- if ( pl.Usergroup == usergroup ) then
			-- playersFound = true
			--break
		--end
	--end
	--if ( !playersFound ) then return y end
	
	local y = self.Y + 110
	surface.SetDrawColor( 89, 144, 222, 100 )
	surface.DrawRect( self.X + 15, y, self.Width - 30, 25 )
	draw.SimpleText( "Player", "ScoreboardTextHeader", self.X+20, y+20, Color( 39, 39, 39, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText( "Rank", "ScoreboardTextHeader", self.X+400, y+20, Color( 39, 39, 39, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	--draw.SimpleText( "Time", "ScoreboardTextHeader", self.X+500, y+20, Color( 39, 39, 39, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText( "Ping", "ScoreboardTextHeader", self.X+620, y+20, Color( 39, 39, 39, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	
	y = y + 45
	
	for _, pl in ipairs( playerinfo ) do
		--if ( pl.Usergroup == usergroup ) then
			draw.SimpleText( pl.Nick, "ScoreboardText", self.X + 20, y, Color( 100, 100, 100, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			draw.SimpleText( tostring(pl.Usergroup), "ScoreboardText", self.X +400, y, Color( 100, 100, 100, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			if (pl.Ping < 50) then
				draw.SimpleText( pl.Ping, "ScoreboardText", self.X + 620, y, Color( 0,170,0, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			elseif (pl.Ping < 75) then
				draw.SimpleText( pl.Ping, "ScoreboardText", self.X + 620, y, Color( 150,255,0, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			elseif (pl.Ping < 100) then
				draw.SimpleText( pl.Ping, "ScoreboardText", self.X + 620, y, Color( 220,220,0, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			elseif (pl.Ping < 150) then
				draw.SimpleText( pl.Ping, "ScoreboardText", self.X + 620, y, Color( 255,150,0, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			elseif (pl.Ping < 200) then
				draw.SimpleText( pl.Ping, "ScoreboardText", self.X + 620, y, Color( 255,100,0, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			elseif (pl.Ping >= 200) then
				draw.SimpleText( pl.Ping, "ScoreboardText", self.X + 620, y, Color( 255,0,0, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			end
			--draw.SimpleText( pl.PlayTime, "ScoreboardText", self.X + 500, y, Color( 100, 100, 100, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
			
			
			y = y + 20
		--end
	end
	
	return y
end

function PLUGIN:DrawPlayers()
	local playerInfo = {}
	for _, v in pairs( player.GetAll()) do
		table.insert( playerInfo, { Nick = v:Nick(), Usergroup = v:GetRank(), Ping = v:Ping()} )
		
	end
	
	local y = self.Y + 155
	local serverranks = {}
	for id, rank in pairs( exsto.Ranks ) do
		table.insert( serverranks, { ID = id, Title = rank.Name, Immunity = rank.Immunity} )
	end
	table.SortByMember( playerInfo, "Immunity" )
	
	for _, rank in ipairs( serverranks ) do
			y = self:DrawUsergroup( playerInfo, rank.Title, y )
	end
	
	return y
end

function PLUGIN:HUDDrawScoreBoard()
	if ( !self.DrawScoreboard ) then return end
	if ( !self.Height ) then self.Height = 139 end
	
	// Update position
	self.X = ScrW() / 2 - self.Width / 2
	self.Y = ScrH() / 2 - ( self.Height ) / 2
	
	surface.SetDrawColor( 89, 144, 222, 255 )
	surface.DrawRect(self.X-3, self.Y-3, self.Width+6, self.Height+6)
	surface.SetDrawColor( 230, 230, 230, 255 )
	surface.DrawRect(self.X, self.Y, self.Width, self.Height)
	local headerX = self.X + 15
	--draw.SimpleText( GetHostName(), "ExstoScoreboardHeader", self.X + 16, self.Y + 26, Color( 200, 200, 200, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	draw.SimpleText( "Welcome to ", "ExstoScoreboardHeader", headerX, self.Y + 25, Color( 150, 150, 150, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	headerX = headerX + self:QuickTextSize( "ExstoScoreboardHeader", "Welcome to " )
	draw.SimpleText( GetHostName(), "ExstoScoreboardHeader", headerX, self.Y + 25, Color( 89, 144, 222, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

	surface.SetDrawColor( 255, 255, 255, 255 )
	
	self:DrawInfoBar()
	
	local y = self:DrawPlayers()
	
	self.Height = y - self.Y
end

PLUGIN:Register()