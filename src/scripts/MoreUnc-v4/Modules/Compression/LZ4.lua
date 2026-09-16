--!strict
-- Pure-Lua LZ4 block codec (no executor functions used).
-- Compress() emits the same bytes as lz4compress() and Decompress() reads them back.

local LZ4 = {}

local MINMATCH = 4
local MFLIMIT = 12
local LASTLITERALS = 5
local DISTANCE_MAX = 65535
local U16_INPUT_LIMIT = 65547
local PRIME32 = 2654435761
local PRIME5_HI, PRIME5_LO = 207, 365368507

local floor = math.floor
local min = math.min
local char = string.char
local byte = string.byte
local sub = string.sub
local concat = table.concat

-- (a * b) % 2^32 without leaving double precision
local function mulMod32(a: number, b: number): number
	local a0, a1 = a % 65536, floor(a / 65536)
	local b0, b1 = b % 65536, floor(b / 65536)
	return ((a1 * b0 + a0 * b1) % 65536 * 65536 + a0 * b0) % 4294967296
end

-- top 13 bits of (sequence * PRIME32) % 2^32, used by the 16-bit table
local function hash4(seq: number): number
	return floor(mulMod32(seq, PRIME32) / 524288)
end

-- top 14 bits of ((sequence << 24) * 889523592379) % 2^64, used by the 32-bit table
local function hash5(seq8: number): number
	local low40 = seq8 % 1099511627776
	local a = {
		(low40 % 256) * 16777216 % 65536,
		floor((low40 % 256) * 16777216 / 65536),
		floor(low40 / 256) % 65536,
		floor(low40 / 16777216) % 65536,
	}
	local b = { PRIME5_LO % 65536, floor(PRIME5_LO / 65536), PRIME5_HI, 0 }

	local limbs = { 0, 0, 0, 0, 0, 0, 0, 0 }
	for i = 1, 4 do
		local ai = a[i]
		if ai ~= 0 then
			for j = 1, 4 do
				limbs[i + j - 1] += ai * b[j]
			end
		end
	end

	local carry = 0
	for k = 1, 8 do
		local t = limbs[k] + carry
		limbs[k] = t % 65536
		carry = floor(t / 65536)
	end

	return floor((limbs[4] * 65536 + limbs[3]) / 262144)
end

