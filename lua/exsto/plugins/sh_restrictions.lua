-- Exsto
-- Rank Restrictions

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Restricter",
	ID = "rank-restrictions",
	Desc = "A plugin that gives functionality to rank restrictions.",
	Owner = "Prefanatic",
} )

PLUGIN.Restrictions = {} 
PLUGIN.FileTypes = {
	props = "Props",
	sweps = "Sweps",
	entities = "Entities",
	stools = "Stools",
}

if SERVER then

	function PLUGIN:Init()
		
		-- Check to see if the server owners want to input their restrictions through the file library.
		if !file.Exists( "exsto_restrictions/readme.txt", "DATA" ) then
			file.CreateDir( "exsto_restrictions" )
			file.Write( "exsto_restrictions/readme.txt", [[
	Please read the following on how to restrict ranks through these files.
	
	1. Please create a file inside this folder with the following style.
		-- exsto_*TYPE*_restrict_*RANK*.txt
		
		Replace *TYPE* with either props, entities, sweps, or stools.
		Replace *RANK* with the short ID of the rank, such as admin or superadmin.
		
	2. Place the information you want inside, separated by lines.  For example,
		weapon_tmp
		weapon_glock
		weapon_something
		
		Place them on each line, separate from each other.  If using models, please have the .mdl at the end.
		
	3. Load up Exsto, it should automatically load up your restriction file and integrate it with the database.
	
			]] )
			
		end
		
		exsto.RestrictDB = FEL.CreateDatabase( "exsto_data_restrictions" )
			exsto.RestrictDB:ConstructColumns( {
				Rank = "VARCHAR(100):primary:not_null";
				Props = "TEXT";
				Stools = "TEXT";
				Entities = "TEXT";
				Sweps = "TEXT";
			} )

		local data = exsto.RestrictDB:GetAll()
		
		if #data == 0 then 
			
			for k,v in pairs( exsto.Ranks ) do
				self.Restrictions[ v.ID ] = {
					Rank = v.ID,
					Props = {},
					Stools = {},
					Entities = {},
					Sweps = {},
				}
				
				self:SaveData( "all", v.ID )
			end

			self:LoadFileRestrictions()
			return
			
		end

		for _, info in pairs( data ) do
			self.Restrictions[ info.Rank ] = {
				Rank = info.Rank,
				Props = von.deserialize( info.Props ),
				Stools = von.deserialize( info.Stools ),
				Entities = von.deserialize( info.Entities ),
				Sweps = von.deserialize( info.Sweps ),
			}
		end
		
		self:LoadFileRestrictions()
		
	end
	
	-- Reggh, this gets over-written after its created by SOMEONE.
	timer.Simple( 1, function()
		local oldCount = exsto.Registry.Player.GetCount
		function exsto.Registry.Player.GetCount( self, ... )
			if self.ExNoLimits and PLUGIN:IsEnabled() then return -1 end
			return oldCount( self, ... )
		end
	end )
	
	function PLUGIN:NoLimits( caller, ply )
		local t = " has enabled limits on "
		if !ply.ExNoLimits then
			ply.ExNoLimits = true
			t = " has disabled limits on "
		else
			ply.ExNoLimits = false
		end
		
		return {
			Activator = caller,
			Player = ply, 
			Wording = t,
		}
	end			
	PLUGIN:AddCommand( "nolimits", {
		Call = PLUGIN.NoLimits,
		Desc = "Allows users to set nolimits on players.",
		Console = { "nolimits" },
		Chat = { "!nolimits" },
		ReturnOrder = "Player",
		Args = { Player = "PLAYER" },
		Category = "Fun",
	})
	PLUGIN:RequestQuickmenuSlot( "nolimits" )
	
	function PLUGIN:ExOnRankCreate( ID )
		if self.Restrictions[ ID ] then return end
		
		self.Restrictions[ ID ] = {
			Rank = ID,
			Props = {},
			Stools = {},
			Entities = {},
			Sweps = {},
		}
					
		self:SaveData( "all", ID )
	end
	
	function PLUGIN:LoadFileRestrictions()
		local load = ""
		for style, format in pairs( self.FileTypes ) do
			for ID, data in pairs( exsto.Ranks ) do
				if file.Exists( "exsto_restrictions/exsto_" .. style .. "_restrict_" .. ID .. ".txt", "DATA" ) then
					load = file.Read( "exsto_restrictions/exsto_" .. style .. "_restrict_" .. ID .. ".txt", "DATA" )
					load = string.Explode( "\n", load )
					
					for k,v in ipairs( load ) do
						table.insert( self.Restrictions[ ID ][format], v )
					end				
					
					self:SaveData( style, ID )
					file.Delete( "exsto_restrictions/exsto_" .. style .. "_restrict_" .. ID .. ".txt", "DATA" )
				end
			end
		end
	end
	
	function PLUGIN:SaveData( type, rank )
	
		local data = self.Restrictions[ rank ]
		local saveData = {}
		
		if type == "all" then
			saveData = {
				Rank = rank,
				Props = von.serialize( data.Props ),
				Stools = von.serialize( data.Stools ),
				Entities = von.serialize( data.Entities ),
				Sweps = von.serialize( data.Sweps ),
			}
			
		elseif type == "props" then
			saveData = {
				Rank = rank,
				Props = von.serialize( data.Props ),
			}
		elseif type == "stools" then
			saveData = {
				Rank = rank,
				Stools = von.serialize( data.Stools ),
			}
		elseif type == "entities" then
			saveData = {
				Rank = rank,
				Entities = von.serialize( data.Entities ),
			}
		elseif type == "sweps" then
			saveData = {
				Rank = rank,
				Sweps = von.serialize( data.Sweps ),
			}
		end
		
		exsto.RestrictDB:AddRow( saveData )

	end
	
	function PLUGIN:CanTool( ply, trace, tool )
		if !self.Restrictions or !self.Restrictions[ ply:GetRank() ] then
			self:Debug( "Unable to access rank restriction table.  Making one for: " .. ply:GetRank(), 1 )
			self:OnExRankCreate( ply:GetRank() )
			return
		end
		if self.Restrictions[ ply:GetRank() ] and table.HasValue( self.Restrictions[ ply:GetRank() ].Stools, tool ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The tool ", COLOR.NAME, tool, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	
	function PLUGIN:PlayerGiveSWEP( ply, class, wep )
		if !self.Restrictions or !self.Restrictions[ ply:GetRank() ] then
			self:Debug( "Unable to access rank restriction table.  Making one for: " .. ply:GetRank(), 1 )
			self:OnExRankCreate( ply:GetRank() )
			return
		end
		if self.Restrictions[ ply:GetRank() ] and table.HasValue( self.Restrictions[ ply:GetRank() ].Sweps, class ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The weapon ", COLOR.NAME, class, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	function PLUGIN:PlayerSpawnSWEP( ply, class, wep )
		if !self.Restrictions or !self.Restrictions[ ply:GetRank() ] then
			self:Debug( "Unable to access rank restriction table.  Making one for: " .. ply:GetRank(), 1 )
			self:OnExRankCreate( ply:GetRank() )
			return
		end
		if self.Restrictions[ ply:GetRank() ] and table.HasValue( self.Restrictions[ ply:GetRank() ].Sweps, class ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The weapon ", COLOR.NAME, class, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	
	function PLUGIN:PlayerSpawnProp( ply, prop )
		if !self.Restrictions or !self.Restrictions[ ply:GetRank() ] then
			self:Debug( "Unable to access rank restriction table.  Making one for: " .. ply:GetRank(), 1 )
			self:OnExRankCreate( ply:GetRank() )
			return
		end
		if self.Restrictions[ ply:GetRank() ] and table.HasValue( self.Restrictions[ ply:GetRank() ].Props, prop ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The prop ", COLOR.NAME, prop, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	
	function PLUGIN:PlayerSpawnSENT( ply, class )
		if !self.Restrictions or !self.Restrictions[ ply:GetRank() ] then
			self:Debug( "Unable to access rank restriction table.  Making one for: " .. ply:GetRank(), 1 )
			self:OnExRankCreate( ply:GetRank() )
			return
		end
		if self.Restrictions[ ply:GetRank() ] and table.HasValue( self.Restrictions[ ply:GetRank() ].Entities, class ) then
			ply:Print( exsto_CHAT, COLOR.NORM, "The entity ", COLOR.NAME, class, COLOR.NORM, " is disabled for your rank!" )
			return false
		end
	end
	
	function PLUGIN:AllowObject( owner, rank, object, data )
		
		if !self.Restrictions[ rank ] then
			local closeRank = exsto.GetClosestString( rank, exsto.Ranks, "ID", owner, "Unknown rank" )
			return
		end

		local tbl = self.Restrictions[ rank ]
		local style = ""
		
		if object == "stools" then 
			tbl = tbl.Stools
			style = "STOOL"
		elseif object == "sweps" then
			tbl = tbl.Sweps
			style = "SWEP"
		elseif object == "props" then
			tbl = tbl.Props
			style = "Prop"
		elseif object == "entities" then
			tbl = tbl.Entities
			style = "Entity"
		end
		
		if !data or data == "" then
			return { owner, COLOR.NORM, "No ", COLOR.NAME, style, COLOR.NORM, " specified!" }
		end
		
		local id = exsto.GetTableID( tbl, data )
		if !id then
			if table.Count( tbl ) == 0 then	
				return { owner, COLOR.NORM, "The " .. style .. " ", COLOR.NAME, data, COLOR.NORM, " doesn't exist in the deny table!" }
			end
			
			exsto.GetClosestString( data, tbl, nil, owner, "Unknown " .. style )
			return
		end
		
		table.remove( tbl, id )
		self:SaveData( object, rank )
		
		return { owner, COLOR.NORM, "Removing " .. style .. " ", COLOR.NAME, data, COLOR.NORM, " from ", COLOR.NAME, rank, COLOR.NORM, " restrictions!" }
	
	end
	
	function PLUGIN:DenyObject( owner, rank, object, data )
	
		if !self.Restrictions[ rank ] then
			local closeRank = exsto.GetClosestString( rank, exsto.Ranks, "ID", owner, "Unknown rank" )
			return
		end
		
		local tbl = self.Restrictions[ rank ]
		local style = ""
		
		if object == "stools" then 
			tbl = tbl.Stools
			style = "STOOL"
		elseif object == "sweps" then
			tbl = tbl.Sweps
			style = "SWEP"
		elseif object == "props" then
			tbl = tbl.Props
			style = "Prop"
		elseif object == "entities" then
			tbl = tbl.Entities
			style = "Entity"
		end
		
		if !data or data == "" then
			return { owner, COLOR.NORM, "No ", COLOR.NAME, style, COLOR.NORM, " specified!" }
		end
		
		table.insert( tbl, data )
		self:SaveData( object, rank )
	
		return { owner, COLOR.NORM, "Inserting " .. style .. " ", COLOR.NAME, data, COLOR.NORM, " into ", COLOR.NAME, rank, COLOR.NORM, " restrictions!" }
		
	end
	
--[[ -----------------------------------
		ENTITIES
     ----------------------------------- ]]
	function PLUGIN:AllowEntity( owner, rank, entity )
		return self:AllowObject( owner, rank, "entities", entity )
	end
	PLUGIN:AddCommand( "allowentity", {
		Call = PLUGIN.AllowEntity,
		Desc = "Allows users to remove disallowed entities from a rank.",
		Console = { "allowentity" },
		Chat = { "!allowentity" },
		ReturnOrder = "Rank-Entity",
		Args = { Rank = "STRING", Entity = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:DenyEntity( owner, rank, entity )
		return self:DenyObject( owner, rank, "entities", entity )
	end
	PLUGIN:AddCommand( "denyentity", {
		Call = PLUGIN.DenyEntity,
		Desc = "Allows users to deny entities to ranks.",
		Console = { "denyentity" },
		Chat = { "!denyentity" },
		ReturnOrder = "Rank-Entity",
		Args = { Rank = "STRING", Entity = "STRING" },
		Category = "Restrictions",
	})
	
--[[ -----------------------------------
		PROPS
     ----------------------------------- ]]
	function PLUGIN:AllowProp( owner, rank, prop )
		if !string.Right( prop, 4 ) == ".mdl" then prop = prop .. ".mdl" end
		return self:AllowObject( owner, rank, "props", prop )
	end
	PLUGIN:AddCommand( "allowprop", {
		Call = PLUGIN.AllowProp,
		Desc = "Allows users to remove disallowed props from a rank.",
		Console = { "allowprop" },
		Chat = { "!allowprop" },
		ReturnOrder = "Rank-Prop",
		Args = { Rank = "STRING", Prop = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:DenyProp( owner, rank, prop )
		if !string.Right( prop, 4 ) == ".mdl" then prop = prop .. ".mdl" end
		return self:DenyObject( owner, rank, "props", prop )
	end
	PLUGIN:AddCommand( "denyprop", {
		Call = PLUGIN.DenyProp,
		Desc = "Allows users to deny props to ranks.",
		Console = { "denyprop" },
		Chat = { "!denyprop" },
		ReturnOrder = "Rank-Prop",
		Args = { Rank = "STRING", Prop = "STRING" },
		Category = "Restrictions",
	})
	
--[[ -----------------------------------
		SWEPS
     ----------------------------------- ]]
	function PLUGIN:AllowSwep( owner, rank, swep )
		return self:AllowObject( owner, rank, "sweps", swep )
	end
	PLUGIN:AddCommand( "allowswep", {
		Call = PLUGIN.AllowSwep,
		Desc = "Allows users to remove disallowed sweps from a rank.",
		Console = { "allowswep" },
		Chat = { "!allowswep" },
		ReturnOrder = "Rank-Swep",
		Args = { Rank = "STRING", Swep = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:DenySwep( owner, rank, swep )
		return self:DenyObject( owner, rank, "sweps", swep )
	end
	PLUGIN:AddCommand( "denyswep", {
		Call = PLUGIN.DenySwep,
		Desc = "Allows users to deny sweps to ranks.",
		Console = { "denyswep" },
		Chat = { "!denyswep" },
		ReturnOrder = "Rank-Swep",
		Args = { Rank = "STRING", Swep = "STRING" },
		Category = "Restrictions",
	})
	
--[[ -----------------------------------
		STOOLS
     ----------------------------------- ]]
	function PLUGIN:AllowStool( owner, rank, stool )
		return self:AllowObject( owner, rank, "stools", stool )
	end
	PLUGIN:AddCommand( "allowstool", {
		Call = PLUGIN.AllowStool,
		Desc = "Allows users to remove disallowed stools from a rank.",
		Console = { "allowstool" },
		Chat = { "!allowstool" },
		ReturnOrder = "Rank-Stool",
		Args = { Rank = "STRING", Stool = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:DenyStool( owner, rank, stool )
		return self:DenyObject( owner, rank, "stools", stool )
	end
	PLUGIN:AddCommand( "denystool", {
		Call = PLUGIN.DenyStool,
		Desc = "Allows users to deny stools to ranks.",
		Console = { "denystool" },
		Chat = { "!denystool" },
		ReturnOrder = "Rank-Stool",
		Args = { Rank = "STRING", Stool = "STRING" },
		Category = "Restrictions",
	})
	
	function PLUGIN:PrintRestrictions( owner )
		
		owner:Print( exsto_CLIENT, "--- Rank Restriction Data ---\n" )
		
		for k,v in pairs( self.Restrictions ) do
			owner:Print( exsto_CLIENT_NOLOGO, " Rank: " .. k )
			
			owner:Print( exsto_CLIENT_NOLOGO, "    ** Props: " )
			for _, prop in ipairs( v.Props ) do
				owner:Print( exsto_CLIENT_NOLOGO, "       -- " .. prop )
			end
			
			owner:Print( exsto_CLIENT_NOLOGO, "    ** Entities: " )
			for _, ent in ipairs( v.Entities ) do
				owner:Print( exsto_CLIENT_NOLOGO, "       -- " .. ent )
			end
			
			owner:Print( exsto_CLIENT_NOLOGO, "    ** Sweps: " )
			for _, swep in ipairs( v.Sweps ) do
				owner:Print( exsto_CLIENT_NOLOGO, "       -- " .. swep )
			end
			
			owner:Print( exsto_CLIENT_NOLOGO, "    ** Stools: " )
			for _, stool in ipairs( v.Stools ) do
				owner:Print( exsto_CLIENT_NOLOGO, "       -- " .. stool )
			end
			
			owner:Print( exsto_CLIENT_NOLOGO, "\n" )
		end
		
		owner:Print( exsto_CLIENT, "--- End of Restriction Data Print ---\n" )
		
		return { owner, COLOR.NORM, "All rank restrictions have been printed to your ", COLOR.NAME, "console", COLOR.NORM, "!" }
	
	end
	PLUGIN:AddCommand( "printrestrict", {
		Call = PLUGIN.PrintRestrictions,
		Desc = "Allows users to print rank restrictions.",
		Console = { "restrictions" },
		Chat = { "!restrictions" },
		Args = { },
		Category = "Restrictions",
	})

elseif CLIENT then

	function PLUGIN.RecieveRestrictions( data )
		PLUGIN.Restrictions = data
	end
	//exsto.UMHook( "ExRecRestrict", PLUGIN.RecieveRestrictions )
	
	function PLUGIN.Build()
	end

	function PLUGIN.Reload( panel )
		PLUGIN.Restrictions = {}
		RunConsoleCommand( "_SendRestrictions" )	
	end

	--[[
	Menu.CreatePage( {
		Title = "Rank Restrictor",
		Short = "rankrestrictions",
		Flag = "rankrestrictions",
		}, 
		function( panel )
			PLUGIN.Reload( panel )
		end
	)]]
	
end

PLUGIN:Register()
