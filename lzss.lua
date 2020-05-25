local lzss = [===[--[[----------------------------------------------------------------------------
	https://raw.githubusercontent.com/kieselsteini/lzss/master/lzss.lua
	LZSS - encoder / decoder

	This is free and unencumbered software released into the public domain.

	Anyone is free to copy, modify, publish, use, compile, sell, or
	distribute this software, either in source code form or as a compiled
	binary, for any purpose, commercial or non-commercial, and by any
	means.

	In jurisdictions that recognize copyright laws, the author or authors
	of this software dedicate any and all copyright interest in the
	software to the public domain. We make this dedication for the benefit
	of the public at large and to the detriment of our heirs and
	successors. We intend this dedication to be an overt act of
	relinquishment in perpetuity of all present and future rights to this
	software under copyright law.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
	OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
	OTHER DEALINGS IN THE SOFTWARE.

	For more information, please refer to <http://unlicense.org/>

--]]----------------------------------------------------------------------------
--------------------------------------------------------------------------------
local lzss = {}
local string, table = string, table

--------------------------------------------------------------------------------
local POS_BITS = 12
local LEN_BITS = 16 - POS_BITS
local POS_SIZE = 1 << POS_BITS
local LEN_SIZE = 1 << LEN_BITS
local LEN_MIN = 3

--------------------------------------------------------------------------------
function lzss.compress(input)
	local offset, output = 1, {}
	local window = ''

	local function search()
		for i = LEN_SIZE + LEN_MIN - 1, LEN_MIN, -1 do
			local str = string.sub(input, offset, offset + i - 1)
			local pos = string.find(window, str, 1, true)
			if pos then
				return pos, str
			end
		end
	end

	while offset <= #input do
		local flags, buffer = 0, {}

		for i = 0, 7 do
			if offset <= #input then
				local pos, str = search()
				if pos and #str >= LEN_MIN then
					local tmp = ((pos - 1) << LEN_BITS) | (#str - LEN_MIN)
					buffer[#buffer + 1] = string.pack('>I2', tmp)
				else
					flags = flags | (1 << i)
					str = string.sub(input, offset, offset)
					buffer[#buffer + 1] = str
				end
				window = string.sub(window .. str, -POS_SIZE)
				offset = offset + #str
			else
				break
			end
		end

		if #buffer > 0 then
			output[#output + 1] = string.char(flags)
			output[#output + 1] = table.concat(buffer)
		end
	end

	return table.concat(output)
end

--------------------------------------------------------------------------------
function lzss.decompress(input)
	local offset, output = 1, {}
	local window = ''

	while offset <= #input do
		local flags = string.byte(input, offset)
		offset = offset + 1

		for i = 1, 8 do
			local str = nil
			if (flags & 1) ~= 0 then
				if offset <= #input then
					str = string.sub(input, offset, offset)
					offset = offset + 1
				end
			else
				if offset + 1 <= #input then
					local tmp = string.unpack('>I2', input, offset)
					offset = offset + 2
					local pos = (tmp >> LEN_BITS) + 1
					local len = (tmp & (LEN_SIZE - 1)) + LEN_MIN
					str = string.sub(window, pos, pos + len - 1)
				end
			end
			flags = flags >> 1
			if str then
				output[#output + 1] = str
				window = string.sub(window .. str, -POS_SIZE)
			end
		end
	end

	return table.concat(output)
end

function lzss.getSXF(input, lua53) -- lua53 - force Lua 5.3 (OpenComputers ONLY)
	input = input and input:gsub(".", {["\r"] = "\\r", ["\n"] = "\\n", ["\\"] = "\\\\", ["'"] = "\\'"})

	local SXF = ([[local i,b,o,d,e,f,g,h,l='%s',1,'',''while b<=#i do e=o.byte(i,b)b=b+1;for j=0,7 do h=o.sub;l=h(i,b,b)if e>>j&1<1 and b<#i then g=o.unpack('>I2',i,b)f=1+(g>>4);l=h(d,f,f+(g&15)+2)b=b+1 end;b=b+1;o=o..l;d=h(d..l,-4^6)end end load(o,'=bios')()]])
		:format(
			input or ""
		)

	if lua53 then
		SXF = ('computer.setArchitecture"Lua 5.3"load([=[%s]=],"=bios")()'):format(SXF)
	end

	return SXF
end

return lzss

]===]

local success = load(lzss, "=lzss.lua")

if success then
	return success()
else
	error("THIS. LIBRARY. REQUIRES. LUA 5.3. OR. BETTER. PLEASE. INSTALL. IT")
end