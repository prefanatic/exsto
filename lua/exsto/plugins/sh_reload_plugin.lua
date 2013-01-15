 -- Exsto
 -- Reload Plugin Plugin (lol)

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Plugin Controls",
	ID = "plugcontrols",
	Desc = "A plugin that provides reloading support for plugins, and a plugin menu!",
	Owner = "Prefanatic",
} )

if SERVER then

	function PLUGIN:ResendPlug( ply, filename )
		-- This better be a cloud.
		
		local data = file.Read( "exsto_cloud/" .. filename .. ".txt" )
		if !data then return { ply, COLOR.NORM, "Could not find plugin ", COLOR.NAME, filename, COLOR.NORM, ".  It doesn't exist!" } end
		
		local sender = exsto.CreateSender( "ExPlug_Reload", "all" )
			sender:AddString( data )
		sender:Send()
		
		
		return { COLOR.NORM, "Resending plugin ", COLOR.NAME, filename, COLOR.NORM, "!" }
	end
	PLUGIN:AddCommand( "resendplug", {
		Call = PLUGIN.ResendPlug,
		Desc = "Allows users to resend plugins to the client.",
		Console = { "resendplug" },
		Chat = { "!resendplug" },
		ReturnOrder = "Plug",
		Args = { Plug = "STRING" },
		Category = "Utilities",
	})

	function PLUGIN:ReloadPlug( ply, plugname )
		local plug = exsto.Plugins[plugname]
		if !plug then return { ply, COLOR.NORM, "Could not find plugin ", COLOR.NAME, plugname, COLOR.NORM, ".  It doesn't exist!" } end
		
		plug.Object:Reload()
		
		return { COLOR.NORM, "Reloading plugin ", COLOR.NAME, plug.Name, COLOR.NORM, "!" }
	end
	PLUGIN:AddCommand( "reloadplug", {
		Call = PLUGIN.ReloadPlug,
		Desc = "Allows users to reload plugins.",
		Console = { "reloadplug" },
		Chat = { "!reloadplug" },
		ReturnOrder = "Plug",
		Args = { Plug = "STRING" },
		Category = "Utilities",
	})
	
	exsto.CreateFlag( "plugindisable", "Allows users to disable or enable plugins in the Plugin List page." )

	function PLUGIN.SendServerPlugins( ply )
		for k,v in pairs( exsto.Plugins ) do	
			local sender = exsto.CreateSender( "ExSendPlugs", ply )
				sender:AddString( k )
				sender:AddString( v.Name )
				sender:AddString( v.Desc )
				sender:AddBool( v.Experimental )
				sender:Send()
		end
		exsto.CreateSender( "ExSendPlugsDone", ply ):Send()
	end
	concommand.Add( "_SendPluginList", PLUGIN.SendServerPlugins )
	
	function PLUGIN.TogglePlugin( ply, _, args )

		if !ply:IsAllowed( "pluginlist" ) then return end
		if math.Round( tostring( args[1] ) ) != ply.MenuAuthKey then return end

		local style = tobool( args[2] )
		local short = args[3]
		
		local plugin = exsto.Plugins[short]
		if !plugin then return end
		
		if !ply.PlugChange then ply.PlugChange = CurTime() end
		if CurTime() < ply.PlugChange then return end
		
		ply.PlugChange = CurTime() + 1
		if style then 
			-- We are trying to enable him.
			exsto.EnablePlugin( plugin.Object )
			exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "Enabling plugin ", COLOR.NAME, plugin.Name, COLOR.NORM, "!"  )
		else
			-- He needs to die.
			exsto.DisablePlugin( plugin.Object )
			exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "Disabling plugin ", COLOR.NAME, plugin.Name, COLOR.NORM, "!"  )
		end	
		
		exsto.ResendCommands()

	end
	concommand.Add( "_TogglePlugin", PLUGIN.TogglePlugin )
	
