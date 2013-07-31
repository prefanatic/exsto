--[[
	Exsto
	Copyright (C) 2013  Prefanatic

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local anim = {}
	anim.__index = anim;

function exsto.CreateAnimation( panel, onUpdate, onFinished )
	local obj = {}
	setmetatable( obj, anim )
	
	obj.Panel = panel;
	obj.OnUpdate = onUpdate;
	obj.OnFinished = onFinished or function() end;
	
	obj:SetMultiplier( 2 )

	return obj
end

function anim:SetMultiplier( m ) self.Multiplier = m end

function anim:Run()
	if not self.Running then
		return
	end
	
	local delta = RealFrameTime() * ( ( self.To - self.Current ) / self.Multiplier ) * 40
	print( self.From, self.Current, self.To, delta )
	self.Current = self.Current + delta
	
	local percent = math.floor( self.Current / self.To )
	if percent == 1 or percent == 0 then
		self.Running = false
		self.OnFinished( self.Panel, self.Current )
		print( "Stopped" )
	end
	
	self.OnUpdate( self.Panel, self.Current )
end

function anim:Stop()
	self.Running = false
end

function anim:Start( from, to )
	if self.Running then -- Oh no.
		self.From = from
		self.To = to
		return
	end
	
	self.Running = true
	self.From = from
	self.To = to
	self.Current = from
	
end

exsto.Animations = {
	Handle = {};
	Styles = {};
	Override = false;
	Math = "smooth";
}

local function constructMeta( obj )
	
	-- Backup old functions
	obj._Old = {
		GetSize = obj.GetSize;
		SetSize = obj.SetSize;
		SetTall = obj.SetTall;
		SetWide = obj.SetWide;
		GetPos = obj.GetPos;
		SetPos = obj.SetPos;
		Close = obj.Close;
		IsVisible = obj.IsVisible;
		SetVisible = obj.SetVisible;
		SetAlpha = obj.SetAlpha;
	}
	
	-- Sizing
	
	obj.GetSize = function( o )
		return o:GetAnimSizeCurW(), o:GetAnimSizeCurH()
	end
	
	obj.GetSeriousSize = function( o )
		return o:GetAnimSizeProgW(), o:GetAnimSizeProgH()
	end
	
	obj.SetSize = function( o, w, h )
		o:SetAnimSizeProgW( w or 0 );
		o:SetAnimSizeProgH( h or 0 );
	end
	
	obj.SetTall = function( o, h )
		--print( "Setting tall ", h )
		o:SetAnimSizeProgH( h or 0 );
	end
	
	obj.SetWide = function( o, w )
		o:SetAnimSizeProgW( w or 0 )
	end
	
	obj.ForceSize = function( o, w, h )
		o:SetSize( w, h )
		o:SetAnimationSize( w, h )
	end		
	
	obj.SetAnimationSizeW = function( o, w )
		o:SetAnimSizeCurW( w or 0 );
		o._Old.SetSize( o, w, o:GetAnimSizeCurH() )
	end
	
	obj.SetAnimationSizeH = function( o, h )
		o:SetAnimSizeCurH( h or 0 );
		--print( "updating animation size", h )
		o._Old.SetSize( o, o:GetAnimSizeCurW(), h )
	end
	
	obj.SetAnimationSize = function( o, w, h )
		o:SetAnimationSizeW( w )
		o:SetAnimationSizeH( h )
	end
	
	obj.GetAnimSizeProgW = function( o ) return o:GetAnimationData()[2][1][2] end
	obj.SetAnimSizeProgW = function( o, w ) o:GetAnimationData()[2][1][2] = w end
	
	obj.GetAnimSizeProgH = function( o ) return o:GetAnimationData()[2][2][2] end
	obj.SetAnimSizeProgH = function( o, h ) o:GetAnimationData()[2][2][2] = h end
	
	obj.GetAnimSizeCurW = function( o ) return o:GetAnimationData()[2][1][1] end
	obj.SetAnimSizeCurW = function( o, w ) o:GetAnimationData()[2][1][1] = w end
	
	obj.GetAnimSizeCurH = function( o ) return o:GetAnimationData()[2][2][1] end
	obj.SetAnimSizeCurH = function( o, h ) o:GetAnimationData()[2][2][1] = h end
	
	-- Positioning
	
	obj.GetPos = function( o )
		return o:GetAnimPosCurX(), o:GetAnimPosCurY()
	end
	
	obj.GetSeriousPos = function( o )
		return o:GetAnimPosProgX(), o:GetAnimPosProgY()
	end
	
	obj.SetPos = function( o, x, y )
		o:SetAnimPosProgX( x or 0 );
		o:SetAnimPosProgY( y or 0 );
	end
	
	obj.ForcePos = function( o, x, y )
		o:SetPos( x, y )
		o:SetAnimationPos( x, y )
	end		
	
	obj.SetAnimationPosX = function( o, x )
		o:SetAnimPosCurX( x or 0 );
		o._Old.SetPos( o, x, o:GetAnimPosCurY() )
	end
	
	obj.SetAnimationPosY = function( o, y )
		o:SetAnimPosCurY( y or 0 );
		o._Old.SetPos( o, o:GetAnimPosCurX(), y )
	end
	
	obj.SetAnimationPos = function( o, x, y )
		o:SetAnimationPosX( x )
		o:SetAnimationPosY( y )
	end
	
	obj.GetAnimPosProgX = function( o ) return o:GetAnimationData()[1][1][2] end
	obj.SetAnimPosProgX = function( o, x ) o:GetAnimationData()[1][1][2] = x end
	
	obj.GetAnimPosProgY = function( o ) return o:GetAnimationData()[1][2][2] end
	obj.SetAnimPosProgY = function( o, y ) o:GetAnimationData()[1][2][2] = y end
	
	obj.GetAnimPosCurX = function( o ) return o:GetAnimationData()[1][1][1] end
	obj.SetAnimPosCurX = function( o, x ) o:GetAnimationData()[1][1][1] = x end
	
	obj.GetAnimPosCurY = function( o ) return o:GetAnimationData()[1][2][1] end
	obj.SetAnimPosCurY = function( o, y ) o:GetAnimationData()[1][2][1] = y end
	
	
	--Alpha
	
	obj.GetAlpha = function( o )
		return o:GetAnimationData()[3][1][1]
	end
	
	obj.SetAlpha = function( o, val )
		o:GetAnimationData()[3][1][2] = val
	end
	
	obj.SetAnimationAlpha = function( o, a )
		o:GetAnimationData()[3][1][1] = a or 0;
		o._Old.SetAlpha( o, a )
	end
	
	-- Closing
	
	obj.SetAnimationClose = function( o, enum )
		o._AnimClose = enum
		
		if enum == ANIM_BLIND_UP then
			o:GetAnimationData()[2].OnComplete = function( val )
				--print( "ANIMATION COMPLETE", val )
				--o:SetVisible( false )
			end
		end
	end
	
	obj.GetAnimationClose = function( o )
		return o._AnimClose
	end
	
	obj.SetVisible = function( o, val )
		if val then
			o:GetAnimationData()[3][1][1] = 10
			o._Old.SetAlpha( o, 10 )
			o._Old.SetVisible( o, val )
		end
		o:GetAnimationData()[3][1][2] = ( val and 255 or 0 )
	end
	
	obj.IsVisible = function( o )
		return o:GetAnimationData()[3][1][1] > 0;
	end
	
	-- Misc
	
	obj.ForceAnimationRefresh = function( o )
		o.__ANIMFORCE = true
	end
	
	obj.GetAnimationTable = function( o )
		return exsto.Animations.Handle[ o.__ANIMID ]
	end
	
	obj.SetAnimationSupport = function( o, tbl )
		o.__ANIMDATA = tbl
	end
	
	obj.GetAnimationData = function( o )
		return o:GetAnimationTable().__ANIMDATA
	end
	
	obj.GetAnimationDelta = function( o, a, b, c )
		return RealFrameTime() * ( ( b - a ) / o:GetAnimationMul( c )  ) * 40
	end
	
	obj.SetAnimationMul = function( o, mul )
		o.__ANIMMUL = mul
	end
	
	obj.GetAnimationMul = function( o, c )
		if c == 3 then return o.__ANIMFADEMUL end
		return o.__ANIMMUL
	end
	
	obj.SetAnimFadeMul = function( o, mul )
		o.__ANIMFADEMUL = mul
	end
	
	obj.GetAnimFadeMul = function( o ) return o.__ANIMFADEMUL end

end

function exsto.Animations.Create( obj )

	-- Insert him into our handle.
	local id = table.insert( exsto.Animations.Handle, obj )
	obj.__ANIMID = id;
	
	-- Create our animation support table.
	local x, y = obj:GetPos()
	local w, h = obj:GetSize()
	local a = obj:GetAlpha()
	
	-- Construct meta helpers.
	constructMeta( obj )
	
	obj:SetAnimationSupport( {
		
		-- Position
		{
			{ x, x, OnUpdate = function( val ) obj:SetAnimationPosX( val ) end };
			{ y, y, OnUpdate = function( val ) obj:SetAnimationPosY( val ) end };
			OnComplete = function()  end;
		};
		
		-- Size
		{
			{ w, w, OnUpdate = function( val )  obj:SetAnimationSizeW( val ) end };
			{ h, h, OnUpdate = function( val )  obj:SetAnimationSizeH( val ) end };
			OnComplete = function()  end;
		};
		
		-- Alpha
		{
			{ a, a, OnUpdate = function( val ) obj:SetAnimationAlpha( math.Clamp( val, 0, 255 ) ) end };
			OnComplete = function( val )
				obj._Old.SetVisible( obj, ( val > 200 ) and true or false )
			end;
		};
	} )
	
	obj:SetAnimationMul( 2 )
	obj:SetAnimFadeMul( 1 )
	
	--[[
		I AM DOING THIS BECAUSE FOR SOME REASON OBJECTS SEEM TO KILL THEMSELVES OVER TIME, AND IT ERRORS OUT EVERYTHING IF NOT DONE ON AN INDIVIDUAL OBJECT LEVEL.
		ALL IN ALL, I HAVE NO IDEA WHY.  deal with it
	]]
	
	local FUCK = obj.Think or function() end
	obj.Think = function( obj )
		-- Loop through our supported animation styles.
		for style, content in ipairs( obj:GetAnimationData() ) do
			
			-- Go through the values that need changing.
			for _, segment in ipairs( content ) do
				if ( ( math.abs( segment[ 1 ] / segment[ 2 ] ) == ( 1 or 0 ) ) or ( math.floor( segment[ 1 ] + 0.5 ) == math.floor( segment[ 2 ] + 0.5 ) ) ) and !content._COMPLETED then
					content.OnComplete( segment[ 1 ] )
					content._COMPLETED = true
				elseif math.floor( segment[ 1 ] + 0.5 ) != math.floor( segment[ 2 ] + 0.5 ) then
					content._COMPLETED = false

					segment.OnUpdate( segment[ 1 ] + obj:GetAnimationDelta( segment[ 1 ], segment[ 2 ], style ) )
				end
			end
		end
		FUCK( obj )
	end
	
end

-- TODO: DBug states this holds 10% of computational power.  Most likely due to the fact that it CONSTANTLY sets the object's position no matter what.
-- As in, the delta makes it only approach the position it needs to go to, not reach it.
function exsto.Animations.Think()
	
	-- Loop through our handled objects.
	for _, obj in ipairs( exsto.Animations.Handle ) do
		-- Make sure they're valid first.
		if IsValid( obj ) and obj:IsVisible() and obj:GetAnimationData() then
			
			-- Loop through our supported animation styles.
			for style, content in ipairs( obj:GetAnimationData() ) do
				
				-- Go through the values that need changing.
				for _, segment in ipairs( content ) do
					if ( ( math.abs( segment[ 1 ] / segment[ 2 ] ) == ( 1 or 0 ) ) or ( math.floor( segment[ 1 ] + 0.5 ) == math.floor( segment[ 2 ] + 0.5 ) ) ) and !content._COMPLETED then
						content.OnComplete( segment[ 1 ] )
						content._COMPLETED = true
					elseif math.floor( segment[ 1 ] + 0.5 ) != math.floor( segment[ 2 ] + 0.5 ) then
						content._COMPLETED = false

						segment.OnUpdate( segment[ 1 ] + obj:GetAnimationDelta( segment[ 1 ], segment[ 2 ], style ) )
					end
				end
			end

		else
			-- Remove invalid.
			exsto.Debug( "Animations --> Invalid object caught in animation table.", 1 )
			
			
			obj:Remove()
			exsto.Animations.Handle[ _ ] = nil
		end
	end
	
end
--hook.Add( "Think", "ExAnimationThink", exsto.Animations.Think )

local function storeOldFunctions( obj )
	local getPos = obj.GetPos
	local setPos = obj.SetPos
	local setAlpha = obj.SetAlpha
	local setVisible = obj.SetVisible
	
	obj.OldFuncs = {
		GetPos = getPos;
		SetPos = setPos; 
		SetX = function( obj, x ) obj.OldFuncs.SetPos( obj, x, obj.Anims[ 2 ].Last or obj.OldFuncs.GetPos[2] or 0 ) end;
		SetY = function( obj, y ) obj.OldFuncs.SetPos( obj, obj.Anims[ 1 ].Last or obj.OldFuncs.GetPos[1] or 0, y ) end;
		
		SetVisible = setVisible;
		SetAlpha = function( obj, alpha ) 
			setAlpha( obj, alpha ) 
			setVisible( obj, alpha >= 5 ) 
		end;
	
		SetColor = function( obj, color ) obj.m_bgColor = color end;
		SetRed = function( obj, red ) obj.m_bgColor.r = red end;
		SetGreen = function( obj, green ) obj.m_bgColor.g = green end;
		SetBlue = function( obj, blue ) obj.m_bgColor.b = blue end;
		SetAlphaBG = function( obj, alpha ) obj.m_bgColor.a = alpha end;
	}
end

local function buildAnimTable( obj )
	local x, y = obj:GetPos()
	obj.Anims[ 1 ] = {
		Current = x,
		Last = x,
		Mul = 2,
		Call = "SetX",
	}
	
	obj.Anims[ 2 ] = {
		Current = y,
		Last = y,
		Mul = 2,
		Call = "SetY",
	}

	-- Alpha.
	obj.Anims[ 3 ] = {
		Current = 255,
		Last = 255,
		Mul = 4,
		Call = "SetAlpha"
	}
	
	local col = obj.m_bgColor
	if col then
		-- Color Object
		obj.Anims[ 4 ] = {
			Current = col.r,
			Last = col.r,
			Mul = 4,
			Call = "SetRed"
		}
		obj.Anims[ 5 ] = {
			Current = col.g,
			Last = col.g,
			Mul = 4,
			Call = "SetGreen"
		}
		obj.Anims[ 6 ] = {
			Current = col.b,
			Last = col.b,
			Mul = 4,
			Call = "SetBlue"
		}
		obj.Anims[ 7 ] = {
			Current = col.a,
			Last = col.a,
			Mul = 4,
			Call = "SetAlphaBG"
		}
	end
end

local function createOverrides( obj )
	-- General
	obj.SetPosMul = function( obj, mul )
		obj.Anims[1].Mul = mul
		obj.Anims[2].Mul = mul
	end
	
	obj.SetFadeMul = function( obj, mul ) obj.Anims[3].Mul = mul end
	
	obj.SetColorMul = function( obj, mul )
		for I = 4, 7 do
			obj.Anims[ I ].Mul = mul
		end
	end
	
	obj.DisableAnims = function( obj ) self.Anims.Disabled = true end
	obj.EnableAnims = function( obj ) self.Anims.Disabled = false end
	
	-- Positions
	obj.GetPos = function( obj, bool )
		local x = !bool and ( obj.Anims[ 1 ].Last or 0 ) or ( obj.Anims[ 1 ].Current or 0 )
		local y = !bool and ( obj.Anims[ 2 ].Last or 0 ) or ( obj.Anims[ 2 ].Current or 0 )
		return x, y
	end
	obj.SetPos = function( obj, x, y ) 
		obj.Anims[1].Current = x
		obj.Anims[2].Current = y 
	end
	
	-- Fading
	obj.FadeOnVisible = function( obj, bool ) obj.fadeOnVisible = bool end
	obj.SetFadeMul = function( obj, mul ) obj.Anims[3].Mul = mul end
	
	obj.SetAlpha = function( obj, alpha ) obj.Anims[3].Current = alpha end
	
	obj.SetVisible = function( obj, bool )
		if obj.fadeOnVisible then
			if bool == true then
				obj.SetAlpha( obj, 255 )
				obj.Anims[3].Last = 10
				obj.OldFuncs.SetAlpha( obj, 10 )
			else
				obj.SetAlpha( obj, 0 )
			end
		else
			obj.OldFuncs.SetVisible( obj, bool )
		end
	end
	
	-- Color
	obj.SetColor = function( obj, col )
		obj:SetRed( col.r )
		obj:SetGreen( col.g )
		obj:SetBlue( col.b )
		obj:SetAlpha2( col.a )
	end
	
	obj.SetRed = function( obj, r ) obj.Anims[4].Current = r end
	obj.SetGreen = function( obj, g ) obj.Anims[5].Current = g end
	obj.SetBlue = function( obj, b ) obj.Anims[6].Current = b end
	obj.SetAlpha2 = function( obj, a ) obj.Anims[7].Current = a end
	
end

function exsto.Animations.CreateAnimation( obj )
	obj.Anims = {}
	
	storeOldFunctions( obj )
	buildAnimTable( obj )
	createOverrides( obj )
	
	local think, dist, speed = obj.Think
	obj.Think = function( self )
		if think then think( self ) end
		
		for _, data in ipairs( self.Anims ) do
			if math.Round( data.Last ) != math.Round( data.Current ) then
				if self.Anims.Disabled then
					data.Last = data.Current
					data.Call( self, self.Anims[ _ ].Last )
				else
					dist = data.Current - data.Last
					speed = RealFrameTime() * ( dist / data.Mul  ) * 40

					self.Anims[ _ ].Last = math.Approach( data.Last, data.Current, speed )
					if self.OldFuncs[ data.Call ] then
						self.OldFuncs[ data.Call ]( self, self.Anims[ _ ].Last )
					else
						Error( "ExDerma --> Unknown animation callback '" .. tostring( data.Call ) .. "'" )
					end
				end
			end
		end
	end
	
end