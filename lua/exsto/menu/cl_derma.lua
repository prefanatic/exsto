--[[
	Exsto
	Copyright (C) 2010  Prefanatic

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


-- Derma Utilities
exsto.Textures = {
	GradDown = surface.GetTextureID( "gui/gradient_down" );
	CloudActivated = surface.GetTextureID( "exsto/greentick" );
	CloudVerified = surface.GetTextureID( "exsto/tick" );
	CloudNotVerified = surface.GetTextureID( "exsto/ohnoes" );
	CloudDownloading = surface.GetTextureID( "exsto/downloading" );
	CloudDeleting = surface.GetTextureID( "exsto/downloading" );
	CloudFail = surface.GetTextureID( "exsto/fail" );
	Refresh = surface.GetTextureID( "exsto/refresh" );
	BackHighlight = surface.GetTextureID( "exsto/back_highlight" );
	BackNorm = surface.GetTextureID( "exsto/back_norm" );
	QuickLogo = surface.GetTextureID( "exsto/exlogo_qmenu" );
}

-- ################# Time saving DERMA functions @ Prefanatic
function exsto.WordWrap( text, maxW, fnt ) 
	surface.SetFont( fnt )
	local exp = string.Explode( " ", text )
	local tblBuffer, curW, curI = {}, 0, 1
	
	tblBuffer[ 1 ] = ""

	for _, word in ipairs( exp ) do
		if word == "\n" then
			curW = 0
			curI = curI + 1
			
			tblBuffer[ curI ] = ""
		end
		
		local wordW = surface.GetTextSize( word )
		if curW + wordW + 4 >= maxW then
			curW = 0
			curI = curI + 1

			tblBuffer[ curI ] = word
		else
			curW = curW + wordW + 4
			
			tblBuffer[ curI ] = tblBuffer[ curI ] .. " " .. word
		end
	end
	return tblBuffer
end

function exsto.CreateLabel( x, y, text, font, parent )

	local label = vgui.Create("DLabel", parent)
		label:SetText( text )
		label:SetFont( font )
		label:SizeToContents()

		if x == "center" then x = (parent:GetWide() / 2) - (label:GetWide() / 2) end
		label:SetPos( x, y )
		label:SetVisible(true)
		label:SetTextColor( Color( 99, 99, 99, 255 ) )

	return label

end	
	
function exsto.CreatePanel( x, y, w, h, color, parent )

	local panel = vgui.Create("DPanel", parent)
		panel:SetSize( w, h )
		panel:SetPos( x, y )
		--panel.m_bBackground = false
		panel.m_bgColor = color
		
		panel.Gradient = function( self, grad )
			if grad then
				self.GradientHigh = Color( 236, 236, 236, 255 )
				self.GradientLow = Color( 249, 249, 249, 255 )
				self.GradientBorder = Color( 124, 124, 124, 255 )
			end
			self.ShouldGradient = grad	
		end
		
		panel.bgColor = color
		
	return panel

end

function exsto.CreateColorMixer( x, y, w, h, defaultColor, parent )
	local mixer = vgui.Create( "DColorMixer", parent )
		mixer:SetSize( w, h )
		mixer:SetPos( x, y )
		mixer:SetPalette( false )
		
		mixer.niceColor = defaultColor
		mixer:SetColor( defaultColor )
		mixer.HSV:UpdateColor()
		
	return mixer
end

function exsto.CreateTextEntry( x, y, w, h, parent )

	local tentry = vgui.Create( "DTextEntry", parent )
	
	tentry:SetSize( w, h )
	tentry:SetAllowNonAsciiCharacters( true )
	
	if x == "center" then x = (parent:GetWide() / 2) - (tentry:GetWide() / 2) end
	tentry:SetPos( x, y )
	
	return tentry

end

function exsto.CreateMultiChoice( x, y, w, h, parent )

	local panel = vgui.Create( "DComboBox", parent )
	
	panel:SetSize( w, h )
	panel:SetPos( x, y )
	
	return panel
	
end

function exsto.CreateFrame( x, y, w, h, title, showclose, borderfill )

	local frame = vgui.Create( "DFrame" )
	
		frame:SetPos( x, y )
		frame:SetSize( w, h )
		frame:SetVisible( true )
		frame:SetTitle( "" )
		frame:SetDraggable( true )
		frame:SetBackgroundBlur( false )
		frame:ShowCloseButton( true )
		
		frame.GradientHigh = Color( 236, 236, 236, 255 )
		frame.GradientLow = Color( 249, 249, 249, 255 )
		frame.GradientBorder = Color( 124, 124, 124, 255 )
		
		frame:MakePopup()

	return frame
	
end

function exsto.CreateComboBox( x, y, w, h, parent ) -- Changed to DListView because of Garry being homosexual.  Changing fucking API god damnit.
	local box = vgui.Create( "DListView", parent )
		box:SetPos( x, y )
		box:SetSize( w, h )

		local old = box.AddLine
		--[[box.AddLine = function( self, ... )
			local obj = old( self, ... )
				obj.OnCursorEntered = function( self ) self.Hovered = true end
				obj.OnCursorExited = function( self ) self.Hovered = false end
				obj.Columns[1]:SetFont( "ExGenericTextNoBold15" )
			return obj
		end]]
		box.AddChoice = box.AddLine
		box.AddItem = box.AddLine

		--[[box.GetSelectedLine = function( self )
			if self:GetSelectedLine() and self:GetSelectedLine()[1] then
				return self:GetSelectedLine()[1]:GetValue()
			end
		end]]
		box.GetSelectedItem = box.GetSelectedLine
		
		box.SelectByName = function( self, data )
			for id, line in pairs( self.Lines ) do
				if line:GetValue() == data then
					self:ClearSelection()
					line:SetSelected( true ) break 
				end
			end
		end
		
		local addcolumn = box.AddColumn
		box.AddColumn = function( lv, name, mat, pos )
			local obj = addcolumn( lv, name, mat, pos )
				obj.Header._DLISTCOLUMN = true
				obj.Header:SetFont( "ExGenericTextNoBold14" )
				
			return obj
		end
		
		
	return box
end

function exsto.CreateImage( x, y, w, h, img, parent )
	local image = vgui.Create( "DImage", parent )
		image:SetSize( w, h )
		image:SetPos( x, y )
		image:SetImage( img )
	return image
end

function exsto.CreateImageButton( x, y, w, h, img, parent )
	local image = vgui.Create( "DImageButton", parent )
		image:SetSize( w, h )
		image:SetPos( x, y )
		image:SetImage( img )
	return image
end

function exsto.CreateButton( x, y, w, h, text, parent )

	local button = vgui.Create("DButton", parent)
	
		button:SetText( text )
		button:SetSize( w, h )
		button:SetFont( "ExGenericTextNoBold14" )
		
		if x == "center" then x = (parent:GetWide() / 2) - (button:GetWide() / 2) end
		button:SetPos( x, y )
		
		button.GetStyle = function( self )
			return self.mStyle
		end
		
		button.Flash = function( self )
			self.Flashing = true
			self.FlashAlpha = 255
			self.BeginFlash = CurTime()
		end
		
		button.SetStyle = function( self, style )
			self.mStyle = style
			if style == "secondary" then
				button.GradientHigh = Color( 229, 229, 299, 255 )
				button.GradientLow = Color( 222, 222, 222, 222 )
				button.BorderColor = Color( 191, 191, 191, 255 )
				button.Rounded = 0
				
				button.HoveredGradHigh = Color( 237, 237, 237, 255 )
				button.HoveredGradLow = Color( 226, 226, 226, 255 )
				
				button.SelectedBorder = Color( 0, 194, 14, 255 )
				
				button.TextColor = Color( 64, 64, 64, 255 )
				button.Font = "exstoSecondaryButtons"
				return 
			end
			
			if style == "neutral" then
				button.TextColor = Color( 0, 153, 176, 255 )
			elseif style == "negative" then
				button.TextColor = Color( 176, 0, 0, 255 )
			elseif style == "positive" then
				button.TextColor = Color( 12, 176, 0, 255 )
			end
			
			button.BorderColor = Color( 194, 194, 194, 255 )
			button.SelectedBorder = button.BorderColor
			button.GradientHigh = Color( 255, 255, 255, 255 )
			button.GradientLow = Color( 236, 236, 236, 255 )
			button.Rounded = 4
			button.Font = "exstoButtons"
		end
		
		button:SetStyle( "neutral" )
		
		button.DoClick = function( self )
			print( "FLASHING GO!" )
			self:Flash()
			if type( self.OnClick ) == "function" then
				self:OnClick()
			end
		end

	return button
	
end

function exsto.CreateSysButton( x, y, w, h, type, parent )

	local button = vgui.Create( "DSysButton", parent )
	
		button:SetSize( w, h )
		button:SetPos( x, y )
		button:SetType( type )
		
	return button
	
end

function exsto.CreateListView( x, y, w, h, parent )
	
	local lview = vgui.Create("DListView", parent)
	
		lview:SetSize( w, h )
		
		if posx == "center" then posx = (parent:GetWide() / 2) - (lview:GetWide() / 2) end
		lview:SetPos( x, y )
		lview:SetMultiSelect( false )
		
		local addcolumn = lview.AddColumn
		lview.AddColumn = function( lv, name, mat, pos )
			local obj = addcolumn( lv, name, mat, pos )
				obj.Header._DLISTCOLUMN = true
				obj.Header:SetFont( "ExGenericTextNoBold14" )
			return obj
		end
		
		-- Hack.  I hate it more than you do.
		local function lthink( l )
			if l.Hovered and !l._HThinked then l.Columns[1]:SetTextColor( Color( 0, 180, 255, 255 ) ) l._HThinked = true end
			if !l.Hovered and l._HThinked then l.Columns[1]:SetTextColor( Color( 72, 72, 72, 255 ) ) l._HThinked = false end
			return l._OLDTHINK or nil
		end
		
		local addline = lview.AddLine
		lview.AddLine = function( lv, ... )
			local l = addline( lv, ... )
				l._OLDTHINK = l.Think
				l.Think = lthink
			return l
		end
		
	return lview
	
end

function exsto.CreateCheckBox( x, y, text, convar, value, parent )

	local cbox = vgui.Create("DCheckBoxLabel", parent)
	
		cbox:SetPos( x, y )
		cbox:SetText( text )
		cbox:SetConVar( convar )
		cbox:SetValue( value )
		cbox:SizeToContents()
	
	return cbox
	
end

function exsto.CreateNumberWang( x, y, w, h, value, max, min, parent )
	local wang = vgui.Create( "DNumberWang", parent )
		wang:SetPos( x, y )
		wang:SetSize( w, h )
		wang:SetMinMax( min, max )
		wang:SetValue( value )
	return wang
end

function exsto.CreateNumSlider( x, y, w, text, min, max, decimals, panel )

	local panel = vgui.Create( "DNumSlider", panel )
		
		panel:SetPos( x, y )
		panel:SetWide( w )
		panel:SetText( text )
		panel:SetMin( min )
		panel:SetMax( max )
		panel:SetDecimals( decimals )
		
	return panel
	
end

local function animationAdd( panel )
	print( "dmoajsdf" )
	Menu:CreateAnimation( panel )
	PrintTable( panel.Anims )
	print( "medic." )
end

function exsto.CreatePanelList( x, y, w, h, space, horiz, vscroll, parent )
	local list = vgui.Create( "DPanelList", parent )
		list:SetPos( x, y )
		list:SetSize( w, h )
		list:SetSpacing( space )
		list:EnableHorizontal( horiz )
		--list:EnableVerticalScrollbar( vscroll )
		
		list.contentWidth = 0
		list.contentHeight = 0
		local oldAddItem = list.AddItem
		list.AddItem = function( self, panel, ... )
			oldAddItem( self, panel, ... )
			panel:SetSkin( "ExstoTheme" )
			
			if self._ExAnims == true then
				timer.Simple( 0.01, animationAdd, panel )
				//panel:SetPos( panel:GetWide() * -1, 0 )
				
				//panel:SetPosMul( 3 )
				
				//list:InvalidateLayout()
			end
		end
		
		list.EnableAnimations = function( self, bool )
			self._ExAnims = bool
		end
		
	return list
end

function exsto.CreateCollapseCategory( x, y, w, h, label, parent )
	
	local category = vgui.Create( "DCollapsibleCategory", parent )
		category:SetPos( x, y )
		category:SetSize( w, h )
		category:SetExpanded( false )
		category:SetLabel( label )

	return category
	
end

function exsto.CreateModelPanel( x, y, w, h, model, parent )
	local panel = vgui.Create( "DModelPanel", parent )
		panel:SetPos( x, y )
		panel:SetWide( w, h )
		panel:SetModel( model )
	return panel
end

function exsto.CreateLabeledPanel( x, y, w, h, label, color, parent )
	local panel = exsto.CreatePanel( x, y, w, h, color, parent )
	panel.Label = exsto.CreateLabel( x + 5, y - 10, label, "default", parent )
	
	local oldApplyScheme = panel.Label.ApplySchemeSettings
	panel.Label.ApplySchemeSettings = function( self )
		oldApplyScheme( self )
		
		local x, y = panel:GetPos()
		local w, h = self:GetSize()
		
		self:SizeToContents()
		self:SetPos( x + 5, y - ( h / 2 ) + .5 )
	end
	
	//panel:NoClipping( true )
	panel.Label:SetTextColor( Color( 93, 93, 93, 255  ) )
	
	panel.Paint = function( panel )
		draw.RoundedBox( 6, 0, 0, panel:GetWide(), panel:GetTall(), color )
	end
	
	return panel
end

--[[local oldCreate = vgui.Create

function vgui.Create( class, parent, name, ... )
	local panel = oldCreate( class, parent, name, ... )
	
	if panel and parent then
		parent.children = parent.children or {}
		table.insert( parent.children, panel )
	end
	
	return panel
end]]

--[[
********** Thank you Overv for the following code.  All credit goes to you, with some modifications by me. **********
]]

local function rect( x, y, w, h, u1, v1, u2, v2 )
	return {
		{ x = x, y = y, u = u1, v = v1 },
		{ x = x + w, y = y, u = u2, v = v1 },
		{ x = x + w, y = y + h, u = u2, v = v2 },
		
		{ x = x + w, y = y + h, u = u2, v = v2 },
		{ x = x, y = y + h, u = u1, v = v2 },
		{ x = x, y = y, u = u1, v = v1 }
	}
end

local function circle( cx, cy, r, segments, min, max, u1, v1, u2, v2 )
	local a, b, c, d
	local delta = math.pi*2/segments
	local vertices = {}
	
	local hdu = (u2-u1)/2
	local hdv = (v2-v1)/2
	local cu = u1 + hdu
	local cv = v1 + hdv
	
	for ang = min or 0, ( max or math.pi*2 ) - delta*0.9, delta do
		a = cx + math.cos( ang ) * r
		b = cy + math.sin( ang ) * r
		c = cx + math.cos( ang + delta ) * r
		d = cy + math.sin( ang + delta ) * r
		
		table.Add( vertices, {
			{ x = cx, y = cy, u = cu, v = cv },
			{ x = a, y = b, u = cu + math.cos( ang ) * hdu, v = cv + math.sin( ang ) * hdv },
			{ x = c, y = d, u = cu + math.cos( ang + delta ) * hdu, v = cv + math.sin( ang + delta ) * hdv }
		} )
	end
	
	return vertices
end

local white = Color( 255, 255, 255, 255 )
function draw.TexturedRoundedBox( border, x, y, w, h, color, u1, v1, u2, v2 )
	color = color or white
	surface.SetDrawColor( color.r, color.g, color.b, color.a )
	u1, v1, u2, v2 = u1 or 0, v1 or 0, u2 or 1, v2 or 1
	local du, dv = u2 - u1, v2 - v1
	
	local verts = {}
	
	table.Add( verts, rect( x, y + border, w, h - border*2, u1, v1 + border/h*dv, u2, v2 - border/h*dv ) )
	table.Add( verts, rect( x + border, y, w - border*2, border, u1 + border/w*du, v1, u2 - border/w*du, v1 + border/h*dv ) )
	table.Add( verts, rect( x + border, y + h - border, w - border*2, border, u1 + border/w*du, v2 - border/h*dv, u2 - border/w*du, v2 ) )
	
	table.Add( verts, circle( x + border, y + border, border, border, 1 * math.pi, 1.5 * math.pi, u1, v1, u1 + border/w*2*du, v1 + border/h*2*dv ) )
	table.Add( verts, circle( x + w - border, y + border, border, border, 1.5 * math.pi, 2 * math.pi, u2 - border/w*2*du, v1, u2, v1 + border/h*2*dv ) )
	table.Add( verts, circle( x + w - border, y + h - border, border, border, 0, 0.5 * math.pi, u2 - border/w*2*du, v2 - border/h*2*dv, u2, v2 ) )
	table.Add( verts, circle( x + border, y + h - border, border, border, 0.5 * math.pi, math.pi, u1, v2 - border/h*2*dv, u1 + border/w*2*du, v2 ) )
	
	surface.DrawPoly( verts )
end

--[[local mat = surface.GetTextureID( "VGUI/entities/npc_antlion" )
hook.Add( "HUDPaint", "lol", function()
	surface.SetTexture( mat )
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.DrawTexturedRect( 100, 100, 400, 300 )
	
	draw.TexturedRoundedBox( 64, 570, 100, 400, 300, Color( 255, 255, 255, 255 ), 0, 0, 1, 1 )
end )]]