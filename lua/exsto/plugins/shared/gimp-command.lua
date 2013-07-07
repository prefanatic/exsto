local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Gimp - Gag - Mute",
	ID = "gimggagmute",
	Desc = "A plugin that allows a variety of player language controls!",
	Owner = "Prefanatic",
} )

if SERVER then

	PLUGIN.Sayings = {
		"You smell like me.",
		"Fucking is so fucking awesome.",
		"I sense that you all love me, very, very much.",
		"Seeing is believing.",
		"You look :)",
		"How do I speak llama?",
		"Semper ubi sub ubi!",
		"I realize the truth in your opinion, and swiftly deny it.",
		"I know everything.",
		"Ban me, please.",
		"I hope I'm not gimped.",
		"This server sucks lolol.",
		"Garry is my hero!",
	}

	function PLUGIN:Init()
		if !file.Exists( "exsto/gimps.txt", "DATA" ) then
			file.Write( "exsto/gimps.txt", string.Implode( "\n", self.Sayings ) )
		else
			self.Sayings = string.Explode( "\n", file.Read( "exsto/gimps.txt" ) )
		end
		
		self.DB = FEL.CreateDatabase( "exsto_plugin_mute" )
			self.DB:SetDisplayName( "Persistent Mute" )
			self.DB:ConstructColumns( {
				ID = "VARCHAR(255):primary:not_null";
				Muted = "TINYINT";
			} )
		
		util.AddNetworkString( "ExMutePlayer" )
	end

	function PLUGIN:AddGimp( owner, message )
		table.insert( self.Sayings, message )
		file.Write( "exsto/gimps.txt", string.Implode( "\n", self.Sayings ) )
		
		return { owner, COLOR.NORM, "Adding message to ", COLOR.NAME, "gimp data!" }
	end
	PLUGIN:AddCommand( "addgimp", {
		Call = PLUGIN.AddGimp,
		Desc = "Allows users to add gimp messages.",
		Console = { "addgimp" },
		Chat = { "!addgimp" },
		ReturnOrder = "Message",
		Args = {Message = "STRING"},
		Category = "Chat",
	})
	
	function PLUGIN:Gimp( owner, ply )
		if self:IsGimped( ply ) then
			ply:Print( exsto_CHAT, COLOR.NAME, ply:Nick(), COLOR.NORM, " is already gimped." )
			return
		end
		
		ply.Gimped = true
		exsto.NotifyChat( COLOR.NAME, owner:Nick(), COLOR.NORM, " has gimped ", COLOR.NAME, ply:Nick() )
	end
	PLUGIN:AddCommand( "gimp", {
		Call = PLUGIN.Gimp,
		Desc = "Allows users to gimp other players.",
		Console = { "gimp" },
		Chat = { "!gimp" },
		Arguments = {
			{ Name = "Player", Type = COMMAND_PLAYER };
		};
		Category = "Chat",
	})
	PLUGIN:RequestQuickmenuSlot( "gimp", "Gimp" )
	
	function PLUGIN:UnGimp( owner, ply )
		if not self:IsGimped( ply ) then
			ply:Print( exsto_CHAT, COLOR.NAME, ply:Nick(), COLOR.NORM, " is not gimped." )
			return
		end
		
		ply.Gimped = false
		exsto.NotifyChat( COLOR.NAME, owner:Nick(), COLOR.NORM, " has ungimped ", COLOR.NAME, ply:Nick() )
	end
	PLUGIN:AddCommand( "ungimp", {
		Call = PLUGIN.UnGimp,
		Desc = "Allows users to ungimp other players.",
		Console = { "ungimp" },
		Chat = { "!ungimp" },
		Arguments = {
			{ Name = "Player", Type = COMMAND_PLAYER };
		};
		Category = "Chat",
	})
	PLUGIN:RequestQuickmenuSlot( "ungimp", "Ungimp" )

	function PLUGIN:Mute( owner, ply, persist )
		if ply._IsMuted then
			return { owner, COLOR.NAME, ply:Nick(), COLOR.NORM, " is already muted!" }
		end
		
		ply._IsMuted = true
		
		-- Send this to our players
		local sender = exsto.CreateSender( "ExMutePlayer", player.GetAll() )
			sender:AddEntity( ply )
			sender:AddBool( true ) -- Designates if we're muting.
		sender:Send()
		
		local wording = " has muted "
		if persist then
			wording = " has persistently muted "
			
			self.DB:AddRow( {
				ID = ply:SteamID();
				Muted = 1;
			} )
		end
		
		return {
			Activator = owner,
			Player = ply,
			Wording = wording,
		}
	end
	PLUGIN:AddCommand( "mute", {
		Call = PLUGIN.Mute,
		Desc = "Allows users to mute other players.  Persist allows muting across server restarts.",
		Console = { "mute" },
		Chat = { "!mute" },
		Arguments = {
			{ Name = "Victim", Type = COMMAND_PLAYER };
			{ Name = "Persist", Type = COMMAND_BOOLEAN, Optional = false };
		};
		Category = "Chat",
	})
	PLUGIN:RequestQuickmenuSlot( "mute", "Mute" )
	
	function PLUGIN:UnMute( owner, ply )
		if !ply._IsMuted then
			return { owner, COLOR.NAME, ply:Nick(), COLOR.NORM, " is not muted!" }
		end
		
		ply._IsMuted = false
		
		local sender = exsto.CreateSender( "ExMutePlayer", player.GetAll() )
			sender:AddEntity( ply )
			sender:AddBool( false )
		sender:Send()
		
		-- Secretly do this.
		self.DB:GetAll( function( q, d )
			if not d then return end
			for _, p in ipairs( d ) do
				if ( p.ID == ply:SteamID() ) and p.Muted == 1 then
					self.DB:DropRow( p.ID )
				end
			end
		end )
		
		return {
			Activator = owner,
			Player = ply,
			Wording = " has unmuted ",
		}
	end
	PLUGIN:AddCommand( "unmute", {
		Call = PLUGIN.UnMute,
		Desc = "Allows users to unmute other players.",
		Console = { "unmute" },
		Chat = { "!unmute" },
		ReturnOrder = "Victim",
		Args = {Victim = "PLAYER"},
		Category = "Chat",
	})
	PLUGIN:RequestQuickmenuSlot( "unmute", "Unmute" )

	function PLUGIN:Gag( owner, ply )

		local style = " has gagged "
		
		if ply.Gagged then
			ply.Gagged = false	
			style = " has un-gagged "
		else
			ply.Gagged = true
		end
			
		return {
			Activator = owner,
			Player = ply,
			Wording = style,
		}
		
	end
	PLUGIN:AddCommand( "gag", {
		Call = PLUGIN.Gag,
		Desc = "Allows users to gag other players.",
		Console = { "gag" },
		Chat = { "!gag" },
		ReturnOrder = "Victim",
		Args = {Victim = "PLAYER"},
		Category = "Chat",
	})
	PLUGIN:RequestQuickmenuSlot( "gag", "Gag" )

	function PLUGIN:IsMuted( ply )
		if ply.Gagged then return true end
	end

	function PLUGIN:IsGimped( ply )
		if ply.Gimped then return true end
	end

	function PLUGIN:IsGagged( ply )
		if ply.Muted then return true end
	end

	function PLUGIN:PlayerSay( ply, text )
		if self:IsGimped( ply ) then
			for i,com in pairs(exsto.Commands) do
				for k,comm in pairs(com.Chat) do
					if string.match( text, comm, 1, true ) then return exsto.ChatMonitor( ply, text ) end -- Pretty ghetto way of doing it, but whatever.
				end
			end
			return self.Sayings[ math.random( 1, #PLUGIN.Sayings ) ]
		end
		if self:IsGagged( ply ) then
			for i,com in pairs(exsto.Commands) do
				for k,comm in pairs(com.Chat) do
					if string.match( text, comm, 1, true ) then return exsto.ChatMonitor( ply, text ) end
				end
			end
			return ""
		end
	end
	
	-- Send down the muted players we have
	function PLUGIN:ExInitSpawn( ply )
		for _, p in ipairs( player.GetAll() ) do
			if p._IsMuted then
				local sender = exsto.CreateSender( "ExMutePlayer", ply )
					sender:AddEntity( p )
					sender:AddBool( true )
				sender:Send()
			end
		end
		
		-- Look at our persistance and see if we need to mute this dude.
		self.DB:GetAll( function( q, d )
			if not d then return end
			for _, p in ipairs( d ) do
				if ( p.ID == ply:SteamID() ) and p.Muted == 1 then
					ply._IsMuted = true
					local sender = exsto.CreateSender( "ExMutePlayer", player.GetAll() )
						sender:AddEntity( ply )
						sender:AddBool( true )
					sender:Send()
				end
			end
		end )
	end
	
elseif CLIENT then
	
	exsto.CreateReader( "ExMutePlayer", function( reader )
		local ply = reader:ReadEntity()
		ply:SetMuted( reader:ReadBool() )
	end )
	
end

PLUGIN:Register()
