 -- Exsto
 -- Testing Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Testing",
	ID = "test",
	Desc = "A plugin that throws Exsto through its paces.",
	Owner = "Prefanatic",
} )

PLUGIN.Tests = {}
PLUGIN.Queue = {}
PLUGIN.Errors = {}
PLUGIN.RunningTest = false
PLUGIN.Caller = nil

function PLUGIN:CreateTest( name, id, func )
	table.insert( self.Tests, { Name = name, ID = id, Func = func } )
end

local function CommandTest( caller )

	-- Random selection of commands
	local coms = {
		"!god",
		"!god",
		"!slap",
		"!whip pre 10 8 0.01",
		"!version",
		"!rank",
		"!updateowner",
		"!goto",
		"!bring",
		"!send", -- Purpose Error.
		"!stripweps",
		"!returnweps", 
		"!admin \"And god shall smite thee!\"",
		"@@ \"Living in Exsto...\"",
		"!getvariable native_exsto_colors",
		"!health pre 1000",
		"!armor pre 100",
		"!ignite",
		"!rocket",
		"!gimp",
		"I like chicken pie.",
		"!gimp",
		"Whoa, no gimping.",
	}
	
	local finished = false
	local function queue()
		
		if table.Count( coms ) == 0 then finished = true end
		
		caller:ConCommand( "say " .. coms[1] )
		
		table.remove( coms, 1 )
		timer.Simple( 1, queue )
	end
	queue()
	
	return true
	
end
PLUGIN:CreateTest( "Command Test", "commands", CommandTest )

local function OnJoinStress( caller )

	exsto.IgnorePrints( true )

	local makeBot = function()
		game.ConsoleCommand( "bot\n" )
	end
	
	local count = 1

	local function loop()
	
		count = count + 1
	
		debug.sethook()
	
		makeBot()
		
		for k,v in pairs( player.GetAll() ) do
			if v:IsBot() then v:Kick( "BYE" ) end
		end
		
		if count < 70 then timer.Simple( 0.05, loop ) end
		
	end
	loop()
	
	exsto.IgnorePrints( false )
	
	return true
	
end
PLUGIN:CreateTest( "OnJoin Stress", "onjoin", OnJoinStress )

local function PrintTest( caller )

	for k,v in pairs( exsto.PrintStyles ) do
		
		local data = true
		
		-- Test if he can do a meta test.
		if v.meta then
			data = caller:Print( v.enum, "Testing Exsto Printing Utils" )
		else
			data = exsto.Print( v.enum, "Testing Exsto Printing Utils" )
		end
		
		if !data then return false, "Errored out on caller enum " .. v.enum end
		
	end
	
	return true
	
end
PLUGIN:CreateTest( "Printing Test", "print", PrintTest )

local function TestFEL( caller )

	-- Putting FEL through it's paces.  Lets start off with creating a table.
	FEL.MakeTable( "exsto_test_loop", {
		Player = "varchar(255)",
		SteamID = "varchar(255)",
		Int = "int",
	} )
	
	-- Should be saved, lets try adding data into it.
	FEL.AddData( "exsto_test_loop", {
		Look = {
			SteamID = caller:SteamID(),
		}, 
		Data = {
			Player = caller:Nick(),
			SteamID = caller:SteamID(),
			Int = math.random( -100000, 100000 ),
		}
	} )
	
	-- Lets load that data up and return it
	local int = FEL.LoadData( "exsto_test_loop", "Int", "SteamID", caller:SteamID() )
	
	if !tostring( int ) then return false, "Errored out on loading Int from FEL table" end
	
	caller:Print( exsto_CHAT, COLOR.NORM, "Return value is ", COLOR.NAME, int, COLOR.NORM, "!" )
	
	-- Delete the table, then try to load from it again.
	FEL.Query( "DROP TABLE exsto_test_loop;" )
	
	local int = FEL.LoadData( "exsto_test_loop", "Int", "SteamID", caller:SteamID() )
	
	if !tostring( int ) then return true end
	
end
PLUGIN:CreateTest( "FEL Debug", "fel", TestFEL )

function PLUGIN:Think()

	if table.Count( self.Queue ) >= 1 and !self.RunningTest then

		self.RunningTest = true
		local success, err = pcall( self.Queue[1].Func, self.Caller )
		
		if !success then
			table.insert( self.Errors, { ID = self.Queue[1].ID, Err = err } )
		else
			self.Caller:Print( exsto_CHAT, COLOR.NORM, "Success!  Test ", COLOR.NAME, self.Queue[1].Name, COLOR.NORM, " has completed with no errors!" )
		end
		
		if table.Count( self.Queue ) == 1 then	
			self.Caller:Print( exsto_CHAT, COLOR.NORM, "Completed all tests!" )
			
			if table.Count( self.Errors ) == 0 then
				self.Caller = nil
			end
		end
		
		timer.Simple( 2, function() self.RunningTest = false table.remove( self.Queue, 1 ) end )
	elseif table.Count( self.Queue ) == 0 and table.Count( self.Errors ) >= 1 then
	
		self.Caller:Print( exsto_CHAT, COLOR.NORM, "Test ", COLOR.NAME, self.Errors[1].ID, COLOR.NORM, " has failed!  Printing error to console." )
		self.Caller:Print( exsto_CLIENT, self.Errors[1].Err )
		
		if table.Count( self.Errors ) == 1 then
			self.Caller = nil
		end
		
		table.remove( self.Errors, 1 )
		
	end
	
end

function PLUGIN:RunTest( caller, all )

	if self.Caller then return { caller, COLOR.NORM, "There already is active tests running!" } end

	self.Caller = caller

	if all == "all" then self.Queue = table.Copy( self.Tests ) return { caller, COLOR.NORM, "Running ", COLOR.NAME, "tests", COLOR.NORM, "!" } end
	
	for k,v in pairs( self.Tests ) do
		if v.ID == all then
			table.insert( self.Queue, v )
			return { caller, COLOR.NORM, "Running test ", COLOR.NAME, v.Name, COLOR.NORM, "!" }
		end
	end
	
	self.Caller = nil
	return { caller, COLOR.NORM, "Could not find a test named ", COLOR.NAME, all, COLOR.NORM, "!" }
	
end
PLUGIN:AddCommand( "runtest", {
	Call = PLUGIN.RunTest,
	Desc = "Throws Exsto through its paces.",
	Console = { "stress_test" },
	Chat = { "!test" },
	ReturnOrder = "All",
	Args = { All = "STRING" },
	Optional = { All = "all" }
})

PLUGIN:Register()
