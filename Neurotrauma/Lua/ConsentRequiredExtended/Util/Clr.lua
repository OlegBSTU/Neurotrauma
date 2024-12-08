-- Functions for working with CLR types.

local Environment = require("ConsentRequiredExtended.Util.Environment")
local _ENV = Environment.PrepareEnvironment(_ENV)

local UserData = require("ConsentRequiredExtended.Util.UserData")

---Construct ClrType wrapper table for CLR types.
---@param underlyingType userdata The underlying type (CLR type: System.Type).
---@return ClrType Wrapper table for working with CLR types.
local function New(underlyingType)
	---@class ClrType
	local clrType = {}

	---Instantiate an object for the given CLR type.
	---@return any An instance of the CLR type. Actual Lua type depends on MoonSharp conversions.
	function clrType:Instantiate()
		-- TODO: Implement args.
		return underlyingType.Assembly.CreateInstance(underlyingType.FullName)
	end

	---Get the underlying type as a raw CLR type object.
	---@return userdata The raw underlying type (CLR type: System.Type).
	function clrType:GetUnderlyingType()
		return underlyingType
	end

	---Get the full name of the CLR type.
	---@return string The full name of the type.
	function clrType:GetFullName()
		return underlyingType.FullName
	end

	return clrType
end

---Create a constructed generic type.
---@param genericTypeName string The name of the generic type to construct and register.
---@vararg string
---@return ClrType The constructed generic type.
function CreateConstructedGenericType(genericTypeName, ...)
	local genericTypeArgumentsString = table.pack(...)

	local genericTypeArgumentsType = {}
	for _, typeString in pairs(genericTypeArgumentsString) do
		table.insert(genericTypeArgumentsType, GetRawClrType(typeString))
	end

	local genericTypeDefinition = GetRawClrType(genericTypeName)
	local constructedGenericType = genericTypeDefinition.MakeGenericType(table.unpack(genericTypeArgumentsType))
	return New(constructedGenericType)
end

---Get a System.Type object from a type name.
---@param typeName string Name of the type.
---@return userdata The type object (CLR type: System.Type).
function GetRawClrType(typeName)
	return LuaUserData.GetType(typeName)
end

---Get a ClrType instance wrapping a Type object that matches the type name.
---@param typeName string Name of the type.
---@return ClrType The CLR type.
function GetClrType(typeName)
	return New(GetRawClrType(typeName))
end

local function Init()
	UserData.RegisterStandardType("System.Type")
	UserData.RegisterStandardType("System.Reflection.RuntimeAssembly")
end

Init()
return Environment.Export(_ENV)
