local PLUGIN = exsto.CreatePlugin() 

PLUGIN:SetInfo({ 
	 Name = "MOTD", 
	 ID = "motd", 
	 Desc = "Provides MOTD functionality", 
	 Owner = "Prefanatic", 
	 CleanUnload = true,
} ) 

if SERVER then

	function PLUGIN:Init()
		self.JoinEnabled = exsto.CreateVariable( "ExMOTDJoinEnabled", "Enabled", 0, "Automatically opens the MOTD on player join." )
			self.JoinEnabled:SetBoolean()
			self.JoinEnabled:SetCategory( "MOTD" )
			
		local function parse( old, new )
			local exp = string.Explode( ":", new )
			if exp[ 1 ] == "file" then
				self.MOTDData = file.Read( "data/" .. exp[ 2 ], "GAME" )
				self.MOTDFile = true
			else
				self.MOTDData = new
				self.MOTDFile = false
			end
		end
		
		self.MOTDContent = exsto.CreateVariable( "ExMOTDLocation", "Location", "file:exsto/motd.txt", "The location of the MOTD.  You can either specify an HTTP link or a file location.  If using a file, please append file: at the beginning, like file:exsto/motd.txt" )
			self.MOTDContent:SetCategory( "MOTD" )
			self.MOTDContent:SetCallback( parse )
			
		parse( nil, self.MOTDContent:GetValue() )

		util.AddNetworkString( "ExOpenMOTD" )
		
	end
	
	function PLUGIN:PushMOTD( ply )
		self:Debug( "Pushing MOTD open to '" .. ply:Nick() .. "'", 2 )
		local sender = exsto.CreateSender( "ExOpenMOTD", ply )
			sender:AddString( self.MOTDData )
			sender:AddBool( self.MOTDFile )
		sender:Send()
	end
	
	function PLUGIN:ExInitSpawn( ply )
		if self.JoinEnabled:GetValue() == 1 then
			self:PushMOTD( ply )
		end
	end
	
	function PLUGIN:OpenMOTD( caller )
		self:PushMOTD( caller )
	end
	PLUGIN:AddCommand( "motd", { 
		Call = PLUGIN.OpenMOTD, 
		Desc = "Opens the MOTD", 
		Console = { "motd" }, 
		Chat = { "!motd" }, 
		Category = "Fun", 
	}) 

else

	function PLUGIN:Init()
		-- Create our MOTD VGUI
		
		self.Frame = vgui.Create( "DFrame" )
			self.Frame:SetSize( ScrW() - 200, ScrH() - 200 )
			self.Frame:SetPos( 100, 100 )
			self.Frame:DockPadding( 8, 8, 8, 52 )
			self.Frame:SetSkin( "Exsto" )
			self.Frame:SetTitle( "" )
			self.Frame:ShowCloseButton( false )
			self.Frame:SetDeleteOnClose( false )
			self.Frame:MakePopup()
			self.Frame:SetVisible( false )
			
		exsto.Animations.Create( self.Frame )
			
		self.HTML = vgui.Create( "DHTML", self.Frame )
			self.HTML:Dock( FILL )
			
		self.Close = vgui.Create( "ExButton", self.Frame )
			self.Close:SetSize( 100, 40 )
			self.Close:Text( "Close" )
			self.Close:SetPos( ( self.Frame:GetWide() / 2 ) - 50, self.Frame:GetTall() - 48 )
			self.Close.OnClick = function( s ) self.Frame:Close() end
		
	end
	
	function PLUGIN:OnUnload()
		self.Frame:Remove()
	end
	
	function PLUGIN:OpenMOTD( reader )
		if not IsValid( self.Frame ) then self:Init() end
		
		local content = reader:ReadString()
		local f = reader:ReadBool()

		if f then
			self.HTML:SetHTML( content )
		else
			self.HTML:OpenURL( content )
		end
		
		self.Frame:MakePopup()
		self.Frame:SetVisible( true )
		
		local x, y = self.Frame:GetPos()
		
		self.Frame:ForcePos( x, y + 100 )
		self.Frame:SetPos( x, y )
	end
	PLUGIN:CreateReader( "ExOpenMOTD", PLUGIN.OpenMOTD )

end

PLUGIN:Register()