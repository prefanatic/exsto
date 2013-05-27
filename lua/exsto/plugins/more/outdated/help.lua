-- Exsto
-- Help Menu

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Help Menu",
	ID = "helpmenu",
	Desc = "A menu panel that shows Exsto help",
	Owner = "Prefanatic",
	Clientside = true,
} )

function PLUGIN:Init()
	-- Variables.
	self.DropLink = "http://dl.dropbox.com/u/717734/Exsto/DO%20NOT%20DELETE/Help/"
	self.DatabaseLink = self.DropLink .. "helpdb.txt"
	
	self.DatabaseConstruct = {}
	self.DatabaseLoading = true
	self.DatabaseRecieved = false
	self.DatabaseVersion = 1.0

	-- Grab the database list.
	http.Fetch( self.DatabaseLink, function( contents, size )
		if size == 0 or contents:Trim() == "" then
			self:Print( "Unable to retrieve database." )
			self.DatabaseRecieved = false
			self.DatabaseLoading = false
			return
		end
		
		local verStart, verEnd, version = string.find( contents, "%[helpver=(%d%.%d)%]" )
		if !verStart or !verEnd or !version then
			self:Print( "Unable to read version header." )
			self.DatabaseRecieved = false
			self.DatabaseLoading = false
			return
		end
		
		self.DatabaseVersion = tonumber( version )
		self:Print( "Recieved help list.  Constructing menu data.  Version: " .. self.DatabaseVersion  )
		
		-- Loop through our categories.
		local capture = string.gmatch( contents, "%[cat=\"(%a+)\"%](.-)%[/cat%]" )
		for category, data in capture do
			local files = string.match( data, "Files = {(.-)}" )
			self.DatabaseConstruct[ category:Trim() ] = string.Explode( ",", files:gsub( "\"", "" ) )
		end

		self.DatabaseLoading = false
		self.DatabaseRecieved = true
	end )
	
end

function PLUGIN:CreateHTML( url )
	--background-image:url( "]] .. self.DropLink .. "background.png" .. [[" );
	return [[
		<html>
			<head>
				<style type="text/css">
					body{
						padding:0px 0px 0px 0px;
						margin:0px 0px 0px 0px;
					}
					.image{
						width:565px;
						height:280px;
					}
				</style>
			</head>
			<body>
				<center><img src="]] .. url .. [[" alt="image1" /></center>
			</body>
		</html>
	]]
end

function PLUGIN:Reset( panel, pages )
	self.Pics = pages
	
	panel.CurrentIndex = 1
	self.browser:SetHTML( self:CreateHTML( self.DropLink .. pages[ panel.CurrentIndex ] ) )
	--self.browser:SetVisible( false )
	--panel:PushLoad()

	panel.Prev:SetVisible( false )
	panel.Next:SetVisible( false )
	if #pages > 1 then
		panel.Next:SetVisible( true )
	end
end

function PLUGIN:CreatePage( panel )
	local tabs = panel:RequestTabs()
	
	-- Sort them.
	local newTable = {}
	for category, pictures in pairs( self.DatabaseConstruct ) do
		table.insert( newTable, { Category = category, Pics = pictures } )
	end
	
	table.sort( newTable, function( a, b ) return a.Category == "Introduction" or a.Category > b.Category end )
	
	local function waitOnFinish( html, url )
		html:SetVisible( true )
		panel:EndLoad()
	end
	
	panel.CurrentIndex = 1
	
	-- Create the HTML thing.  Thank you WebKit.
	self.browser = vgui.Create( "DHTML", panel )
		//self.browser:SetHTML( self:CreateHTML( self.DropLink .. self.Pics[1] ) )
		self.browser:SetSize( 595, 305 )
		self.browser:SetPos( ( panel:GetWide() / 2 ) - ( self.browser:GetWide() / 2 ), 5 )
		
		self.browser:SetMouseInputEnabled( false )
		self.browser.FinishedURL = waitOnFinish
		
	-- Create prev and next buttons.
	panel.Prev = exsto.CreateButton( 15, panel:GetTall() - 40, 84, 27, "Previous", panel )
		panel.Prev:SetStyle( "negative" )
		panel.Prev:SetVisible( false )
		
		panel.Prev.OnClick = function()
			if panel.CurrentIndex == 1 then return end
			
			panel.CurrentIndex = panel.CurrentIndex - 1
			self.browser:SetHTML( self:CreateHTML( self.DropLink .. self.Pics[ panel.CurrentIndex ] ) )
			--self.browser:SetVisible( false )
			--panel:PushLoad()
			
			panel.Next:SetVisible( true )
			if panel.CurrentIndex == 1 then panel.Prev:SetVisible( false ) end
		end

	panel.Next = exsto.CreateButton( panel:GetWide() - 74 - 15,panel:GetTall() - 40, 74, 27, "Next", panel )
		panel.Next:SetStyle( "positive" )
		
		panel.Next.OnClick = function()
			if panel.CurrentIndex == #self.Pics then return end
			
			panel.CurrentIndex = panel.CurrentIndex + 1
			self.browser:SetHTML( self:CreateHTML( self.DropLink .. self.Pics[ panel.CurrentIndex ] ) )
			--self.browser:SetVisible( false )
			--panel:PushLoad()
			
			panel.Prev:SetVisible( true )
			if panel.CurrentIndex == #self.Pics then panel.Next:SetVisible( false ) end
		end
		
	for _, data in ipairs( newTable ) do
		tabs:CreateButton( data.Category, function() self:Reset( panel, data.Pics ) end )
	end
	
end	
	
Menu:CreatePage({
		Title = "Exsto Help",
		Short = "helppage",
	}, function( panel )
		PLUGIN:CreatePage( panel )
	end )
	
PLUGIN:Register()
