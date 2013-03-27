-- Clientside Chat v2

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Custom Chat",
	ID = "cl-chat",
	Desc = "A cool custom chat with supporting animations.",
	Owner = "Prefanatic",
})

if SERVER then

	util.AddNetworkString( "ExChatPlug_RankColors" )
	util.AddNetworkString( "ExChatPlug_AdminBlink" )
	util.AddNetworkString( "ExChatPlug_ToggleAnims" )
	
	local OnVarChange2 = function( val )
		for k,v in pairs( player.GetAll() ) do
			PLUGIN:SetRankColors( v, val )
		end
		return true
	end
	
	local OnVarChange1 = function( old, val )
		for k,v in pairs( player.GetAll() ) do
			PLUGIN:SetAdminBlink( v, val )
		end
		return true
	end

	function PLUGIN:Init()
		resource.AddFile( "sound/name_said.wav" )
		
		self.NativeColors = exsto.CreateVariable( "ExNativeColors",
			"Native Colors",
			false,
			"Enable Exsto to override team colors w/ rank colors."
		)
		self.NativeColors:SetCategory( "Chat" )
		self.NativeColors:SetCallback( OnVarChange2 )
		
		self.Blink = exsto.CreateVariable( "ExChatBlink",
			"Admin Blink",
			false,
			"Enable Exsto to blink superadmin chat messages."
		)
		self.Blink:SetCallback( OnVarChange1 )
		self.Blink:SetCategory( "Chat" )
	end
	
	function PLUGIN:ToggleAnims( owner )
		exsto.CreateSender( "ExChatPlug_ToggleAnims", owner ):Send()
	end
	PLUGIN:AddCommand( "togglechatanim", {
		Call = PLUGIN.ToggleAnims,
		Desc = "Allows users to toggle chat animations on or off.",
		Console = { "togglechatanims" },
		Chat = { "!chatanim" },
		Args = { },
	} )
	
	function PLUGIN:PlayerInitialSpawn( ply )
		for _, v in ipairs( player.GetAll() ) do
			exsto.Print( exsto_CHAT_NOLOGO, v, COLOR.NAME, ply:Nick(), COLOR.NORM, " has joined the server!" )
		end
	end
	
	function PLUGIN:PlayerDisconnected( ply )
		for _, v in ipairs( player.GetAll() ) do
			exsto.Print( exsto_CHAT_NOLOGO, v, COLOR.NAME, ply:Nick(), COLOR.NORM, " has left the server!" )
		end
	end
	
	function PLUGIN:SetAdminBlink( ply, val )
		local sender = exsto.CreateSender( "ExChatPlug_AdminBlink", ply )
			sender:AddBool( val )
			sender:Send()
	end
	
	function PLUGIN:SetRankColors( ply, val )
		local sender = exsto.CreateSender( "ExChatPlug_RankColors", ply )
			sender:AddBool( val )
			sender:Send()
	end
	
	function PLUGIN:ExClientPluginsReady( ply )
		self:SetAdminBlink( ply, self.Blink:GetValue() )
		self:SetRankColors( ply, self.NativeColors:GetValue() )
	end
	
