--[[
	Exsto
	Copyright (C) 2013  Prefanatic

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

-- Helper function
local count = 0
local function enum()
	count = count + 1
	return count;
end

--[[ -----------------------------------
	Rank Error Enumerators
	----------------------------------- ]]
ALOADER_SELF_PARENT = enum();  -- Parenting off themself.
ALOADER_INVALID_PARENT = enum(); -- Non-existant parent.
ALOADER_ENDLESS = enum(); -- Endless derive.
ALOADER_NO_IMMUNITY = enum();
ALOADER_VON_FAILURE_COLOR = enum();
ALOADER_VON_FAILURE_FLAGS = enum();

--[[ -----------------------------------
	Animations
	----------------------------------- ]]
ANIM_BLIND_UP = enum();
ANIM_POP_UP = enum();

--[[ -----------------------------------
	Command Types
	----------------------------------- ]]
COMMAND_STRING = enum();
COMMAND_PLAYER = enum();
COMMAND_NUMBER = enum();
COMMAND_BOOL = enum();
COMMAND_BOOLEAN = COMMAND_BOOL

--[[ -----------------------------------
	Misc
	----------------------------------- ]]
EX_DEVELOPMENT = "devlopment";