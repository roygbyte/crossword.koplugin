local DataStorage = require("datastorage")
local LuaSettings = require("frontend/luasettings")
local logger = require("logger")

local State = {
    state_file = "crossword_states.lua",
    lua_settings = nil,
}

function State:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o:init()
    return o
end

function State:init()
    self.lua_settings = LuaSettings:open(("%s/%s"):format(DataStorage:getSettingsDir(), self.state_file))
end

function State:load()
    local state = self.lua_settings:child(self.id)
    for key, value in pairs(state.data) do
        self[key] = value
    end
end

function State:save()
    self.lua_settings:saveSetting(self.id, self)
    self.lua_settings:flush()
end

return State
