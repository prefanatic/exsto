
include( 'shared.lua' )

ENT.Font = "Grave_Font"
ENT.FakeFont = "Fake_GraveFont"

surface.CreateFont( ENT.Font, {
	font = "coolvetica",
	size = 128,
	weight = 400,
} )

surface.CreateFont( ENT.FakeFont, {
	font = "coolvetica",
	size = 128 / 4,
	weight = 400,
} )

function ENT:Initialize()

	local min = self:OBBMins()
	local max = self:OBBMaxs()

	self.X = -200
	self.Y = -50
	print( self.X, self.Y )
	
	self.Text = ""
	
	self.Lines = {}
	self.Width = 200
	print( self.Width, min.y, max.y, min.x, max.x )
	
	self:SetText( "This is a test of the text on the grave function." )
	
	--self.Width = ( min.x * -1 ) + max.x 
	
end

function ENT:SetText( text )

	surface.SetFont( self.FakeFont )
	
	local w, h = surface.GetTextSize( text )
	
	print( "Width is " .. w )
	
	local ntext = text
	
	if w >= self.Width then
	
		ntext = ""
	
		print( "We reached our width limit, parse string." )
		
		local stringlen = 0
	
		print( "Current text is " .. text )
		local words = string.Explode( " ", text )
		
		PrintTable( words )
		
		for I = 1, #words do
		
			if stringlen >= self.Width then
			
				print( "Put a new line once we hit the max." )
			
				stringlen = 0
				ntext = ntext .. "-"
				
			end
		
			ntext = ntext .. words[I] .. " "
			
			local w, h = surface.GetTextSize( words[I] )
			
			stringlen = stringlen + w
			print( stringlen )
			
		end
		
	end
	
	-- Lets set up the formatted table
	
	if w > self.Width then
	
		local nl_sep = string.Explode( "-", ntext )
		
		self.Lines = nl_sep
		
	end
	
end

function ENT:DrawBackPanel()

	surface.SetDrawColor( 0, 0, 0, 100 )
	surface.DrawRect( self.MinX, self.MaxY, self.Width, self.Height )
	
	surface.SetDrawColor( 255, 255, 255, 100 )
	surface.DrawOutlinedRect( self.MinX, self.MaxY, self.Width, self.Height )
	
end

function ENT:DrawDeadText( pos, ang, size )

	cam.Start3D2D( pos, ang, size )
	
		self:DrawBackPanel()
		
	cam.End3D2D()
	
end

function ENT:Draw()

	self.Entity:DrawModel() -- Draw the model, or it would be INVISIBLE!
	
	local pos = self.Entity:GetPos()
	local ang = self.Entity:GetAngles()
	
	ang:RotateAroundAxis( ang:Forward(), 90 )
	ang:RotateAroundAxis( ang:Right(), 90 )
	
	local curY = self.Y
	
	self:DrawDeadText( pos - ( self:GetForward() * 5 ), ang, 0.05 )
	
	--[[cam.Start3D2D( pos - ( self:GetForward() * 5 ) , ang, 0.05 )
		
		for I = 1, #self.Lines do
		
			surface.SetFont( self.Font )
			surface.SetTextColor( 255, 255, 255, 255 )
		
			local text = self.Lines[I]
			
			--print( "Drawing " .. text )
			
			surface.SetTextPos( self.X, curY )
			surface.DrawText( text )
			
			surface.SetFont( self.FakeFont )
			local w, h = surface.GetTextSize( text )
			curY = curY + h + 2
			
		end
		
	cam.End3D2D()]]
	
end