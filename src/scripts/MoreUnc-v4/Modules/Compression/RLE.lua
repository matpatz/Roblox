local RLE = {}

function RLE.Compress(str: string): string
    local parts = {}
    local len = #str
    local i = 1

    while i <= len do
        local char = str:sub(i, i)
        local count = 1
        while i + count <= len and str:sub(i + count, i + count) == char do
            count += 1
        end
        parts[#parts + 1] = string.pack(">I2", count) .. char
        i += count
    end

    return table.concat(parts)
end

function RLE.Decompress(encoded: string): string
    local len = #encoded
    local parts = {}
    local offset = 1

    while offset <= len do
        local count = string.unpack(">I2", encoded, offset)
        local char = encoded:sub(offset + 2, offset + 2)
        parts[#parts + 1] = char:rep(count)
        offset += 3
    end

    return table.concat(parts)
end

return RLE