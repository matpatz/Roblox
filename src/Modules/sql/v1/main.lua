-- src/Modules/v1/main.lua
-- A tiny in-memory SQL engine with an object layer.
--
-- Object API:
--	local users = sql.new("users", { "id", "name", "age" })
--	users:insert{ name = "bob", age = 30 }
--	users:insert("amy", 25)                        -- positional, schema order
--	users:where(users:col("age"):gt(20)):order(users:col("age"), "desc"):select("name"):all()
--	users:where(function(row) return row.age > 20 end)
--	users:where(sql.And(users:col("age"):gte(20), users:col("name"):like("a%")))
--	sql.db:select("users"):where("age", ">", 18):limit(10):all()
--	sql.db:select("users", "name", "age"):where("name", "like", "a%")()
--
-- SQL API:
--	sql.maketable("users")                         -- == sql.run("CREATE TABLE users")
--	sql.run("CREATE TABLE users (id, name, age)")
--	sql.run("INSERT INTO users VALUES (1, 'bob', 30), (2, 'amy', 25)")
--	sql.run("SELECT name FROM users WHERE age > 20 ORDER BY age DESC LIMIT 10")
--
-- Both APIs share storage (sql.db[name] is a Table object) and a single condition
-- evaluator. Statements: CREATE TABLE / DROP TABLE / INSERT / SELECT / UPDATE /
-- DELETE; WHERE supports = ~= < <= > >=, [NOT] LIKE, [NOT] IN, IS [NOT] NULL and
-- AND / OR / NOT.

local sql = {
	db = {},
	schema = {},
}

-- // Tokenizer

