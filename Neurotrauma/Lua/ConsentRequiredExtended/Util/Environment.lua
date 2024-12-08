-- Functions for managing the mod's environment.

---Isolate a function or module's environment from Global.
---@param env table The _ENV table.
local function prepareEnvironment(env)
	return setmetatable({}, {
		__index = _G,
	})
end

local _ENV = prepareEnvironment(_ENV)

PrepareEnvironment = prepareEnvironment

---Create an empty table whose metatable indexes non-local variables declared within
---a function/module's environment, and is immutable to any changes.
---@param env table The _ENV table.
---@return table Empty table that interfaces with _ENV.
function Export(env)
	return setmetatable({}, {
		__index = function(t, k)
			return env[k]
		end,
		__newindex = function()
			error("Attempted to modify a protected table.")
		end,
	})
end

return Export(_ENV)
