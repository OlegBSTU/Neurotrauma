---@class NTTypes.Affliction Affliction object
---@field id string|nil ID in xml
---@field max number maximum value. Default is 100
---@field min number minimum value. Default is 0
---@field default number base value. Default is 0
---@field update function|nil update function. Default is nil
---@field apply function|nil add function? Default is nil
---@field lateupdate function|nil late update function. Default is nil
NTTypes.Affliction = { id = nil, max = 100, min = 0, default = 0, update = nil, apply = nil, lateupdate = nil }
NTTypes.Affliction.__index = NTTypes.Affliction

---Конструктор нового афликта
---@param id string ID in xml
---@param max number|nil maximum value. Default is 100
---@param min number|nil minimum value. Default is 0
---@param default number|nil base value. Default is 0
---@param update_func function|nil update function. Default is nil
---@param apply_func function|nil add function? Default is nil
---@param lateupdate_fucn function|nil late update function. Default is nil
---@return NTTypes.Affliction
NTTypes.Affliction.new = function(id, max, min, default, update_func, apply_func, lateupdate_fucn)
	local self = setmetatable({}, NTTypes.Affliction)
	self.id = id

	if max then
		self.max = max
	end

	if min then
		self.min = min
	end

	if default then
		self.default = default
	end

	if update_func ~= nil then
		self.update = update_func
	end

	if apply_func ~= nil then
		self.apply = apply_func
	end

	if lateupdate_fucn ~= nil then
		self.lateupdate = lateupdate_fucn
	end

	return self
end
