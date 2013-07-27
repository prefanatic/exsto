local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Vote Map",
	ID = "votemap",
	Desc = "Allows clients to vote on maps.",
	Owner = "Prefanatic",
} )

function PLUGIN:StartVotemap( caller )
	local percent = self.StartThreshold:GetValue()
	if not self.Threshold then self.Threshold = {} end
	
	table.insert( self.Threshold, caller )
	
	if percent == 0 or math.floor( ( #self.Threshold / #player.GetAll() ) * 100 )  >= percent then
		self:Votemap()
		self.Threshold = {}
		return
	end
	
	-- Calculate how many people are needed to start.
	local needed = math.floor( #player.GetAll() / percent )
	exsto.Print( exsto_CHAT_ALL, COLOR.NAME, tostring( needed ), COLOR.NORM, " more players needed to ", COLOR.NAME, "!votemap." )
end
PLUGIN:AddCommand( "votemap", {
	Call = PLUGIN.StartVotemap,
	Desc = "Calls the votemap process.",
	Console = { "votemap" },
	Chat = { "!votemap" },
	Category = "Voting",
})

function PLUGIN:Votemap()
	self:Print( "Starting votemap..." )
	
	exsto.VotemapDB:GetAll( function( q, dt )
		-- Quick thing to make the sorting easier later on
		dt = dt or {}
		
		-- Store this data for later.
		self.LocalStorage = dt
		
		local tmp = {}
		for _, data in ipairs( dt ) do
			tmp[ data.Map ] = data.Played
		end	
		dt = tmp
		
		-- Lets get our map list from sh_restart, because Exsto is awwweeesome <3
		local rstart = exsto.GetPlugin( "restart-changelvl" )
		if !rstart then	self:Print( "Andddd we can't find our restart plugin.  Uh oh!  But this should never happen." ) return end
		
		local maplist = table.Copy( rstart.MapList )
		local lst = {}
		
		-- Clean the map list and only let ttt maps go through.
		for map, data in pairs( maplist ) do
			if data.Category:lower():find( self.Filter:GetValue() ) then 
				table.insert( lst, map ) 
				if !dt[ map ] then dt[ map ] = 0 end
			end
		end
		
		-- Now, we need to put the highest played maps on top.  Sort this thing by the count in exsto.VotemapDB.
		table.sort( lst, function( a, b ) return dt[ a ] > dt[ b ] end )
		
		-- We should have a proper sorted table, with the most played maps closer to 0 on the index.  Push the vote!
		local vote = exsto.GetPlugin( "votefuncs" )
		if !vote then self:Print( "Couldn't find the vote API.  This shouldn't ever happen." ) return end
		
		vote:Vote( "votemap", "Next map!", lst, self.Timeout:GetValue(), "large" )
		self.MapList = lst
	end )
end

function PLUGIN:ExVoteFinished( data )
	if data.ID == "votemap" then -- Make sure this is ours to use.
		-- Check and make sure people voted...
		if data.Won == -1 then -- Fuck
			-- Just set up some random map to go to.
			data.Won = math.random( 1, #self.MapList )
		end
		
		local map = self.MapList[ data.Won ]

		local count = 0
		for _, d in ipairs( self.LocalStorage ) do
			if map == d.Map then count = d.Played end
		end
		
		-- Throw this into the statisitcs table
		exsto.VotemapDB:AddRow( {
			Map = map;
			Played = count + 1;
		} )
		
		-- Now restart.
		local rstart = exsto.GetPlugin( "restart-changelvl" )
		if !rstart then	self:Print( "Andddd we can't find our restart plugin.  Uh oh!  But this should never happen." ) return end
		
		rstart:ChangeLevel( "Console", map, 3, "current" )
		self:Print( exsto_CHAT_ALL, 
			COLOR.NORM, "Changing level to ",
			COLOR.NAME, map:gsub( "%.bsp", "" ),
			COLOR.NORM, " in ",
			COLOR.NAME, tostring( 3 ),
			COLOR.NORM, " seconds!"
		)
	end
end

function PLUGIN:Init()
	self.Timeout = exsto.CreateVariable( "ExVotemapTimeout", "Votemap timeout", 30, "How long the votemap has until it is done polling for votes." )
		self.Timeout:SetMinimum( 0 )
		self.Timeout:SetCategory( "Votes" )
		self.Timeout:SetUnit( "Time (seconds)" )
		
	self.StartThreshold = exsto.CreateVariable( "ExVotemapThreshold", "Start Threshold", 66, "In order for !votemap to start, the number of players that call !votemap needs to be above this percentage treshold.  Set to 0 disable." )
		self.StartThreshold:SetMinimum( 0 )
		self.StartThreshold:SetMaximum( 100 )
		self.StartThreshold:SetUnit( "Players (%)" )
		self.StartThreshold:SetCategory( "Votes" )
		
	self.Filter = exsto.CreateVariable( "ExVotemapFilter", "Filter", "", "Filter map by category.  For example, if you only want to vote Terror Town maps, put in 'trouble'" )
		self.Filter:SetCategory( "Votes" )
	
	-- Purely for statistical purposes.  Votemap also puts the most played above everything else in the list.
	exsto.VotemapDB = FEL.CreateDatabase( "exsto_plugin_votemap" )
		exsto.VotemapDB:SetDisplayName( "Votemap Statistics" )
		exsto.VotemapDB:ConstructColumns( {
			Map = "VARCHAR(255):primary:not_null";
			Played = "INTEGER";
		} )
end

PLUGIN:Register()