local function tokenize(query)
	local tokens = {}
	local length = #query
	local index = 1

	local function push(kind, value)
		tokens[#tokens + 1] = { kind = kind, value = value }
	end

	while index <= length do
		local character = query:sub(index, index)

		if character:match("%s") then
			index = index + 1
		elseif character == "-" and query:sub(index + 1, index + 1) == "-" then
			local newline = query:find("\n", index + 2, true)
			index = newline and newline + 1 or length + 1
		elseif character == "/" and query:sub(index + 1, index + 1) == "*" then
			local closing = query:find("*/", index + 2, true)
			if not closing then
				error("sql: unterminated comment")
			end
			index = closing + 2
		elseif character == "'" or character == '"' then
			local quote = character
			local cursor = index + 1
			local buffer = {}
			while true do
				local current = query:sub(cursor, cursor)
				if current == "" then
					error("sql: unterminated string starting at position " .. index)
				end
				if current == quote then
					if query:sub(cursor + 1, cursor + 1) == quote then
						buffer[#buffer + 1] = quote
						cursor = cursor + 2
					else
						break
					end
				else
					buffer[#buffer + 1] = current
					cursor = cursor + 1
				end
			end
			push("string", table.concat(buffer))
			index = cursor + 1
		elseif character:match("%d") or (character == "." and query:sub(index + 1, index + 1):match("%d")) then
			local number = query:match("^%d+%.%d*[eE][%+%-]?%d+", index)
				or query:match("^%.%d+[eE][%+%-]?%d+", index)
				or query:match("^%d+[eE][%+%-]?%d+", index)
				or query:match("^%d+%.%d*", index)
				or query:match("^%.%d+", index)
				or query:match("^%d+", index)
			push("number", number)
			index = index + #number
		elseif character:match("[%a_]") then
			local word = query:match("^[%a_][%w_]*", index)
			push("identifier", word)
			index = index + #word
		elseif character:match("[=<>~!]") then
			local pair = query:sub(index, index + 1)
			if pair == "<=" or pair == ">=" or pair == "~=" or pair == "!=" or pair == "<>" then
				if pair == "!=" or pair == "<>" then
					pair = "~="
				end
				push("op", pair)
				index = index + 2
			elseif character == "~" or character == "!" then
				error("sql: unexpected character '" .. character .. "'")
			else
				push("op", character)
				index = index + 1
			end
		elseif character:match("[%(%)%,%;%*%+%-]") then
			push("symbol", character)
			index = index + 1
		else
			error("sql: unexpected character '" .. character .. "'")
		end
	end

	return tokens
end

-- // Parser

local Parser = {}
Parser.__index = Parser

function Parser:peek(offset)
	return self.tokens[self.position + (offset or 0)]
end

function Parser:next()
	local token = self.tokens[self.position]
	self.position = self.position + 1
	return token
end

function Parser:isKeyword(word, offset)
	local token = self:peek(offset)
	return token ~= nil and token.kind == "identifier" and token.value:lower() == word
end

function Parser:acceptKeyword(word)
	if self:isKeyword(word) then
		self.position = self.position + 1
		return true
	end
	return false
end

function Parser:expectKeyword(word)
	if not self:acceptKeyword(word) then
		error("sql: expected keyword '" .. word:upper() .. "'")
	end
end

function Parser:isSymbol(symbol, offset)
	local token = self:peek(offset)
	return token ~= nil and token.kind == "symbol" and token.value == symbol
end

function Parser:acceptSymbol(symbol)
	if self:isSymbol(symbol) then
		self.position = self.position + 1
		return true
	end
	return false
end

function Parser:expectSymbol(symbol)
	if not self:acceptSymbol(symbol) then
		error("sql: expected '" .. symbol .. "'")
	end
end

function Parser:expectIdentifier()
	local token = self:next()
	if token == nil or token.kind ~= "identifier" then
		error("sql: expected an identifier")
	end
	return token.value
end

function Parser:expectNumber()
	local token = self:next()
	if token == nil or token.kind ~= "number" then
		error("sql: expected a number")
	end
	return tonumber(token.value)
end

local function newparser(tokens)
	return setmetatable({ tokens = tokens, position = 1 }, Parser)
end

-- // Expressions and conditions

local parseOrExpression

local function parseOperand(parser)
	local token = parser:next()
	if token == nil then
		error("sql: unexpected end of query")
	end

	if token.kind == "string" then
		return { kind = "literal", value = token.value }
	end

	if token.kind == "number" then
		return { kind = "literal", value = tonumber(token.value) }
	end

	if token.kind == "symbol" and (token.value == "-" or token.value == "+") then
		local operand = parseOperand(parser)
		if operand.kind ~= "literal" or type(operand.value) ~= "number" then
			error("sql: unary '" .. token.value .. "' expects a number")
		end
		if token.value == "-" then
			operand.value = -operand.value
		end
		return operand
	end

	if token.kind == "identifier" then
		local word = token.value:lower()
		if word == "null" then
			return { kind = "literal", value = nil }
		elseif word == "true" then
			return { kind = "literal", value = true }
		elseif word == "false" then
			return { kind = "literal", value = false }
		end
		return { kind = "column", name = token.value }
	end

	error("sql: unexpected token '" .. tostring(token.value) .. "'")
end

local function parseCondition(parser)
	local left = parseOperand(parser)

	if parser:acceptKeyword("is") then
		local negated = parser:acceptKeyword("not")
		parser:expectKeyword("null")
		return { kind = "isnull", expression = left, negated = negated }
	end

	local negated = false
	if parser:isKeyword("not") then
		parser:next()
		negated = true
	end

	if parser:acceptKeyword("in") then
		parser:expectSymbol("(")
		local values, count = {}, 0
		repeat
			count = count + 1
			values[count] = parseOperand(parser)
		until not parser:acceptSymbol(",")
		parser:expectSymbol(")")
		return { kind = "in", expression = left, values = values, count = count, negated = negated }
	end

	if parser:acceptKeyword("like") then
		return { kind = "like", expression = left, pattern = parseOperand(parser), negated = negated }
	end

	if negated then
		error("sql: expected IN or LIKE after NOT")
	end

	local token = parser:peek()
	if token == nil or token.kind ~= "op" then
		error("sql: expected a comparison operator")
	end
	parser:next()
	return { kind = "compare", left = left, operator = token.value, right = parseOperand(parser) }
end

local function parsePrimaryCondition(parser)
	if parser:acceptSymbol("(") then
		local expression = parseOrExpression(parser)
		parser:expectSymbol(")")
		return expression
	end
	return parseCondition(parser)
end

local function parseNotExpression(parser)
	if parser:acceptKeyword("not") then
		return { kind = "not", expression = parseNotExpression(parser) }
	end
	return parsePrimaryCondition(parser)
end

local function parseAndExpression(parser)
	local expression = parseNotExpression(parser)
	while parser:acceptKeyword("and") do
		expression = { kind = "and", left = expression, right = parseNotExpression(parser) }
	end
	return expression
end

function parseOrExpression(parser)
	local expression = parseAndExpression(parser)
	while parser:acceptKeyword("or") do
		expression = { kind = "or", left = expression, right = parseAndExpression(parser) }
	end
	return expression
end

-- // Projection, ordering and values

local aggregates = { count = true, sum = true, avg = true, min = true, max = true }

local function parseAggregate(parser)
	local name = parser:next().value:lower()
	parser:expectSymbol("(")
	local star, column
	if parser:acceptSymbol("*") then
		star = true
	else
		column = parser:expectIdentifier()
	end
	parser:expectSymbol(")")
	local alias
	if parser:acceptKeyword("as") then
		alias = parser:expectIdentifier()
	end
	return { aggregate = name, column = column, wildcard = star, alias = alias }
end

local function parseProjection(parser)
	local projection = {}
	repeat
		if parser:acceptSymbol("*") then
			projection[#projection + 1] = { star = true }
		else
			local token = parser:peek()
			if token ~= nil and token.kind == "identifier" and aggregates[token.value:lower()] and parser:isSymbol("(", 1) then
				projection[#projection + 1] = parseAggregate(parser)
			else
				local column = parser:expectIdentifier()
				local alias
				if parser:acceptKeyword("as") then
					alias = parser:expectIdentifier()
				end
				projection[#projection + 1] = { column = column, alias = alias }
			end
		end
	until not parser:acceptSymbol(",")
	return projection
end

local function parseOrderBy(parser)
	local keys = {}
	repeat
		local column = parser:expectIdentifier()
		local ascending = true
		if parser:acceptKeyword("asc") then
			ascending = true
		elseif parser:acceptKeyword("desc") then
			ascending = false
		end
		keys[#keys + 1] = { column = column, ascending = ascending }
	until not parser:acceptSymbol(",")
	return keys
end

local function parseValueList(parser)
	parser:expectSymbol("(")
	local values, count = {}, 0
	repeat
		count = count + 1
		values[count] = parseOperand(parser)
	until not parser:acceptSymbol(",")
	parser:expectSymbol(")")
	return values, count
end

-- // Evaluation

local function evaluateOperand(operand, row)
	if operand.kind == "literal" then
		return operand.value
	end
	return row[operand.name]
end

local function lessThan(left, right)
	if type(left) == "number" and type(right) == "number" then
		return left < right
	end
	if type(left) == "string" and type(right) == "string" then
		return left < right
	end
	return tostring(left) < tostring(right)
end

local function likeMatch(value, pattern)
	if value == nil or pattern == nil then
		return false
	end
	value, pattern = tostring(value), tostring(pattern)

	local luaPattern = "^"
	for index = 1, #pattern do
		local character = pattern:sub(index, index)
		if character == "%" then
			luaPattern = luaPattern .. ".*"
		elseif character == "_" then
			luaPattern = luaPattern .. "."
		elseif character:match("[%w]") then
			luaPattern = luaPattern .. character
		else
			luaPattern = luaPattern .. "%" .. character
		end
	end
	luaPattern = luaPattern .. "$"

	return value:match(luaPattern) ~= nil
end

local function compareValues(left, operator, right)
	if operator == "=" then
		return left == right
	end
	if operator == "~=" then
		return left ~= right
	end
	if left == nil or right == nil then
		return false
	end
	if type(left) ~= type(right) or (type(left) ~= "number" and type(left) ~= "string") then
		return false
	end
	if operator == "<" then
		return left < right
	elseif operator == "<=" then
		return left <= right
	elseif operator == ">" then
		return left > right
	elseif operator == ">=" then
		return left >= right
	end
	error("sql: unknown operator '" .. operator .. "'")
end

local function matches(condition, row)
	local kind = condition.kind

	if kind == "and" then
		return matches(condition.left, row) and matches(condition.right, row)
	end
	if kind == "or" then
		return matches(condition.left, row) or matches(condition.right, row)
	end
	if kind == "not" then
		return not matches(condition.expression, row)
	end
	if kind == "isnull" then
		return (evaluateOperand(condition.expression, row) == nil) ~= condition.negated
	end
	if kind == "in" then
		local value = evaluateOperand(condition.expression, row)
		local found = false
		for index = 1, condition.count do
			if evaluateOperand(condition.values[index], row) == value then
				found = true
				break
			end
		end
		return found ~= condition.negated
	end
	if kind == "like" then
		local value = evaluateOperand(condition.expression, row)
		local pattern = evaluateOperand(condition.pattern, row)
		return likeMatch(value, pattern) ~= condition.negated
	end
	if kind == "compare" then
		return compareValues(
			evaluateOperand(condition.left, row),
			condition.operator,
			evaluateOperand(condition.right, row)
		)
	end
	if kind == "predicate" then
		return condition.fn(row) and true or false
	end

	error("sql: unknown condition")
end

-- // Table helpers

local function requireTable(name)
	local target = sql.db[name]
	if not target then
		error("sql: table '" .. name .. "' does not exist")
	end
	return target
end

local function contains(list, value)
	for index = 1, #list do
		if list[index] == value then
			return true
		end
	end
	return false
end

local function registerColumn(table_, column)
	if not contains(table_.columns, column) then
		table_.columns[#table_.columns + 1] = column
	end
end

local function sortRows(rows, keys)
	table.sort(rows, function(a, b)
		for index = 1, #keys do
			local key = keys[index]
			local left, right = a[key.column], b[key.column]
			if left ~= right then
				if left == nil then
					return false
				end
				if right == nil then
					return true
				end
				if key.ascending then
					return lessThan(left, right)
				end
				return lessThan(right, left)
			end
		end
		return false
	end)
end

local function projectRow(row, projection)
	local result = {}
	for _, item in ipairs(projection) do
		if item.star then
			for key, value in pairs(row) do
				result[key] = value
			end
		else
			result[item.alias or item.column] = row[item.column]
		end
	end
	return result
end

local function projectAggregate(rows, projection)
	local result = {}
	for _, item in ipairs(projection) do
		if item.star then
			error("sql: cannot select '*' together with aggregate functions")
		end

		local value
		if item.aggregate == "count" then
			value = 0
			if item.wildcard then
				value = #rows
			else
				for _, row in ipairs(rows) do
					if row[item.column] ~= nil then
						value = value + 1
					end
				end
			end
		elseif item.aggregate == "sum" or item.aggregate == "avg" then
			local total, count = 0, 0
			for _, row in ipairs(rows) do
				local number = row[item.column]
				if type(number) == "number" then
					total = total + number
					count = count + 1
				end
			end
			if item.aggregate == "sum" then
				value = total
			else
				value = count > 0 and total / count or nil
			end
		elseif item.aggregate == "min" or item.aggregate == "max" then
			for _, row in ipairs(rows) do
				local candidate = row[item.column]
				if candidate ~= nil then
					if value == nil then
						value = candidate
					elseif item.aggregate == "min" and lessThan(candidate, value) then
						value = candidate
					elseif item.aggregate == "max" and lessThan(value, candidate) then
						value = candidate
					end
				end
			end
		end

		result[item.alias or item.aggregate] = value
	end
	return { result }
end

-- // Object layer
--
-- sql.db[name] is a Table, rows are Row objects, and conditions come from Column
-- objects (t.age:gt(20)), sql.And / sql.Or / sql.Not, or plain predicates
-- (function(row) ... end). Conditions are built in the parser's AST shape, so
-- matches() and the SQL string API share one evaluator.

local Row = {}

local function wrapRow(data)
	return setmetatable(data, Row)
end

Row.__index = Row

function Row.__tostring(self)
	local parts = {}
	for key, value in pairs(self) do
		parts[#parts + 1] = tostring(key) .. " = " .. tostring(value)
	end
	return "Row{ " .. table.concat(parts, ", ") .. " }"
end

function Row:get(column)
	return self[column]
end

function Row:set(column, value)
	self[column] = value
	return self
end

function Row:has(column)
	return self[column] ~= nil
end

function Row:fields()
	local names = {}
	for key in pairs(self) do
		names[#names + 1] = key
	end
	table.sort(names, function(a, b)
		return tostring(a) < tostring(b)
	end)
	return names
end

function Row:copy()
	local data = {}
	for key, value in pairs(self) do
		data[key] = value
	end
	return wrapRow(data)
end

local Condition = {}
Condition.__index = Condition

local function condition(ast)
	return setmetatable(ast, Condition)
end

local function And(...)
	local result
	for index = 1, select("#", ...) do
		local item = select(index, ...)
		if item ~= nil then
			if result == nil then
				result = item
			else
				result = { kind = "and", left = result, right = item }
			end
		end
	end
	return result ~= nil and condition(result) or nil
end

local function Or(...)
	local result
	for index = 1, select("#", ...) do
		local item = select(index, ...)
		if item ~= nil then
			if result == nil then
				result = item
			else
				result = { kind = "or", left = result, right = item }
			end
		end
	end
	return result ~= nil and condition(result) or nil
end

local function Not(item)
	return condition({ kind = "not", expression = item })
end

local function predicate(fn)
	return condition({ kind = "predicate", fn = fn })
end

local function asCondition(value)
	if value == nil then
		return nil
	end
	if type(value) == "function" then
		return predicate(value)
	end
	if type(value) == "string" then
		error("sql: where() expected a condition, got a column name (use where(column, value) or where(column, operator, value))")
	end
	return value
end

function Condition.__tostring(self)
	return "Condition(" .. tostring(self.kind) .. ")"
end

function Condition:and_(other)
	return condition({ kind = "and", left = self, right = other })
end

function Condition:or_(other)
	return condition({ kind = "or", left = self, right = other })
end

function Condition:not_()
	return condition({ kind = "not", expression = self })
end

local Column = {}
Column.__index = Column

function Column.__tostring(self)
	return self.table.name .. "." .. self.name
end

local function operandOf(value)
	if getmetatable(value) == Column then
		return { kind = "column", name = value.name }
	end
	return { kind = "literal", value = value }
end

local function columnOperand(column)
	if type(column) == "string" then
		return { kind = "column", name = column }
	end
	return { kind = "column", name = column.name }
end

local operators = {
	["="] = "=",
	["=="] = "=",
	eq = "=",
	["~="] = "~=",
	["!="] = "~=",
	["<>"] = "~=",
	neq = "~=",
	[">"] = ">",
	gt = ">",
	[">="] = ">=",
	gte = ">=",
	["<"] = "<",
	lt = "<",
	["<="] = "<=",
	lte = "<=",
}

local function comparison(column, operator, value)
	local normalized = operators[operator]
	if normalized == nil then
		error("sql: unknown operator '" .. tostring(operator) .. "'")
	end
	return condition({
		kind = "compare",
		left = columnOperand(column),
		operator = normalized,
		right = operandOf(value),
	})
end

function Column:eq(value)
	return comparison(self, "=", value)
end

function Column:neq(value)
	return comparison(self, "~=", value)
end

function Column:gt(value)
	return comparison(self, ">", value)
end

function Column:gte(value)
	return comparison(self, ">=", value)
end

function Column:lt(value)
	return comparison(self, "<", value)
end

function Column:lte(value)
	return comparison(self, "<=", value)
end

function Column:like(pattern)
	return condition({
		kind = "like",
		expression = columnOperand(self),
		pattern = { kind = "literal", value = pattern },
		negated = false,
	})
end

function Column:notlike(pattern)
	return condition({
		kind = "like",
		expression = columnOperand(self),
		pattern = { kind = "literal", value = pattern },
		negated = true,
	})
end

local function inCondition(column, values, negated)
	local list, count = {}, 0
	for _, value in ipairs(values) do
		count = count + 1
		list[count] = operandOf(value)
	end
	return condition({ kind = "in", expression = columnOperand(column), values = list, count = count, negated = negated })
end

function Column:in_(values)
	return inCondition(self, values, false)
end

function Column:notin(values)
	return inCondition(self, values, true)
end

function Column:isnull()
	return condition({ kind = "isnull", expression = columnOperand(self), negated = false })
end

function Column:notnull()
	return condition({ kind = "isnull", expression = columnOperand(self), negated = true })
end

function Column:between(low, high)
	return And(self:gte(low), self:lte(high))
end

-- (column, value), (column, "isnull") and (column, operator, value) shorthand:
--	db:select("users"):where("age", ">", 18)
--	users:where("name", "like", "b%")
--	users:where("id", "in", { 1, 2, 3 })
local function normalizeShorthand(...)
	local count = select("#", ...)

	if count == 2 and type((...)) == "string" then
		local column, value = ...
		if value == "isnull" or value == "null" then
			return condition({ kind = "isnull", expression = columnOperand(column), negated = false })
		end
		if value == "notnull" then
			return condition({ kind = "isnull", expression = columnOperand(column), negated = true })
		end
		return comparison(column, "=", value)
	end

	if count == 3 and type((...)) == "string" and type((select(2, ...))) == "string" then
		local column, operator, value = ...
		local key = operator:lower()
		if key == "like" or key == "notlike" then
			return condition({
				kind = "like",
				expression = columnOperand(column),
				pattern = { kind = "literal", value = value },
				negated = key == "notlike",
			})
		end
		if key == "in" or key == "notin" then
			return inCondition(column, value, key == "notin")
		end
		return comparison(column, operator, value)
	end

	return nil
end

local function combineConditions(combined, ...)
	local shorthand = normalizeShorthand(...)
	if shorthand ~= nil then
		if combined == nil then
			return shorthand
		end
		return condition({ kind = "and", left = combined, right = shorthand })
	end

	for index = 1, select("#", ...) do
		local item = asCondition(select(index, ...))
		if item ~= nil then
			if combined == nil then
				combined = item
			else
				combined = condition({ kind = "and", left = combined, right = item })
			end
		end
	end
	return combined
end

local Query = {}
Query.__index = Query

local function applyWindow(rows, offset, limit)
	if offset == nil and limit == nil then
		return rows
	end
	local result = {}
	local first = (offset or 0) + 1
	local last = limit ~= nil and (first + limit - 1) or #rows
	for index = first, last do
		if rows[index] ~= nil then
			result[#result + 1] = rows[index]
		end
	end
	return result
end

local function newQuery(table_, condition_)
	return setmetatable({
		table = table_,
		condition = condition_,
		orders = {},
		rowLimit = nil,
		rowOffset = nil,
		projection = nil,
	}, Query)
end

local function copyOrders(orders)
	local copy = {}
	for index = 1, #orders do
		copy[index] = orders[index]
	end
	return copy
end

local function columnName(value)
	if getmetatable(value) == Column then
		return value.name
	end
	return value
end

function Query:clone()
	local query = newQuery(self.table, self.condition)
	query.orders = copyOrders(self.orders)
	query.rowLimit = self.rowLimit
	query.rowOffset = self.rowOffset
	query.projection = self.projection
	return query
end

function Query:where(...)
	local query = self:clone()
	query.condition = combineConditions(self.condition, ...)
	return query
end

function Query:order(column, direction)
	local ascending = not (direction == "desc" or direction == "DESC" or direction == false)
	local query = self:clone()
	query.orders[#query.orders + 1] = { column = columnName(column), ascending = ascending }
	return query
end

function Query:limit(count)
	local query = self:clone()
	query.rowLimit = count
	return query
end

function Query:offset(count)
	local query = self:clone()
	query.rowOffset = count
	return query
end

function Query:select(...)
	local items, count = {}, 0
	for index = 1, select("#", ...) do
		local item = select(index, ...)
		count = count + 1
		if type(item) == "table" and getmetatable(item) == Column then
			items[count] = { column = item.name }
		elseif type(item) == "string" then
			items[count] = { column = item }
		else
			items[count] = item
		end
	end
	local query = self:clone()
	query.projection = items
	return query
end

function Query:accepts(row)
	return self.condition == nil or matches(self.condition, row)
end

function Query:all()
	local matched = {}
	for _, row in ipairs(self.table.rows) do
		if self:accepts(row) then
			matched[#matched + 1] = row
		end
	end

	if #self.orders > 0 then
		sortRows(matched, self.orders)
	end

	if self.projection ~= nil then
		local hasAggregate = false
		for _, item in ipairs(self.projection) do
			if item.aggregate then
				hasAggregate = true
				break
			end
		end
		if hasAggregate then
			local aggregated = projectAggregate(matched, self.projection)
			for index = 1, #aggregated do
				aggregated[index] = wrapRow(aggregated[index])
			end
			return aggregated
		end
		local projected = {}
		for _, row in ipairs(matched) do
			projected[#projected + 1] = wrapRow(projectRow(row, self.projection))
		end
		return applyWindow(projected, self.rowOffset, self.rowLimit)
	end

	return applyWindow(matched, self.rowOffset, self.rowLimit)
end

function Query:first()
	local rows = self:all()
	return rows[1]
end

function Query:count()
	local total = 0
	for _, row in ipairs(self.table.rows) do
		if self:accepts(row) then
			total = total + 1
		end
	end
	return total
end

function Query:exists()
	for _, row in ipairs(self.table.rows) do
		if self:accepts(row) then
			return true
		end
	end
	return false
end

function Query:pluck(column)
	local name = columnName(column)
	local values = {}
	for _, row in ipairs(self:all()) do
		values[#values + 1] = row[name]
	end
	return values
end

function Query:sum(column)
	local name = columnName(column)
	local total = 0
	for _, row in ipairs(self:all()) do
		local value = row[name]
		if type(value) == "number" then
			total = total + value
		end
	end
	return total
end

function Query:avg(column)
	local name = columnName(column)
	local total, count = 0, 0
	for _, row in ipairs(self:all()) do
		local value = row[name]
		if type(value) == "number" then
			total = total + value
			count = count + 1
		end
	end
	return count > 0 and total / count or nil
end

function Query:min(column)
	local name = columnName(column)
	local best
	for _, row in ipairs(self:all()) do
		local value = row[name]
		if value ~= nil and (best == nil or lessThan(value, best)) then
			best = value
		end
	end
	return best
end

function Query:max(column)
	local name = columnName(column)
	local best
	for _, row in ipairs(self:all()) do
		local value = row[name]
		if value ~= nil and (best == nil or lessThan(best, value)) then
			best = value
		end
	end
	return best
end

function Query:each(fn)
	for _, row in ipairs(self:all()) do
		if fn(row) == false then
			break
		end
	end
end

function Query:update(values)
	local affected = 0
	for _, row in ipairs(self.table.rows) do
		if self:accepts(row) then
			for column, value in pairs(values) do
				row[column] = value
				registerColumn(self.table, column)
			end
			affected = affected + 1
		end
	end
	return affected
end

function Query:delete()
	local condition_ = self.condition
	local removed = 0
	local kept = {}
	for _, row in ipairs(self.table.rows) do
		if condition_ == nil or matches(condition_, row) then
			removed = removed + 1
		else
			kept[#kept + 1] = row
		end
	end
	self.table.rows = kept
	return removed
end

function Query.__len(self)
	return self:count()
end

function Query.__call(self)
	return self:all()
end

function Query.__iter(self)
	local rows = self:all()
	local index = 0
	return function()
		index = index + 1
		return rows[index]
	end
end

function Query.__tostring(self)
	return "Query(" .. self.table.name .. ", " .. self:count() .. " matched)"
end

local Table = {}
Table.__index = Table

function Table.__tostring(self)
	return "Table(" .. self.name .. ", " .. #self.rows .. " rows)"
end

function Table.__len(self)
	return #self.rows
end

function Table.__iter(self)
	local index = 0
	return function()
		index = index + 1
		return self.rows[index]
	end
end

local function valuesToRow(table_, values, count)
	local row = {}
	for index = 1, count do
		local column = table_.columns[index]
		if column == nil then
			error("Table:insert: more values than columns on '" .. table_.name .. "'")
		end
		row[column] = values[index]
	end
	return row
end

function Table:insert(...)
	local arguments = table.pack(...)
	local row = {}

	if arguments.n == 1 and type(arguments[1]) == "table" then
		local source = arguments[1]
		if #source > 0 then
			row = valuesToRow(self, source, #source)
		else
			for column, value in pairs(source) do
				row[column] = value
				registerColumn(self, column)
			end
		end
	elseif arguments.n > 0 then
		row = valuesToRow(self, arguments, arguments.n)
	end

	row = wrapRow(row)
	self.rows[#self.rows + 1] = row
	return row
end

function Table:insertmany(list)
	local inserted = {}
	for _, item in ipairs(list) do
		inserted[#inserted + 1] = self:insert(item)
	end
	return inserted
end

function Table:where(...)
	return newQuery(self, combineConditions(nil, ...))
end

function Table:query()
	return newQuery(self, nil)
end

function Table:all()
	local copy = {}
	for index = 1, #self.rows do
		copy[index] = self.rows[index]
	end
	return copy
end

function Table:find(...)
	return self:where(...):all()
end

function Table:first(...)
	return self:where(...):first()
end

function Table:count(...)
	local condition_ = combineConditions(nil, ...)
	if condition_ == nil then
		return #self.rows
	end
	return self:where(condition_):count()
end

function Table:exists(condition_)
	return self:where(condition_):exists()
end

function Table:pluck(column)
	return self:query():pluck(column)
end

function Table:sum(column)
	return self:query():sum(column)
end

function Table:avg(column)
	return self:query():avg(column)
end

function Table:min(column)
	return self:query():min(column)
end

function Table:max(column)
	return self:query():max(column)
end

function Table:each(fn)
	return self:query():each(fn)
end

function Table:order(column, direction)
	return self:query():order(column, direction)
end

function Table:limit(count)
	return self:query():limit(count)
end

function Table:offset(count)
	return self:query():offset(count)
end

function Table:select(...)
	return self:query():select(...)
end

function Table:update(values, condition_)
	if condition_ ~= nil then
		return self:where(condition_):update(values)
	end

	local affected = 0
	for _, row in ipairs(self.rows) do
		for column, value in pairs(values) do
			row[column] = value
			registerColumn(self, column)
		end
		affected = affected + 1
	end
	return affected
end

function Table:delete(...)
	local condition_ = combineConditions(nil, ...)
	if condition_ == nil then
		return self:clear()
	end
	return self:where(condition_):delete()
end

function Table:clear()
	local removed = #self.rows
	self.rows = {}
	return removed
end

function Table:schema()
	local copy = {}
	for index = 1, #self.columns do
		copy[index] = self.columns[index]
	end
	return copy
end

function Table:has(column)
	return contains(self.columns, column)
end

function Table:col(column)
	if not contains(self.columns, column) then
		return nil
	end
	return setmetatable({ table = self, name = column }, Column)
end

function Table:addcolumn(column)
	registerColumn(self, column)
	return self
end

function Table:row(index)
	return self.rows[index]
end

function Table:drop()
	sql.db[self.name] = nil
	sql.schema[self.name] = nil
	self.rows = {}
	return true
end

local function createTable(name, columns)
	if type(columns) == "string" then
		columns = { columns }
	end

	local table_ = setmetatable({ name = name, columns = {}, rows = {} }, Table)
	sql.db[name] = table_
	sql.schema[name] = table_.columns

	for _, column in ipairs(columns or {}) do
		registerColumn(table_, column)
	end

	return table_
end

-- // Statements

local function executeCreate(parser)
	parser:expectKeyword("create")
	parser:expectKeyword("table")

	local ifNotExists = false
	if parser:acceptKeyword("if") then
		parser:expectKeyword("not")
		parser:expectKeyword("exists")
		ifNotExists = true
	end

	local name = parser:expectIdentifier()
	if sql.db[name] then
		if ifNotExists then
			return false
		end
		error("sql: table '" .. name .. "' already exists")
	end

	local columns = {}
	if parser:acceptSymbol("(") then
		repeat
			columns[#columns + 1] = parser:expectIdentifier()
			-- skip the rest of this column definition (types, constraints) up to , or )
			local depth = 0
			while true do
				local token = parser:peek()
				if token == nil then
					error("sql: unterminated column list")
				end
				if token.kind == "symbol" and token.value == "(" then
					depth = depth + 1
					parser:next()
				elseif token.kind == "symbol" and token.value == ")" then
					if depth == 0 then
						break
					end
					depth = depth - 1
					parser:next()
				elseif token.kind == "symbol" and token.value == "," and depth == 0 then
					break
				else
					parser:next()
				end
			end
		until not parser:acceptSymbol(",")
		parser:expectSymbol(")")
	end

	parser:acceptSymbol(";")
	return createTable(name, columns)
end

local function executeDrop(parser)
	parser:expectKeyword("drop")
	parser:expectKeyword("table")

	local ifExists = false
	if parser:acceptKeyword("if") then
		parser:expectKeyword("exists")
		ifExists = true
	end

	local name = parser:expectIdentifier()
	local table_ = sql.db[name]
	if table_ == nil then
		if ifExists then
			return false
		end
		error("sql: table '" .. name .. "' does not exist")
	end

	table_:drop()
	parser:acceptSymbol(";")
	return true
end

local function executeInsert(parser)
	parser:expectKeyword("insert")
	parser:expectKeyword("into")
	local name = parser:expectIdentifier()
	local target = requireTable(name)

	local columns
	if parser:acceptSymbol("(") then
		columns = {}
		repeat
			columns[#columns + 1] = parser:expectIdentifier()
		until not parser:acceptSymbol(",")
		parser:expectSymbol(")")
	end

	parser:expectKeyword("values")

	local inserted = 0
	repeat
		local values, count = parseValueList(parser)
		local names = columns or target.columns
		if names == nil or #names == 0 then
			error("sql: INSERT INTO '" .. name .. "' needs a column list (table has no schema)")
		end

		local row = {}
		for index = 1, count do
			local column = names[index]
			if column == nil then
				error("sql: too many values for table '" .. name .. "'")
			end
			row[column] = evaluateOperand(values[index], row)
			registerColumn(target, column)
		end

		target.rows[#target.rows + 1] = wrapRow(row)
		inserted = inserted + 1
	until not parser:acceptSymbol(",")

	parser:acceptSymbol(";")
	return inserted
end

local function executeSelect(parser)
	parser:expectKeyword("select")
	local projection = parseProjection(parser)
	parser:expectKeyword("from")
	local name = parser:expectIdentifier()
	local target = requireTable(name)

	local where
	if parser:acceptKeyword("where") then
		where = parseOrExpression(parser)
	end

	local orderBy
	if parser:acceptKeyword("order") then
		parser:expectKeyword("by")
		orderBy = parseOrderBy(parser)
	end

	local limit, offset
	while true do
		if parser:acceptKeyword("limit") then
			limit = parser:expectNumber()
		elseif parser:acceptKeyword("offset") then
			offset = parser:expectNumber()
		else
			break
		end
	end
	parser:acceptSymbol(";")

	local query = newQuery(target, where)
	query.orders = orderBy or {}
	query.rowLimit = limit
	query.rowOffset = offset
	query.projection = projection
	return query:all()
end

local function executeUpdate(parser)
	parser:expectKeyword("update")
	local name = parser:expectIdentifier()
	local target = requireTable(name)

	parser:expectKeyword("set")
	local assignments = {}
	repeat
		local column = parser:expectIdentifier()
		local token = parser:peek()
		if token == nil or token.kind ~= "op" or token.value ~= "=" then
			error("sql: expected '=' in SET")
		end
		parser:next()
		assignments[#assignments + 1] = { column = column, value = parseOperand(parser) }
	until not parser:acceptSymbol(",")

	local where
	if parser:acceptKeyword("where") then
		where = parseOrExpression(parser)
	end
	parser:acceptSymbol(";")

	local affected = 0
	for _, row in ipairs(target.rows) do
		if where == nil or matches(where, row) then
			for _, assignment in ipairs(assignments) do
				row[assignment.column] = evaluateOperand(assignment.value, row)
				registerColumn(target, assignment.column)
			end
			affected = affected + 1
		end
	end
	return affected
end

local function executeDelete(parser)
	parser:expectKeyword("delete")
	parser:expectKeyword("from")
	local name = parser:expectIdentifier()
	local target = requireTable(name)

	local where
	if parser:acceptKeyword("where") then
		where = parseOrExpression(parser)
	end
	parser:acceptSymbol(";")

	if where == nil then
		return target:clear()
	end

	local kept = {}
	local affected = 0
	for _, row in ipairs(target.rows) do
		if matches(where, row) then
			affected = affected + 1
		else
			kept[#kept + 1] = row
		end
	end
	target.rows = kept
	return affected
end

local function execute(parser)
	local token = parser:peek()
	if token == nil then
		return nil
	end
	if token.kind ~= "identifier" then
		error("sql: unexpected token '" .. tostring(token.value) .. "'")
	end

	local keyword = token.value:lower()
	if keyword == "create" then
		return executeCreate(parser)
	elseif keyword == "drop" then
		return executeDrop(parser)
	elseif keyword == "insert" then
		return executeInsert(parser)
	elseif keyword == "select" then
		return executeSelect(parser)
	elseif keyword == "update" then
		return executeUpdate(parser)
	elseif keyword == "delete" then
		return executeDelete(parser)
	end

	error("sql: unsupported statement '" .. keyword .. "'")
end

-- // db entry point
--
-- sql.db:select(...) is the chainable shorthand:
--	sql.db:select("users"):where("age", ">", 18):limit(10):all()

local Db = {}

function Db:select(name, ...)
	local query = newQuery(requireTable(name), nil)
	if select("#", ...) > 0 then
		query = query:select(...)
	end
	return query
end

Db.from = Db.select

function Db:table(name)
	return sql.db[name]
end

function Db:create(name, columns)
	if sql.db[name] ~= nil then
		error("sql: table '" .. name .. "' already exists")
	end
	return createTable(name, columns)
end

function Db:tables()
	return sql.names()
end

function Db:exists(name)
	return sql.db[name] ~= nil
end

-- // Public API

sql.run = function(query)
	local parser = newparser(tokenize(query))

	local results = {}
	while parser:peek() ~= nil do
		results[#results + 1] = execute(parser)
		parser:acceptSymbol(";")
	end

	if #results == 0 then
		error("sql: empty query")
	end
	if #results == 1 then
		return results[1]
	end
	return results
end

sql.maketable = function(name)
	return sql.run("CREATE TABLE " .. name)
end

sql.new = function(name, columns)
	if sql.db[name] ~= nil then
		error("sql: table '" .. name .. "' already exists")
	end
	return createTable(name, columns)
end

sql.get = function(name)
	return sql.db[name]
end

sql.exists = function(name)
	return sql.db[name] ~= nil
end

sql.drop = function(name)
	local table_ = sql.db[name]
	if table_ == nil then
		return false
	end
	return table_:drop()
end

sql.names = function()
	local names = {}
	for name in pairs(sql.db) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

sql.predicate = predicate
sql.And = And
sql.Or = Or
sql.Not = Not

sql.Row = Row
sql.Table = Table
sql.Query = Query
sql.Column = Column
sql.Condition = Condition

setmetatable(sql.db, {
	__index = Db,
})

setmetatable(sql, {
	__call = function(_, query)
		return sql.run(query)
	end,
	__index = function(_, key)
		return sql.db[key]
	end,
})

return sql