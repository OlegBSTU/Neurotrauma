-- Functions for creating userdata.

local Environment = require 'ConsentRequiredExtended.Util.Environment'
local _ENV = Environment.PrepareEnvironment(_ENV)

---Create a userdata that references the type in a static context.
---@param clrTypeName string The name of the type to point to.
---@return userdata A userdata that references the type in a static context.
function FromStringStatic(clrTypeName)
    LuaUserData.CreateStatic(clrTypeName)
end

---Create a userdata that references the type described by a ClrType in a static context.
---@param clrType ClrType ClrType that describes the type being referenced.
---@return userdata A userdata that references the type in a static context.
function FromClrTypeStatic(clrType)
    return FromStringStatic(clrType:GetFullName())
end

---Create a userdata that references an instance of a CLR type with conversion.
---@param value any A Lua value to convert to a CLR object of the given type and wrap up in a userdata.
---@param clrType ClrType The CLR type to instantiate and wrap in the userdata.
---@return userdata A userdata that references the an instance of the CLR type.
function FromClrType(value, clrType)
    return LuaUserData.CreateUserDataFromType(value, clrType:GetUnderlyingType())
end

---Register standard types with MoonSharp. For generics use RegisterClrType.ConstructedGenericType.
---@param typeName string Name of the type to register.
function RegisterStandardType(typeName)
    local desc = LuaUserData.RegisterType(typeName)
    _G.Descriptors[typeName] = desc
end

return Environment.Export(_ENV)
