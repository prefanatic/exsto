include( "shared.lua" )

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local fontTbl = {
	font = "Arial",
	size = 0,
	weight = 100,
}
for I = 18, 144 do
	fontTbl.size = I;
	surface.CreateFont( "Ex3DText" .. I, fontTbl );
end

function ENT:Initialize()

	self:SetModel( "" )
	self.TextColor = Color( 255, 255, 255, 255 )
	self.OutlineColor = Color( 0, 0, 0, 255 )
	self.Font = "Ex3DText144"
	self.Text = ""
	
	self.NegX = 0
	self.PosY = 0
	self.TextW = 0
	self.TextH = 0
	
	self.Fade = 0
	self.Faded = true
	
	self:DrawShadow( false )
	
end

function ENT:GetTextSize( text, font )
	surface.SetFont( font )
	local w, h = surface.GetTextSize( text )
	return w, h
end

function ENT:CalcFontSize( text, maxWidth )
	local fnt = 144
	for i = 18, 144 do 
		local w = self:GetTextSize( text, "Ex3DText"..i )
		if w > maxWidth then
			fnt = math.Round( i - 3 ) 
			break 
		end
	end
	return fnt
end

function ENT:OnTextChanged( text )
	self.Font = "Ex3DText" .. math.Clamp( self:CalcFontSize( text, self:GetNWInt( "wide" ) ) / self:GetNWInt( "scale" ), 28, 144 ) - 10
	
	surface.SetFont( self.Font )
	
	local w, h = surface.GetTextSize( text )
	self.NegX = -w / 2
	self.PosY = -h
	self.TextW = w
	self.TextH = h
	
	self:SetRenderBounds( Vector( 0, self.NegX, 0 ), Vector( 0, -self.NegX, h ) )
end

local dist
function ENT:Think()
	if self.Text != self:GetNWString( "Text" ) then
		self.Text = self:GetNWString( "Text" )
		self:OnTextChanged( self.Text )
	end
	
	dist = LocalPlayer():GetPos():Distance( self:GetPos() )
	
	if dist >= 200 and !self.Faded then
		self.Fade = self.Fade - FrameTime() * 70
		if self.Fade <= 0 then self.Fade = 0 self.Faded = true end
	elseif dist <= 200 and self.Faded then
		self.Fade = self.Fade + FrameTime() * 70
		if self.Fade >= 255 then self.Fade = 255 self.Faded = false end
	end

end

function ENT:ColorAlpha( col, alpha )
	col.a = alpha
	return col
end

local ang, pos
function ENT:DrawTranslucent()

	if self.Fade <= 0 then return false end
	
	ang = self:GetAngles()
	pos = self:GetPos() + ang:Up() * math.sin( CurTime() ) * 2
	
	ang:RotateAroundAxis( ang:Forward(), 90 )
	ang:RotateAroundAxis( ang:Right(), 90 )
	
	if (LocalPlayer():EyePos() - pos):DotProduct( ang:Up() ) < 0 then
		ang:RotateAroundAxis( ang:Right(), 180 )
	end
	
	cam.Start3D2D( pos, ang, self:GetNWInt( "scale" ) )
		draw.SimpleTextOutlined( self.Text, self.Font, self.NegX, self.PosY, self:ColorAlpha( self.TextColor, self.Fade ), 0, 0, 1, self:ColorAlpha( self.OutlineColor, self.Fade ) )
	cam.End3D2D()
	
	-- TODO: make it on the other side too.

end

	