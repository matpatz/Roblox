local function Serialize(Value, Indent, Seen)
	Indent = Indent or 0
	Seen = Seen or {}

	local Type = type(Value)

	if Type == "nil" then
		return "nil"
	elseif Type == "boolean" then
		return tostring(Value)
	elseif Type == "number" then
		return tostring(Value)
	elseif Type == "string" then
		return string.format("%q", Value)
	elseif Type == "function" then
		return "<function>"
	elseif Type == "thread" then
		return "<thread>"
	elseif Type == "userdata" then
		return "<userdata>"
	elseif Type == "vector" then
		return tostring(Value)
	elseif Type == "buffer" then
		return "<buffer>"
	elseif Type ~= "table" then
		return "<" .. Type .. ">"
	end

	if Seen[Value] then
		return "<cycle>"
	end

	Seen[Value] = true

	local Padding = string.rep("    ", Indent)
	local NextPadding = string.rep("    ", Indent + 1)
	local Lines = {"{"}

	for Key, Item in pairs(Value) do
		local KeyType = type(Key)
		local FormattedKey

		if KeyType == "string" and Key:match("^[%a_][%w_]*$") then
			FormattedKey = Key
		else
			FormattedKey = "[" .. Serialize(Key, Indent + 1, Seen) .. "]"
		end

		Lines[#Lines + 1] =
			NextPadding
			.. FormattedKey
			.. " = "
			.. Serialize(Item, Indent + 1, Seen)
			.. ","
	end

	Lines[#Lines + 1] = Padding .. "}"

	Seen[Value] = nil

	return table.concat(Lines, "\n")
end

local Utils = {}

function Utils.setclipboard(Table)
	setclipboard(Serialize(Table))
end

function Utils.writefile(Table)
	writefile("table_dump.txt", Serialize(Table))
end