function LZ4.Compress(str: string): string
	local n = #str
	local parts: { string } = {}
	local nParts = 0

	local function push(value: string)
		nParts += 1
		parts[nParts] = value
	end

	-- literal nibble + match nibble, followed by the literal length overflow
	local function writeToken(litLen: number, matchCode: number)
		local litNibble = if litLen >= 15 then 15 else litLen
		local matchNibble = if matchCode >= 15 then 15 else matchCode
		push(char(litNibble * 16 + matchNibble))

		if litLen >= 15 then
			local rest = litLen - 15
			while rest >= 255 do
				push("\255")
				rest -= 255
			end
			push(char(rest))
		end
	end

	local function writeMatchLen(matchCode: number)
		if matchCode >= 15 then
			local rest = matchCode - 15
			while rest >= 255 do
				push("\255")
				rest -= 255
			end
			push(char(rest))
		end
	end

	-- shorter than MFLIMIT + 1: a single literal run and we are done
	if n < MFLIMIT + 1 then
		writeToken(n, 0)
		push(str)
		return concat(parts)
	end

	local smallInput = n < U16_INPUT_LIMIT
	local tableSize = if smallInput then 8192 else 16384
	local hashes: { number } = table.create(tableSize, 0)

	local function read32(off: number): number
		local b1, b2, b3, b4 = byte(str, off + 1, off + 4)
		return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
	end

	local function read64(off: number): number
		local b1, b2, b3, b4, b5, b6, b7, b8 = byte(str, off + 1, off + 8)
		return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
			+ (b5 + b6 * 256 + b7 * 65536 + b8 * 16777216) * 4294967296
	end

	local hashAt: (number) -> number
	local store: (number, number) -> ()

	if smallInput then
		hashAt = function(off: number): number
			return hash4(read32(off)) + 1
		end
		store = function(slot: number, idx: number)
			hashes[slot] = idx % 65536
		end
	else
		hashAt = function(off: number): number
			return hash5(read64(off)) + 1
		end
		store = function(slot: number, idx: number)
			hashes[slot] = idx
		end
	end

	local iend = n
	local mflimitPlusOne = n - MFLIMIT + 1
	local matchlimit = n - LASTLITERALS

	local anchor = 0
	store(hashAt(0), 0)

	local ip = 1
	local forwardH = hashAt(ip)

	while true do
		-- find a match: each slot holds the most recent position with that hash
		local matchIdx = -1
		local forwardIp = ip
		local step = 1
		local searchMatchNb = 64

		while true do
			local slot = forwardH
			ip = forwardIp
			forwardIp += step
			step = floor(searchMatchNb / 64)
			searchMatchNb += 1

			if forwardIp > mflimitPlusOne then
				break
			end

			local candidate = hashes[slot]
			forwardH = hashAt(forwardIp)
			store(slot, ip)

			if candidate + DISTANCE_MAX >= ip and read32(candidate) == read32(ip) then
				matchIdx = candidate
				break
			end
		end

		if matchIdx < 0 then
			local run = iend - anchor
			writeToken(run, 0)
			push(sub(str, anchor + 1, iend))
			return concat(parts)
		end

		while true do
			-- grow the match backwards while the previous bytes still line up
			while ip > anchor and matchIdx > 0 and byte(str, ip) == byte(str, matchIdx) do
				ip -= 1
				matchIdx -= 1
			end

			local litLen = ip - anchor

			local matchCode = 0
			local inPos = ip + MINMATCH
			local matchPos = matchIdx + MINMATCH
			while inPos < matchlimit and byte(str, inPos + 1) == byte(str, matchPos + 1) do
				inPos += 1
				matchPos += 1
				matchCode += 1
			end

			writeToken(litLen, matchCode)
			if litLen > 0 then
				push(sub(str, anchor + 1, ip))
			end

			local offset = ip - matchIdx
			push(char(offset % 256, floor(offset / 256) % 256))
			writeMatchLen(matchCode)

			ip += MINMATCH + matchCode
			anchor = ip

			-- the block always ends with at least 5 literals
			if ip >= mflimitPlusOne then
				local run = iend - anchor
				writeToken(run, 0)
				push(sub(str, anchor + 1, iend))
				return concat(parts)
			end

			store(hashAt(ip - 2), ip - 2)

			local nextMatch = hashes[hashAt(ip)]
			store(hashAt(ip), ip)

			if nextMatch + DISTANCE_MAX >= ip and read32(nextMatch) == read32(ip) then
				matchIdx = nextMatch
			else
				ip += 1
				forwardH = hashAt(ip)
				break
			end
		end
	end
end

function LZ4.Decompress(data: string): string
	local n = #data
	local out = ""
	local ip = 1

	while ip <= n do
		local token = byte(data, ip)
		ip += 1

		local litLen = bit32.rshift(token, 4)
		local matchCode = bit32.band(token, 15)

		if litLen == 15 then
			local extra
			repeat
				extra = byte(data, ip)
				ip += 1
				litLen += extra
			until extra ~= 255
		end

		if litLen > 0 then
			out ..= sub(data, ip, ip + litLen - 1)
			ip += litLen
		end

		-- a trailing literal-only sequence has no offset after it
		if ip > n then
			break
		end

		local offset = byte(data, ip) + byte(data, ip + 1) * 256
		ip += 2

		if matchCode == 15 then
			local extra
			repeat
				extra = byte(data, ip)
				ip += 1
				matchCode += extra
			until extra ~= 255
		end
		matchCode += MINMATCH

		local start = #out - offset + 1
		local remaining = matchCode
		while remaining > 0 do
			local take = min(#out - start + 1, remaining)
			out ..= sub(out, start, start + take - 1)
			remaining -= take
		end
	end

	return out
end

LZ4.compress = LZ4.Compress
LZ4.decompress = LZ4.Decompress

return LZ4