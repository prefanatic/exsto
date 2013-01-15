include( "shared.lua" )

-- RULES
ENT.Rules = {"1. Kick ass",
			"2. Kick more ass",
			"3. Kick more than that",
			"4. You can't leave.",
			"201. OH my god this is a long rule jesus christ.",
}

-- Draw Variables
ENT.Alpha = 255
ENT.Font = "Panel_Font94"
ENT.BigFont = "Panel_Font128"
ENT.SmallFont = "Panel_Font64"

local fontTbl = {
	font = "coolvetica",
	size = 0,
	weight = 400,
}
for I = 48, 128 do
	fontTbl.size = I;
	surface.CreateFont( "Panel_Font" .. I, fontTbl );
end
 
-- Colors
ENT.Text = Color( 255, 255, 255, 255 )
ENT.Outline = Color( 0, 0, 0, 255 )

-- Do Not Touch
ENT.Players = {}
ENT.NextPRefresh = 0
ENT.LagX = 0
ENT.LagY = 0

-- Scalarrrrrr
ENT.Scale = 5
ENT.Scale_X = ENT.Scale
ENT.Scale_Y = ENT.Scale

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()

	self.BaseClass:Initialize()
	
	self:SetRenderBounds( Vector( -1000, -1000, -1000 ), Vector( 1000, 1000, 1000 ) )
	
end

function ENT:SetUpDraw( SetToEyes, Reverse )

	local ply = LocalPlayer()
	local entpos = self:GetPos()
	local dist = ply:GetPos():Distance( entpos )
	
	local max = self:OBBMaxs()
	local min = self:OBBMins()
	
		min.x = max.x + 1
		min.y = min.y + 2
		min.z = max.z
		
	local ang = LocalPlayer():EyeAngles()
	if (!SetToEyes) then ang = self:GetAngles() end
	if !Reverse then
		ang:RotateAroundAxis( ang:Forward(), 90 )
		ang:RotateAroundAxis( ang:Right(), 90 )
	elseif Reverse then
		ang:RotateAroundAxis( ang:Forward(), 90 )
		ang:RotateAroundAxis( ang:Right(), -90 )
	end
	
	local to = self:GetPos() - LocalPlayer():GetPos()
		to.x = math.Clamp( to.x, -1, 1 )
		to.y = math.Clamp( to.y, -1, 1 )
		to.z = math.Clamp( to.z, -1, 1 )
		
	--local pos = ( self:LocalToWorld( min ) + ang:Up() * math.sin( CurTime() ) * 2 ) 
	local pos = ( self:GetPos() + ang:Up() ) + ang:Up() * 20
	
	local center = self:GetWide() / 2

	return pos, ang, center
	
end

function ENT:MonitorDistance()

	local ply = LocalPlayer()
	local ply_pos = ply:GetPos()
	local self_pos = self:GetPos()
	local dist = ply_pos:Distance( self_pos )
	
	if dist >= 1000 then return true end
	
	return false
	
end

function ENT.RefreshPlayerList()

	self.Players = player.GetAll()
	
end

function ENT:CalcFontSize( text, maxWidth, maxFont )

	local fnt = maxFont
	for i = 48, maxFont do 
	
		local w = self:GetTextSize( text, "Panel_Font"..i )
		
		if w > maxWidth then
		
			fnt = math.Round( i - 3 ) 
			break 
			
		end
		
	end
	return fnt
	
end

function ENT:Animate( x, y )

	mul = math.floor( 1 / FrameTime() ) / 3

	if self.LagX != x then
	
		local dist = x - self.LagX
		local speed = dist / mul
		
		self.LagX = math.Approach( self.LagX, x, speed )
		
	end
	
	if self.LagY != y then
	
		local dist = y - self.LagY
		local speed = dist / mul
		
		self.LagY = math.Approach( self.LagY, y, speed )
		
	end
	
end

local texture = surface.GetTextureID( "gui/gradient_down" )
//local texture = Material( "gui/gradient_down" ):SetMaterialInt( "$alpha", 0 )

