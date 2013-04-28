-- Exsto
-- Documentary Plugin / Skeleton Plugin

local PLUGIN = exsto.CreatePlugin() -- First, we need to create the PLUGIN metatable.  This allows us to perform actions on the plugin itself.

--[[ Before we start coding, we need to setup our plugin information.  Without this, our plugin won't work properly.  Here is a list of arguments for PLUGIN:SetInfo()
	
	Name - The display name we want for our plugin.  This is displayed in formatted information panels.
	ID - The short identifier that allows Exsto to organize the plugin.  It should contain now spaces, and all lowercase.
	Desc - The description should be a breif plugin of what this plugin does for Exsto.
	Owner - Credit to the writer of the plugin
	Experimental - Set to true if this plugin isn't complete, or is experimental.
	Enabled - Set this to true if you don't want this plugin to be run, even when checked off through Exsto.
	
	Things like Description and Experimental are optional, Exsto can fill in them if you do not provide a value for it.
]]

PLUGIN:SetInfo({
	Name = "Skeleton Plugin",
	ID = "skeleton",
	Desc = "A plugin that is a documentary!",
	Owner = "Prefanatic",
	Disabled = true,
} )

if SERVER then

	--[[ Exsto has support for real time variables, that can be changed while the game is in progress.
	This allows server admins to disable or change some features of Exsto, without editing core systems.
	To create a variable, you can use PLUGIN:AddVariable.  Here are the arguments it requires, in table format.
	
	Pretty - The display name for the variable.
	Dirty - The ID to help Exsto organize the variable.
	Default - The default value the variable provides.
	Description - The short summary on what this variable is.
	Possible - A table value of all possible values this variable can provide.
	OnChange - A function that can be called on the event of the variable being changed in value.
	
	Description, Possible, and OnChange are all optional arguments.
	]]
	PLUGIN:AddVariable({
		Pretty = "Skeleton Type",
		Dirty = "skel-type",
		Default = "Add",
		Description = "This variable changes weither the skeleton command will add or subtract numbers.",
		Possible = { "Add", "Subtract" }
	})
	
	--[[ Exsto contains a very powerful data saving system called FEL (File Exstension Library)
	FEL allows developers to save in MySQL, or SQLite, depending on what the server owner has set in FEL's settings.
	FEL automates hard processes on developers, so they do not need to learn SQL syntax, or redundant checking.
	To create a table in FEL, you can run PLUGIN:CreateTable, with these table arguments.
	
	Name - The name of the table
	{
		Column_Name = dataType
	}
	
	You may have an infinite number of items inside the second table argument.
	]]
	PLUGIN:CreateTable( "exsto_data_skeleton", {
		Name = "text",
		Number = "int",
	})

	--[[ Exsto contains a very, very powerful command system that works in both chat and console.
	With the Exsto command system, you can declare multiple chat commands, and console commands, that point to the same function.
	Also, you can request specific arguments that is required to be passed into the function, as well as optionals if they do not exist.
	If no optional is set, and an argument isnt provded, Exsto automatically manages the responce of a missing argument.
	]]
	
	function PLUGIN:Skeleton( owner, number, extra ) -- Our function name, please keep it in PLUGIN for development purposes.
		
		-- Lets perform some actions.
		--[[ exsto.Print allows a wide range of printing commands to a number of different people, and styles.
		If a developer wants to print an error, they can just do exsto.Print( exsto_ERROR, errorMsg ).
		The arguments of exsto.Print varies depending on what style of message they are printing, here is a list of styles, and their arguments.
			
			Arguments around * * are required.  Arguments within [ ] can be repeated as much as possible.
			
			exsto_CHAT -- *player*, [string OR color table]
			exsto_CHAT_LOGO -- *player*, [string OR color table] (displays the Exsto logo at start)
			exsto_CHAT_ALL -- [string OR color table] (sends to all clients)
			exsto_CHAT_ALL_LOGO -- [string OR color table] (sends to all clients and displays logo)
			
			exsto_CONSOLE -- string (prints to the server console)
			
			exsto_ERROR -- string (involks error and sends error to superadmins)
			exsto_ERRORNOHALT -- string (involks error and sends error to superadmins)
			
			exsto_CLIENT -- *player*, string (normal print)
			exsto_CLIENT_LOGO -- *player, string (displays logo)
			exsto_CLIENT_ALL -- string (sends to all players)
			exsto_CLIENT_ALL_LOGO -- string (sends to all players and displays logo)
		]]
		
		-- Right here, we are sending a chat message to the command involker, with "We are adding " the number " to " the other number.
		local type = "adding "
		
		-- In other admin mods, chat commands come back with a table argument, and all the arguments are *most likely* a string.
		-- Exsto automatically converts the data type into the format the command requests in the exsto.AddChatCommand function.
		-- This way, we don't need to worry about converting the numbers ourselves, which leaves us more time to code amazing stuff.
		local num = number + extra
		
		-- Lets see if our variable changed.  Right here, we put a check to find out what value our Skeleton variable is.
		-- exsto.GetVar requires the first argument to be the Dirty.  It returns a table value of the variable, where we can get the value.
		if exsto.GetVar( "skel-type" ).Value == "Subtract" then 
			type = "subtracting "
			num = number - extra
		end
		
		-- You can also use metatable printing with Exsto.  owner:Print( exsto_CHAT, COLOR.NORM, ... )
		exsto.Print( exsto_CHAT, owner, COLOR.NORM, "We are " .. type, COLOR.NAME, number, COLOR.NORM, " to ", COLOR.NAME, extra )
	
		-- Remember that FEL table we made?  Lets save this new number into that database.  All we need to do, is run FEL.AddData.
		FEL.AddData( "exsto_data_skeleton", { -- First argument is the table name, that we created up near the top of the plugin.
			Look = { -- The data we want to look for if it already exists.  If it exists, FEL automatically updates the data with the new data.
				Name = ply:Nick(), -- If the column "Name" has a value of your nick, then it will update the number in that column.
			},
			Data = { -- The data we want to insert.
				Name = ply:Nick(), -- Don't forget to insert his name.
				Number = num, -- Add this data into the number column!
			},
			Options = {
				Update = true, -- Makes it so we update if the data exists.
				Threaded = true, -- Makes it so we thread if on mysqloo.
			}
		})			

		-- This may look weird, but Exsto supports return printing.  This way, plugins can return a message, instead of using exsto.Print.
		-- If no player argument is supplied for the first return value in the return table, it prints to all clients.
		-- If a player argument is supplied, it only prints to that player, just like exsto.Print( exsto_CHAT, owner, "Hey" )
		return { owner, COLOR.NORM, "The equation equals ", COLOR.NAME, num }
		
	end
	--[[
		Here is where the awesome coding comes in.  This function allows you as the developer to not worry about anything, other than your plugin.
		EVERYTHING is handled by Exsto that involves command and chat parsing.  Automatically converting values, notifying players, the works.
		The first argument of PLUGIN:AddCommand is the ID of the plugin, the second is the table filled with information.
	]]
	PLUGIN:AddCommand( "skeleton", { -- Don't forget to do this ID here.
		Call = PLUGIN.Skeleton, -- The function you want to call.
		Desc = "Shows you how to format this.", -- A summary of what this command does.  It helps players who use it figure out what commands they need
		Console = { "skeleton" }, -- A table of console commands the user can say to call this function.
		Chat = { "!skeleton" }, -- A table of chat commands the user can say to call this function.
		ReturnOrder = "Number-Extra", -- The order you want your arguments to be returned as.
		Args = {Number = "NUMBER", Extra = "NUMBER"}, -- The arguments you require.  The current types are PLAYER, NUMBER, BOOLEAN, and STRING.
		Optional = {Extra = 10}, -- A table with the optionals you want to add in if the player doesn't give enough info.  This should correspond with your Arguments.
	})
	
	--[[
		With the new Exsto Plugin Library, you can now have plugins that hook into gamemode functions, with no need for extra work!
		For example, if we want to hook into PlayerJoin, we would just do this. ]]
	function PLUGIN:PlayerJoin( ply )
		print( "Hello " .. ply:Nick() .. "!" )
	end
	
elseif CLIENT then

	-- This is the menu create function, which allows plugins to create their own specialized page in the Exsto menu.
	-- With this, it would be just like creating a frame, but included with Exsto.
	-- Exsto provides a ton of *ease of use* functions to automatically speed up development of Derma in Exsto.
	-- These functions are in cl_derma.lua, where you should take a look to see what functions can do what.
	-- Also, each derma object in Exsto is automatically painted to take on the Exsto theme, so you don't need to worry about yours standing out.
	--[[Menu:CreatePage( {
		Title = "Skeleton Stuff", -- The title of the page
		Short = "skeletonpage", -- The short ID
		Flag = "skeletonpage"}, -- The flag you wish players to have to view your panel.
		function( panel ) -- The function that is run to create your panel.  You put all stuff in here.
		
		end )]]

end

-- Finally, we need to tell Exsto that we exist, otherwise, we won't be properly loaded.
PLUGIN:Register()