elseif CLIENT then

	local function receive( reader )
		RunString( reader:ReadString() )
	end
	exsto.CreateReader( "ExPlug_Reload", receive )

	local plugins = {}
	function PLUGIN.RecievePlugins( reader )
		table.insert( plugins, {
				ID = reader:ReadString(),
				Name = reader:ReadString(),
				Desc = reader:ReadString(),
				Experimental = reader:ReadBool(),
			}
		)
	end
	exsto.CreateReader( "ExSendPlugs", PLUGIN.RecievePlugins )
	
	local function sent()
		PLUGIN.Recieved = true
		PLUGIN.Panel:EndLoad()
		PLUGIN.Build( PLUGIN.Panel )
	end
	exsto.CreateReader( "ExSendPlugsDone", sent )
	
	function PLUGIN.ReloadData( panel )
		plugins = {}
		RunConsoleCommand( "_SendPluginList" )
	end
	
	function PLUGIN.GetProperSize( text, max, font )
		surface.SetFont( font )
		
		local w, h = surface.GetTextSize( text )
		if w < max then return w, h end
		
		local spaceW, spaceH = surface.GetTextSize( " " )
		local split = string.Explode( " ", text )
		local newW = 0
		local newH = 0
		
		for _, word in ipairs( split ) do
			w, h = surface.GetTextSize( word )
			newW = newW + w + spaceW
			
			if newW >= max then
				newW = 0
				newH = newH + h + 18
			end
		end

		return max, newH
	end
	
	local function sort( a, b )
		return a.Name < b.Name
	end
	
	function PLUGIN.Build( panel )
	
		-- List view of the plugins.
		panel.pluginList = exsto.CreateComboBox( 10, 10, panel:GetWide() - 20, panel:GetTall() - 70, panel )
		
		-- Sort them nicely
		table.sort( plugins, sort )
		for k,v in ipairs( plugins ) do
		
			local obj = panel.pluginList:AddItem( " " )
				obj.PaintOver = function( self )
					draw.SimpleText( v.Name, "exstoPlyColumn", 5, self:GetTall() / 2, Color( 68, 68, 68, 255 ), 0, 1 )
					
					if self.OldIcon != self.Icon then
						self.IconID = surface.GetTextureID( self.Icon )
						self.OldIcon = self.Icon
					end

					surface.SetTexture( self.IconID )
					surface.SetDrawColor( 255, 255, 255, 255 )
					surface.DrawTexturedRect( panel.pluginList:GetWide() - 40, ( self:GetTall() / 2 ) - 8, 16, 16 )
				end
				if exsto.ServerPlugSettings[v.ID] then
					obj.Icon = "icon_on"
				else
					obj.Icon = "icon_off"
				end
				
				if LocalPlayer():IsSuperAdmin() then
						obj.DoClick = function( self )
							if !LocalPlayer().PlugChange then LocalPlayer().PlugChange = CurTime() end
							if CurTime() < LocalPlayer().PlugChange then panel:PushError( "Slow down, you are toggling plugins too fast!" ) return end
							
							LocalPlayer().PlugChange = CurTime() + 1
							
							if exsto.ServerPlugSettings[v.ID] then
								-- We are trying to disable the plugin.
								
								exsto.ServerPlugSettings[v.ID] = false
								
								Menu.CallServer( "_TogglePlugin", "false", v.ID )
								self.Icon = "icon_off"
							else
								-- Trying to enable it.
								
								exsto.ServerPlugSettings[v.ID] = true

								Menu.CallServer( "_TogglePlugin", "true", v.ID )
								self.Icon = "icon_on"
							end
						end
				end
		end
		
	end

	Menu:CreatePage( {
		Title = "Plugin List",
		Short = "pluginlist",
		},
		function( panel )
			if !PLUGIN.Recieved then
				panel:PushLoad()
				RunConsoleCommand( "_SendPluginList" )
			else
				PLUGIN.Build( PLUGIN.Panel )
			end
			PLUGIN.Panel = panel
		end
	)
	
end

PLUGIN:Register()