function ENT:DrawTranslucent()

	if not COLOR then return end

	local pos, ang = self:SetUpDraw( false, false )
	
	local Scale_X = self.Scale_X
	local Scale_Y = self.Scale_Y
	
	cam.Start3D2D( pos, ang, 0.1 )
	
		local hostname = self:GetNWString( "Hostname" )
	
		local w = 200 * Scale_X
		local h = 350 * Scale_Y
		local x = ( self:GetWide() / 2 )
		local y = ( h / 2 ) * -1
		local curY = 20
		
		if self:MonitorDistance() then
			x = -x
			y = -y
		end
		
		self:Animate( x, y )

		local x = self.LagX
		local y = self.LagY
	
		surface.SetDrawColor( 163, 237, 255, 130 )
		surface.DrawRect( x, y, w , h )
		
		surface.SetDrawColor( 223, 255, 255, 160 )
		surface.SetTexture( texture )
		surface.DrawTexturedRect( x + 20, y + 20, ( w ) - 40, h - 140)
		
		surface.SetDrawColor( 0, 0, 0, 130 )
		surface.DrawOutlinedRect( x, y, w, h )
		
		local hostFont = self:CalcFontSize( hostname, w - 80, 128 )
		local nw, nh = self:GetTextSize( hostname, hostFont )
		draw.SimpleText( hostname, hostFont, (w / 2 ) + 20, y + 20, COLOR.BLUE, 1, 0, 1, self.Outline )
		curY = curY + nh

		local ruleFont = self:CalcFontSize( "RULES: ", w - 80, 94 )
		local rw, rh = self:GetTextSize( "RULES: ", ruleFont )
		draw.SimpleText( "RULES: ", ruleFont, x + 40, y + 40 + nh, COLOR.BLUE, 0, 0 )
		curY = curY + rh
		
		local maxFont = "Panel_Font94";
		local max = 0;
		for k,v in pairs( self.Rules ) do
		
			local ruleFont = self:CalcFontSize( v, w - 180, 94 )
			local w = self:GetTextSize( v, ruleFont )
			
			if w >= max then 
				max = w 
				maxFont = ruleFont
			end
		
		end

		local I = y + 40 + nh + rh
		for k,v in pairs( self.Rules ) do

			local rw, rh = self:GetTextSize( v, maxFont )
		
			draw.SimpleText( v, maxFont, x + 90, I, Color( 50, 50, 180 ), 0, 0 )

			I = I + rh + 5
			
		end
		
		-- Player Times
		local SessionTime = "Session Time: " .. string.FormattedTime( LocalPlayer():GetSessionTime(), "%2i:%02i:%02i" )
		local TotalTime = "Total Time: " .. string.FormattedTime( LocalPlayer():GetTotalTime(), "%2i:%02i:%02i" )
		
		local stFont = self:CalcFontSize( SessionTime, ( w / 2 ) - 80, 94 )
		local ttFont = self:CalcFontSize( TotalTime, ( w / 2 ) - 80, 94 )

		local stWidth = self:GetTextSize( SessionTime, stFont )
		local ttWidth = self:GetTextSize( TotalTime, ttFont )
		
		draw.SimpleText( SessionTime, stFont, ( w / 4 ) + 40, ( ( h / 2 ) + 60 ) - 40, Color( 50, 50, 180 ), 1, 0 )
		draw.SimpleText( TotalTime, stFont, ( w / 4 ) + ( w / 2 ) + 40, ( ( h / 2 ) + 60 ) - 40, Color( 50, 50, 180 ), 1, 0 )
		
		-- Server Time
		local time = os.date( "Today is %A the %d at %I:%M:%S %p" )
		local timeFont = self:CalcFontSize( time, w - 40, 128 )
		local tw, th = self:GetTextSize( time, timeFont )
		draw.SimpleText( time, timeFont, ( w / 2 ) + 20, ( h / 2 ) - th + 40, Color( 50, 50, 180 ), 1, 0 )
		
		--[[
		
		if self.NextPRefresh < CurTime() then
			self.NextPRefresh = CurTime() + 1
			self.Players = player.GetAll()
		end
		
		-- Player List
		draw.SimpleText( "PLAYERS: ", self.BigFont, x + 60, y + 1000, COLOR.BLUE, 0, 0 )
		
		local I = y + 1100
		local P = x + 90
		local MaxW = 0
		local TotalW = 0
		local SetTotal = false
		local Separators = {}
			
		for k,v in pairs( self.Players ) do
		
			if v and v:IsValid() then
		
				if I >= 680 then
					P = P + MaxW + 20
					table.insert( Separators, {X = P, H = I - 300} )
					
					P = P + 20
					I = y + 1100
					MaxW = 0
				end
				
				local w, h = self:GetTextSize( v:Nick(), self.SmallFont )
				
				local rank = v:GetRank()
				local color = PAC.GetRankColor( rank )
			
				draw.SimpleText( v:Nick(), self.SmallFont, P, I, color, 0, 0 )
				I = I + 70
				if w >= MaxW then MaxW = w end

				--TotalW = P + MaxW + 20
				
			end

		end
		
		--surface.SetDrawColor( 50, 50, 50, 200 )
		--surface.DrawRect( x + 70, y + 1080, TotalW, y + 1600 )
		
		surface.SetDrawColor( 255, 255, 255, 200 )
		for k,v in pairs( Separators ) do
		
			surface.DrawRect( v.X, y + 1100, 5, v.H )
			
		end
		
		-- Blog Stuff]]
		
		
	cam.End3D2D()
	
end

function ENT:GetTextSize( text, font )
	
	surface.SetFont( font )

	local w, h = surface.GetTextSize( text )
	local w = w
	local h = h

	return w, h
	
end

function ENT:Draw()

	
	
end
	
function ENT:GetWide()

	return self:OBBMaxs().y + ( self:OBBMins().y * -1 )
	
end