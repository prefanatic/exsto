local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Server Review",
	ID = "srvreview",
	Desc = "Lets users let you know what should be changed on the server.",
	Owner = "Prefanatic",
} )

function PLUGIN:Init()
	file.CreateDir( "exsto/reviews" )
end

function PLUGIN:AddReview( owner, str )
	local date = os.date( "%m-%d-%y" )
	local time = tostring( os.date( "%H:%M:%S" ) )
	
	file.Write( "exsto/reviews/" .. owner:Nick() .. " " .. date .. ".txt", "[" .. time .. "]" .. str )
	
	return { COLOR.NORM, "Review added.  ", COLOR.NAME, "Thanks!" }
end
PLUGIN:AddCommand( "review", {
	Call = PLUGIN.AddReview,
	Desc = "Allows users to put their 2cents in on the server.",
	Console = { "review" },
	Chat = { "!review" },
	ReturnOrder = "Message",
	Args = { Message = "STRING" },
	Category = "Misc",
})

PLUGIN:Register()