elseif CLIENT then
	
	local colName = table.Copy( COLOR.NAME )
	local colNorm = table.Copy( COLOR.NORM )
	
	surface.CreateFont( "ChatText", { font = "coolvetica", size = 20, weight = 400 } )
	
	function PLUGIN:Init()
		-- Create variables.
		self.GlobalX = CreateClientConVar( "ExChat_PosX", 35, true )
		self.GlobalYOffset = CreateClientConVar( "ExChat_OffsetY", 310, true )
		self.GlobalEnabled = CreateClientConVar( "ExChat_Enable", 1, true )
		self.GlobalFont = CreateClientConVar( "ExChat_Font", "ChatText", true )
		
		self.ChatLabelDefault = "Chat"
		self.ChatLabel = self.ChatLabelDefault
		
		self.MaxLines = 5
		self.OutlineColor = Color( 0, 0, 0, 0 )
		
		self.Colors = {}
		self.Colors.White = Color( 255, 255, 255, 200 )
		self.Colors.Outline = self.OutlineColor
		self.Colors.Twitter = Color( 103, 207, 255, 200 )
		self.Colors.Friend = Color( 255, 203, 124, 200 )
		self.Colors.Scroll = Color( 255, 203, 124, 200 )
		
		self.Lines = {}
		self.LineLivingTime = 8
		
		self.ScrollSelection = 0
		
		self.Fade = 0
		self.BlinkAdmins = false
		self.RankColors = false
		self.AnimateLines = true
		
		self.X = self.GlobalX:GetInt()
		self.Y = ScrH() - self.GlobalYOffset:GetInt()
	
		-- ******
		-- Create the panel.
		-- ******
		self.Panel = vgui.Create( "ExChatBox" )
		
		self.Panel:SetPos( self.X, self.Y )
		self.Panel:SetSize( self.Panel.W + 20, self.Panel.H )
		
		chat.AddText( COLOR.NORM, "Don't like the chat? ", COLOR.NAME, "Disable", COLOR.NORM, " it by typing '", COLOR.NAME, "ExChat_Enable 0", COLOR.NORM, "' in console!" )

	end
	
	local function SetRankColors( reader )
		PLUGIN.RankColors = reader:ReadBool()
	end
	exsto.CreateReader( "ExChatPlug_RankColors", SetRankColors )
	
	local function SetAdminBlink( reader )
		PLUGIN.BlinkAdmins = reader:ReadBool()
	end
	exsto.CreateReader( "ExChatPlug_AdminBlink", SetAdminBlink )
	
	local function AnimateLines( reader )
		PLUGIN.AnimateLines = !PLUGIN.AnimateLines
		
		if PLUGIN.AnimateLines then chat.AddText( COLOR.NORM, "Chat animations have been ", COLOR.NAME, "enabled", COLOR.NORM, "!" ) end
		if !PLUGIN.AnimateLines then chat.AddText( COLOR.NORM, "Chat animations have been ", COLOR.NAME, "disabled", COLOR.NORM, "!" ) end
	end
	exsto.CreateReader( "ExChatPlug_ToggleAnims", AnimateLines )
	
	function PLUGIN:Toggle( bool, team )
	
		if self.Open == bool then return end
		
		autoopt = 1
		ACExtra = 0
		ACSlots = {}
		
		self.Open = bool
		self.TeamMode = team
		
		self.Panel:SetKeyboardInputEnabled( bool )
		self.Panel:SetMouseInputEnabled( bool )
		
		self.ScrollSelection = 0
		
		if bool then
			self:OnChatChange( "" )
			
			self.Panel:MakePopup()
			self.Panel:SetFocusTopLevel( true )
			self.Panel.Entry:RequestFocus()
		else
			self.Panel.Entry:SetText( "" )
		end
	end
	
	function PLUGIN:OnPlayerChat( ply, text, team, dead )
		//if self.GlobalEnabled:GetInt() == 0 then return end
		if ply:EntIndex() == 0 then
			chat.AddText( colName, "Console", colNorm, ": " .. text )
			return true
		end
	end

	function PLUGIN:ChatText( index, nick, msg, type )	
		//if self.GlobalEnabled:GetInt() == 0 then return end
		if type == "none" then
			chat.AddText( msg )
		end
	end

	function PLUGIN:PlayerBindPress( ply, bind, pressed )
		if self.GlobalEnabled:GetInt() == 0 then return end
		if string.find( bind, "messagemode" ) then
			self:Toggle( true, bind == "messagemode2" )
			return true
		elseif string.find( bind, "cancelselect" ) then
			self:Toggle( false, false )
			return true
		end
	end
	
	function PLUGIN.UpdatePosition( var, prev, new )
		if !PLUGIN.GlobalX or !PLUGIN.GlobalYOffset then print( "unable to access cvars" ) return end
		PLUGIN.X = PLUGIN.GlobalX:GetInt()
		PLUGIN.Y = ScrH() - PLUGIN.GlobalYOffset:GetInt()
		PLUGIN.Panel:SetPos( PLUGIN.X, PLUGIN.Y )
	end
	cvars.AddChangeCallback( "ExChat_PosX", PLUGIN.UpdatePosition )
	cvars.AddChangeCallback( "ExChat_OffsetY", PLUGIN.UpdatePosition )
	
	function PLUGIN:GetLinePos( line )
		return line.Anims.LastX, line.Anims.LastY
	end
	
	function PLUGIN:SetLinePos( line, x, y )
		line.Anims.CurX = x
		line.Anims.CurY = y
	end
	
	function PLUGIN:GetLineWidth( line )
		return line.Width
	end
	
	local split, selected
	function PLUGIN:OnChatTab( text )
		if self.GlobalEnabled:GetInt() == 0 then return end
	
		for _, ply in ipairs( player.GetAll() ) do
			split = string.Explode( " ", text )
			if string.find( ply:Nick():lower(), split[#split]:lower() ) then
				return ply:Nick()
			end
		end
	
		if self.Panel:AutoCompleteBuilt() then
		
			split = string.Explode( " ", text )
			selected = self.Panel:AutoCompleteSelected()
			
			if selected and #split == 1 then
				return selected.Name .. " "
			end
			
		end
		
		return text
		
	end
	
	-- Commonly used variables for chatchange
	local split
	local oldText = oldText or ""
	
	function PLUGIN:OnChatChange( text )
		split = string.Explode( " ", text )
		split[1] = string.gsub(split[1],"#","")
		if text != oldText then
			ACExtra = 0
			autoopt = 1
			oldText = text
		end
		
		if self.Panel:AutoCompleteBuilt() and text:sub( 1, 1 ) != "!" then
			self.Panel:ClearAutoComplete()		end	
		
		-- If we are going to PM somebody.
		if text:sub( 1, 1 ) == "@" then 
			self.ChatLabel = "PM"
			self.Panel:Resize()
           
		-- If we are going to run an Exsto command.
		elseif text:sub( 1, 1 ) == "!" then
			
			if !exsto.Commands then return end
			
			self.Panel:ClearAutoComplete()
			for _, command in pairs( exsto.Commands ) do
				if command.Chat then
					for _, chat in ipairs( command.Chat ) do
					
						if string.find( chat:lower():Trim(), split[1]:lower():Trim(), 1, true ) then
							self.Panel:AddAutoComplete( chat, command )
						end
					end
				end
			end
            
			self.Panel:BuildAutoComplete()
            
			self.ChatLabel = self.Panel.AutoComplete.Width == 0 and self.ChatLabelDefault or "Exsto"
			self.Panel:Resize()
			
		-- If it's team chat.
        elseif PLUGIN.TeamMode then
			self.ChatLabel = "[TEAM] Chat"
			self.Panel:Resize()
            	
		else
			self.ChatLabel = "Chat"
			self.Panel:Resize()
		
		end
		
	end
	
	-- Commonly used variables for animate
	local dist, speed
	function PLUGIN:AnimateLine( line, mul )
	
		-- If we are not animating, just set our last as the current.
		if !self.AnimateLines then
			line.Anims.LastX = line.Anims.CurX
			line.Anims.LastY = line.Anims.CurY
		end
	
		-- Monitor his values.  If he is closed and gets to the point where he can be disabled draw wise, do it.
		if line.BeginClose then
			if line.Anims.LastX <= line.Anims.CurX then
				line.Closed = true
			end
		end
		
		mul = ( math.floor( 1 / FrameTime() ) / 3 ) * mul
	
		-- Set our multiples on our framerate.

		if math.Round( line.Anims.LastX ) != line.Anims.CurX then
			dist = line.Anims.CurX - line.Anims.LastX
			speed = dist / mul
			
			line.Anims.LastX = math.Approach( line.Anims.LastX, line.Anims.CurX, speed )
		end
	
		if math.Round( line.Anims.LastY ) != line.Anims.CurY then
			dist = line.Anims.CurY - line.Anims.LastY
			speed = dist / mul
			
			line.Anims.LastY = math.Approach( line.Anims.LastY, line.Anims.CurY, speed )	
		end
		
	end
	
	-- Commonly used variables for drawline
	local x, y, len, w, col, text
	function PLUGIN:DrawLine( line )
	
		if line.Closed then return end
	
		x = line.Anims.LastX
		y = line.Anims.LastY
		len = table.Count( line.Blocks )
		
		for I = 1, len do
			
			w = line.Blocks[I]["Width"]
			col = line.Blocks[I]["Color"]
			text = line.Blocks[I]["Text"]
			
			if line.Blocks[I]["Blink"] then
				col = PLUGIN:BlinkColor( col )
			end
			
			if I == 1 and line.AdminSpoke and self.BlinkAdmins then
				col = PLUGIN:BlinkColor( col )
			end
			
			draw.SimpleTextOutlined( text, self.GlobalFont:GetString(), x, y, self:ColorAlpha( col, 255 ), 0, 0, 1, self:ColorAlpha( self.OutlineColor, 255 ) )
			
			if w then x = x + w or x end
			
		end
		
	end
	
	function PLUGIN:HUDShouldDraw( name )
		if self.GlobalEnabled:GetInt() == 0 then return end
		if name == "CHudChat" then return false end
	end
	
	-- Commonly used variables for paint
	local line, x, y, lineHeight, _
	function PLUGIN:HUDPaint()	
		if self.GlobalEnabled:GetInt() == 0 then return end
		
		surface.SetFont( self.GlobalFont:GetString() )
		_, lineHeight = surface.GetTextSize( "H" )
		
		x = self.X + 35
		y = self.Y - 30
		
		-- Loop through the last max.
		for I = 0, self.MaxLines do
			line = self.Lines[ #self.Lines - I - self.ScrollSelection ]
			
			if line then
				if !line.BeginClose then self:SetLinePos( line, x, y ) end
				self:DrawLine( line )
				
				y = y - lineHeight - 2	
			end
		end
	end
	
	-- Commonly used variables in think
	local x, y, w, h
	function PLUGIN:Think()
		if self.GlobalEnabled:GetInt() == 0 then return end
		
		-- Monitor fading stuff here.
		if self.Open then
			if self.Fade != 255 then
				if self.AnimateLines then
					self.Fade = math.Approach( self.Fade, 255, 5 )
				else
					self.Fade = 255
				end
			end
		else
			if self.Fade != 0 then
				if self.AnimateLines then
					self.Fade = math.Approach( self.Fade, 0, 2.5 )
				else
					self.Fade = 0
				end
			end
		end
		
		-- Animate the lines!
		for I = 0, self.MaxLines do
			line = self.Lines[ #self.Lines - I - self.ScrollSelection ]
			
			if line then
				self:AnimateLine( line, self.Open and 0.25 or 0.5 )
			end
		end
		
		-- Send the lines to heaven when they are up.
		for _, line in ipairs( self.Lines ) do
			if line.EndTime <= CurTime() then
			
				x, y = self:GetLinePos( line )
				w = self:GetLineWidth( line )
				self:SetLinePos( line, ( w * -1 ) - 10, y )
				
				line.BeginClose = true
				
			end
		end
		
		-- Bring back all those who lost their lives in the close if we re-open.
		if self.Open then
			for _, line in ipairs( self.Lines ) do
				line.BeginClose = false
				line.Closed = false
				
				x, y = self:GetLinePos( line )
				self:SetLinePos( line, self.X + 35, y )
				
				line.EndTime = CurTime() + self.LineLivingTime - 1
			end
		end
		
		-- Clean the chatbox when it gets too big.
		if table.Count( self.Lines ) > 100 then
			table.remove( self.Lines, 1 )
		end
		        
	end
	
	local newCol
	function PLUGIN:BlinkColor( col )
		newCol = {}
		newCol.r = math.Clamp( col.r + ( math.sin( CurTime() * 7 ) * 90  ), 0, 255 )
		newCol.g = math.Clamp( col.g + ( math.sin( CurTime() * 7 ) * 90  ), 0, 255 )
		newCol.b = math.Clamp( col.b + ( math.sin( CurTime() * 7 ) * 90  ), 0, 255 )
		newCol.a = col.a
		
		return newCol
	end
	
	function PLUGIN:FormatColorString( col )
		return "[c=" .. col.r .. "," .. col.g .. "," .. col.b .. "," .. col.a .. "]"
	end
	
	function PLUGIN:ColorAlpha( col, alpha )
		col.a = alpha
		return col
	end
	
	-- Commonly used variables for chat.AddText
	exsto_PLUGINADDTEXT = exsto_PLUGINADDTEXT or chat.AddText
	local data, colOpen, col, ply, arg
	function chat.AddText( ... )
		if !PLUGIN.GlobalFont:GetString() then return exsto_PLUGINADDTEXT( ... ) end
		if exsto.Plugins[ PLUGIN.Info.ID ] and exsto.Plugins[ PLUGIN.Info.ID ].Disabled then return exsto_PLUGINADDTEXT( ... ) end
		if PLUGIN.GlobalEnabled and PLUGIN.GlobalEnabled:GetInt() == 0 then return exsto_PLUGINADDTEXT( ... ) end
		
		ply = nil
		data = ""
		colOpen = false
		arg = {...}
		
		if type( arg[1] ) == "Player" then ply = arg[1] end

		for _, obj in ipairs( {...} ) do
			if type( obj ) == "table" and obj.r then
				-- We are a color!
				if colOpen then
					data = data .. "[/c]"
					colOpen = false
				end
				
				data = data .. PLUGIN:FormatColorString( obj )
				colOpen = true
			elseif type( obj ) == "Player" then
				if colOpen then
					data = data .. "[/c]"
					colOpen = false
				end
				
				local col = team.GetColor( obj:Team() )
				if PLUGIN.RankColors then col = exsto.GetRankColor( obj:GetRank() ) end
				
				data = data .. PLUGIN:FormatColorString( col )
				data = data .. obj:Nick()
				data = data .. "[/c]"
			elseif type( obj ) == "string" then
				data = data .. obj
			end
		end
		
		PLUGIN:ParseLine( ply, data )
		exsto_PLUGINADDTEXT( ... )
	end
	
	-- Frequently used variables for ParseLine
	local data = {}
		data.Blocks = {}
	local clStart, clEnd, clTag, r, g, b, a, clEndStart, clEndEnd, text, w, h, tmpData, sound
	local id = 1
	local lastSound, totalWidth = 0, 0
	function PLUGIN:ParseLine( ply, line )
	
		surface.SetFont( self.GlobalFont:GetString() )

		while line != "" do
		
			-- Search the string for a color.
			clStart, clEnd, clTag, r, g, b, a = string.find( line, "(%[c=(%d+),(%d+),(%d+),(%d+)%])" )
			
			-- If we found him.
			if clStart then
				-- If he is at the begining.
				if clStart == 1 then
				
					clEndStart, clEndEnd = string.find( line, "(%[/c%])" )
					-- If we found an ending, snip ourselves to the region we can work in
					if clEndStart then clEndStart = clEndStart - 1 else clEndStart = string.len( line ) end
					-- Obviously, if we haven't found an ending just set it's ending as the end snip
					clEndEnd = clEndEnd or string.len( line )
					
					-- Snip out what we can work with.
					text = string.sub( line, clEnd + 1, clEndStart )
					w, h = surface.GetTextSize( text )
					
					-- Insert our data.
					tmpData = {}
					
					tmpData["Text"] = text
					tmpData["Width"] = w
					totalWidth = totalWidth + w
					
					-- Check if our speaker is a player.
					if ply then
					
						-- Are we parsing his own name?
						if text == ply:Nick() then
							tmpData["Color"] = Color( r, g, b, a )
						else

							-- Check for "twitter" style messages.
							if string.sub( text, 3, 3 ) == "@" and string.find( LocalPlayer():Nick():lower(), string.Explode( " ", text )[2]:gsub( "@", "" ):lower(), 1, true ) then
								tmpData["Color"] = self.Colors.Twitter
								tmpData["Blink"] = true
								
								sound = "name_said.wav"
							-- Check if he is a friend.
							elseif ply:GetFriendStatus() == "friend" then
								tmpData["Color"] = self.Colors.Friend
							-- He isn't anyone important.
							else
								tmpData["Color"] = Color( r, g, b, a )
							end
							
							-- Check if he said our name
							if string.find( text, LocalPlayer():Nick(), 1, true ) then
								tmpData["Blink"] = true
								sound = "name_said.wav"
							end
							
							-- Play our sound if it exists
							if lastSound < CurTime() and sound then
								LocalPlayer():EmitSound( sound, 100, math.random( 70, 130 ) )
								lastSound = CurTime() + 1
								sound = nil
							end
							
						end
						
					else
						-- Insert whatever color value exists.
						tmpData["Color"] = Color( r, g, b, a )
					end
					
					if clEndEnd then line = string.sub( line, clEndEnd + 1 ) else line = "" end
					
				-- If he exists after the begining slot.
				elseif clStart > 1 then
				
					text = string.sub( line, 1, clStart - 1 )
					w, h = surface.GetTextSize( text )
					
					tmpData = {}
					
					tmpData["Text"] = text
					tmpData["Color"] = self.Colors.White
					tmpData["Width"] = w
					totalWidth = totalWidth + w
					
					line = string.sub( line, clStart, string.len( line ) )
					
				end
				
				-- Increment our ID for the table.
				id = id + 1
				
			-- If we didn't find any colors...
			else
				
				w, h = surface.GetTextSize( line )
				
				tmpData = {}
				
				tmpData["Text"] = line
				tmpData["Color"] = self.Colors.White
				tmpData["Width"] = w
				totalWidth = totalWidth + w
				
				line = ""
				
			end
			
			-- Save our data if we created the tmpData
			if tmpData then
				table.insert( data.Blocks, tmpData )
				id = 1
				tmpData = nil
			end
			
		end
		
		-- Insert what we found into the plugin lines table
		data.Anims = {
			LastX = self.X + 35,
			LastY = self.Y + 20,
			CurX = self.X + 35,
			CurY = self.Y + 20,
		}
		
		data.EndTime = CurTime() + self.LineLivingTime
		data.Width = totalWidth
		data.AdminSpoke = ply and ply:IsSuperAdmin() or false
			
		table.insert( self.Lines, data )
		data = {}
		data.Blocks = {}
		
	end

	-- Chatbox Panel
    
    local function ScrollUp( )
			if PLUGIN.ScrollSelection + PLUGIN.MaxLines + 1 < #PLUGIN.Lines then PLUGIN.ScrollSelection = PLUGIN.ScrollSelection + 1 end
	end
    
    local function ScrollDown( )
			if PLUGIN.ScrollSelection >= 1 then PLUGIN.ScrollSelection = PLUGIN.ScrollSelection - 1 end
	end
    
	local PANEL = {}
    autoopt = autoopt or 1
	ACExtra = ACExtra or 0
	ACSlots = ACSlots or {}
	
	function PANEL:Init()
		
		self.X = 35
		self.Y = ScrH() - 310
		self.W = 480
		self.H = 20
		
		self.AutoComplete = {
			Slots = {},
			Width = 0,
			Height = 0,
			Built = false,
		}
		
		self:NoClipping( true )
		
		-- ******
		-- Create the first label.
		-- ******
		self.Label = vgui.Create( "DLabel", self )
		self.Label:SetPos( 5, 2 )
		self.Label:SetFont( PLUGIN.GlobalFont:GetString() )
		self.Label:SetText( PLUGIN.ChatLabelDefault )
		self.Label:SizeToContents()
		self.Label:NoClipping( true )
		
		self.Label.Paint = function( self )
			draw.SimpleTextOutlined( self:GetValue(), PLUGIN.GlobalFont:GetString(), 0, 0, PLUGIN:ColorAlpha( PLUGIN.Colors.White, PLUGIN.Fade ), 0, 0, 1, PLUGIN:ColorAlpha( PLUGIN.Colors.Outline, PLUGIN.Fade ) )
			return true
		end

		-- ******
		-- Create the entry.
		-- ******
		self.Entry = vgui.Create( "DTextEntry", self )
		
		self.Entry:SetPos( self.Label:GetWide() + 10, 0 )
		self.Entry:SetSize( self.W - self.Label:GetWide() - 10, self.H )
		self.Entry:SetAllowNonAsciiCharacters( true )
		
		local split
		self.Entry.OnKeyCodeTyped = function( self, code )
			local text = self:GetValue()
			local ctrl = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
			autoopt = autoopt + (code==KEY_DOWN and 1 or code==KEY_UP and -1 or 0)
			
			if autoopt < 1 then
				if ACExtra > 0 then
					ACExtra = ACExtra - 1 
					self:OnTextChanged(text)
				end
				autoopt = 1
			elseif autoopt > 7 or (autoopt > #ACSlots and #ACSlots > 0) then
				if (ACExtra + autoopt) < #ACSlots then 
					ACExtra = ACExtra + 1
					self:OnTextChanged(text)
				end
				autoopt = (7 < #ACSlots) and 7 or #ACSlots
			end
			
			
			if code == KEY_ENTER then
				RunConsoleCommand( PLUGIN.TeamMode and "say_team" or "say", text )
				PLUGIN:Toggle( false )
			elseif ctrl and code == KEY_UP then
				ScrollUp()
			elseif ctrl and code == KEY_DOWN then
				ScrollDown()
			elseif code == KEY_ESCAPE then
				PLUGIN:Toggle( false )
			elseif code == KEY_TAB then
				split = string.Explode( " ", text )
				self:SetText( text:gsub( split[#split], PLUGIN:OnChatTab( text ) ) )
				self:OnTextChanged()
			end
		end
		
		self.Entry.OnTextChanged = function( self )
			PLUGIN:OnChatChange( self:GetValue() )
		end
		
		local think
		if self.Entry.Think then think = self.Entry.Think end
		self.Entry.Think = function( self )
			if think then think( self ) end
			
			if !self:HasFocus() then
				-- Reset our focus please.
				self:RequestFocus()
			end
		end
		
		local oldScheme = self.Entry.ApplySchemeSettings
		self.Entry.ApplySchemeSettings = function( self, ... )
			oldScheme( self, ... )
			
			self:SetTextColor( Color( 255, 255, 255, 255 ) )
			self:SetCursorColor( Color( 255, 255, 255, 255 ) )
		end
		
		self.Entry:SetDrawBackground( false )
		self.Entry:SetDrawBorder( false )
		
		self.Scrollup = exsto.CreateButton( self.Label:GetWide() + 10 + self.Entry:GetWide() + 2, 0, 15, 10, "up", self )
		self.Scrolldown = exsto.CreateButton( self.Label:GetWide() + 10 + self.Entry:GetWide() + 2, 10, 15, 10, "down", self )
		
        self.Scrollup.DoClick = ScrollUp
        
		self.Scrolldown.DoClick = ScrollDown
		
		local function paintButton( self )
			draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), PLUGIN:ColorAlpha( PLUGIN.Colors.Scroll, PLUGIN.Fade ) )
			draw.SimpleText( self:GetValue(), "Marlett", self:GetWide() / 2, self:GetTall() / 2, PLUGIN:ColorAlpha( PLUGIN.Colors.White, PLUGIN.Fade ), 1, 1 )
			return true
		end
		self.Scrollup.Paint = paintButton
		self.Scrolldown.Paint = paintButton

	end
        
    function PANEL:OnMouseWheeled( d )
        if d > 0 then ScrollUp()
        else ScrollDown()
        end
    end
	
	local build, arg
	function PANEL:AddAutoComplete( name, command )
	
		if !LocalPlayer():IsAllowed( command.ID ) then return end
	
		surface.SetFont( PLUGIN.GlobalFont:GetString() )
		local autoData = { }
		autoData.Name = name
		
		build = ""
		
		-- Build the function requirements
		if type( command.ReturnOrder ) == "table" then
			for I = 1, #command.ReturnOrder do
				arg = command.ReturnOrder[ I ]
				
				if arg then
					if command.Optional[ arg ] then arg = "[" .. arg .. "]" end
					build = build .. arg:lower():Trim() .. " "
				end
			end
			
			autoData.Arguments = build
		end

		table.insert( self.AutoComplete.Slots, autoData )
		
	end
		
	local function sort( a, b )
		if !a.Name or !b.Name then return end
		if !a.Name[1] or !b.Name[1] then return end
		
		return a.Name < b.Name
	end
	
	local w, h, slot, nw, nh
	function PANEL:BuildAutoComplete()
		surface.SetFont( PLUGIN.GlobalFont:GetString() )
		
		table.sort(self.AutoComplete.Slots, sort)
		ACSlots = self.AutoComplete.Slots
		
		for I = 1+ACExtra, 7+ACExtra do
			slot = self.AutoComplete.Slots[I]
			
			if slot then
				-- Do the name.
				nw, nh = surface.GetTextSize( slot.Name )
				w, h = surface.GetTextSize( slot.Arguments )
				
				self.AutoComplete.Slots[ I ].NameWidth = nw
				self.AutoComplete.Slots[ I ].ArgWidth = w
				
				w = w + nw
				if w >= self.AutoComplete.Width then self.AutoComplete.Width = w + 15 end
				
				self.AutoComplete.Height = self.AutoComplete.Height + h + 5
				self.AutoComplete.Slots[ I ].Place = self.AutoComplete.Height - h - 3
			end
			
		end
		
		-- Clean those who didn't make the cut.
		local temp = {}
		for _, slot in pairs( self.AutoComplete.Slots ) do
			if slot.Place then table.insert(temp, slot) end
		end
		self.AutoComplete.Slots = temp
		
		self.AutoComplete.Built = true

	end
	
	function PANEL:AutoCompleteBuilt()
		return self.AutoComplete.Built
	end
	
	function PANEL:AutoCompleteSelected()
		return self.AutoComplete.Slots[autoopt]
	end
	
	function PANEL:ClearAutoComplete()
		self.AutoComplete = { 
			Slots = {},
			Width = 0,
			Height = 0,
			Built = false,
		}
	end
	
	function PANEL:Paint()
		surface.SetFont( PLUGIN.GlobalFont:GetString() )
	
		-- Draw green fill on the nice label
		surface.SetDrawColor( 119, 255, 91, PLUGIN.Fade / 2 )
		surface.DrawRect( 0, 0, self.Label:GetWide() + 10, self.Label:GetTall() )
		
		-- Draw text box stuff
		surface.SetDrawColor( 50, 50, 50, PLUGIN.Fade / 2 )
		surface.DrawRect( self.Label:GetWide() + 10, 0, self.W - self.Label:GetWide() - 10, self.H )
	
		-- Create the white outline.
		surface.SetDrawColor( 255, 255, 255, PLUGIN.Fade )
		surface.DrawOutlinedRect( 0, 0, self.Label:GetWide() + 10 + self.Entry:GetWide(), self:GetTall() )
		
		-- Draw white seperator line
		surface.DrawLine( self.Label:GetWide() + 10, 0, self.Label:GetWide() + 10, self.H )
		
		-- Draw autocomplete if availible.
		if self.AutoComplete.Built then
			
			surface.SetDrawColor( 119, 255, 91, PLUGIN.Fade / 2 )
			surface.DrawRect( PLUGIN.X, 25, self.AutoComplete.Width, self.AutoComplete.Height )
			
			surface.SetDrawColor( 255, 255, 255, PLUGIN.Fade )
			surface.DrawOutlinedRect( PLUGIN.X, 25, self.AutoComplete.Width, self.AutoComplete.Height )
			
			for _, slot in ipairs( self.AutoComplete.Slots ) do
				if slot.Place and _ == autoopt then
					local textCount = #string.Explode(" ",self.Entry:GetValue())
					draw.SimpleTextOutlined( slot.Name, PLUGIN.GlobalFont:GetString(), PLUGIN.X + 5, slot.Place + 25, PLUGIN:ColorAlpha( textCount == 1 and PLUGIN:BlinkColor(colName) or colName, PLUGIN.Fade ), 0, 0, 1, PLUGIN:ColorAlpha( PLUGIN.Colors.Outline, PLUGIN.Fade ) )
					
					local extraWidth = 0
					local argSplit = string.Explode(" ",slot.Arguments)
					table.remove(argSplit)
					for _, arg in pairs (argSplit) do
						draw.SimpleTextOutlined( arg, PLUGIN.GlobalFont:GetString(), PLUGIN.X + 10 + slot.NameWidth + extraWidth, slot.Place + 25, PLUGIN:ColorAlpha( (textCount - 1) == _ and PLUGIN:BlinkColor(colNorm) or colNorm, PLUGIN.Fade ), 0, 0, 1, PLUGIN:ColorAlpha( PLUGIN.Colors.Outline, PLUGIN.Fade ) )
						w, h = surface.GetTextSize(arg.." ")
						extraWidth = extraWidth + w
					end
					
				elseif slot.Place then
					draw.SimpleTextOutlined( slot.Name, PLUGIN.GlobalFont:GetString(), PLUGIN.X + 5, slot.Place + 25, PLUGIN:ColorAlpha( colName, PLUGIN.Fade ), 0, 0, 1, PLUGIN:ColorAlpha( PLUGIN.Colors.Outline, PLUGIN.Fade ) )
					draw.SimpleTextOutlined( slot.Arguments, PLUGIN.GlobalFont:GetString(), PLUGIN.X + 10 + slot.NameWidth, slot.Place + 25, PLUGIN:ColorAlpha( colNorm, PLUGIN.Fade ), 0, 0, 1, PLUGIN:ColorAlpha( PLUGIN.Colors.Outline, PLUGIN.Fade ) )
				end
			end
			
		end
		
	end
	
	function PANEL:Resize()
		if PLUGIN.ChatLabel == self.OldLabel then return end
		
		self.OldLabel = PLUGIN.ChatLabel
		self.Label:SetText( PLUGIN.ChatLabel )
		self.Label:SizeToContents()
		self.Entry:SetPos( self.Label:GetWide() + 10, 0 )
		self.Entry:SetWide( self.W - self.Label:GetWide() - 10 )

		self.Scrollup:SetPos( self.Label:GetWide() + 10 + self.Entry:GetWide() + 2, 0 )
		self.Scrolldown:SetPos( self.Label:GetWide() + 10 + self.Entry:GetWide() + 2, 10 )
	end
	
	vgui.Register( "ExChatBox", PANEL, "EditablePanel" )
	
end

PLUGIN:Register()
	