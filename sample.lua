-- Lua sample program for lexical analysis

--[[
  This is a multiline comment.
  Demonstrating all major Lua token types.
]]

local greeting = "Hello, Lua!"
local version  = 5.4
local maxItems = 100
local hexColor = 0xFF5733
local isActive = true
local nothing  = nil

-- Function definition
local function greet(name)
    if name == nil then
        return "Hello, stranger!"
    elseif name == "admin" then
        return "Welcome back, admin."
    else
        return "Hello, " .. name .. "!"
    end
end

-- Table (Lua's data structure)
local student = {
    name  = "Maria",
    age   = 21,
    gpa   = 1.75,
    courses = { "PL", "OS", "Networks" }
}

-- Loop
local sum = 0
for i = 1, 10 do
    sum = sum + i
end

-- While loop
local count = 0
while count < 5 do
    count = count + 1
end

-- Repeat-until
repeat
    count = count - 1
until count == 0

-- Bitwise operators (Lua 5.3+)
local flags = 0x0F & 0xFF
local shifted = flags << 2

-- String with escape sequences
local msg = "Line1\nLine2\tTabbed"
local sq  = 'Single quoted string'

-- Long string
local text = [[
This is a
multiline long string
in Lua.
]]

-- Varargs
local function sum2(...)
    local total = 0
    for _, v in ipairs({...}) do
        total = total + v
    end
    return total
end

print(greet(student.name))
print("Sum 1-10:", sum)
print("Text length:", #text)
