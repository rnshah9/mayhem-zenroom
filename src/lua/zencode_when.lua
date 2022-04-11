--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2021 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--Last modified by Denis Roio
--on Friday, 26th November 2021
--]]

--- WHEN

-- nop to terminate IF blocks
When("done", function() end)

IfWhen("'' is found", function(n) have(n) end)
IfWhen("'' is not found", function(n)
	ZEN.assert(ACK[n] == nil, "Object should not be found: "..n)
end)

When("append '' to ''", function(src, dest)
	local val = have(src)
	local dst = have(dest)
        -- if the destination is a number, fix the encoding to string
        if luatype(dst) == 'number' then
          dst = tostring(dst)
          ZEN.CODEC[dest].encoding = "string"
          ZEN.CODEC[dest].luatype = "string"
          ZEN.CODEC[dest].zentype = "element"
        end
        dst = dst .. val
        if luatype(dst) == 'string' then
          ACK[dest] = O.from_string(dst)
        else
	  ACK[dest] = dst
        end
end)

When("create the ''", function(dest)
	empty (dest)
	ACK[dest] = { }
	ZEN.CODEC[dest] = guess_conversion(ACK[dest], dest)
	ZEN.CODEC[dest].name = dest
end)
When("create the '' named ''", function(sch, name)
	empty(name)
	ACK[name] = { }
	ZEN.CODEC[name] = guess_conversion(ACK[name], sch)
	ZEN.CODEC[name].name = name
end)

-- simplified exception for I write: import encoding from_string ...
When("write string '' in ''", function(content, dest)
	empty(dest)
	ACK[dest] = O.from_string(content)
	ZEN.CODEC[dest] = new_codec(dest,
				    {encoding = 'string',
				     luatype = 'string',
				     zentype = 'element' })
end)

-- ... and from a number
When("write number '' in ''", function(content, dest)
	empty(dest)
	-- TODO: detect number base 10
	local num = tonumber(content)
	ZEN.assert(num, "Cannot convert value to number: "..content)
--	if num > 2147483647 then
--		error('Overflow of number object over 32bit signed size')
		-- TODO: maybe support unsigned native here
--	end
	ACK[dest] = BIG.from_decimal(content)
	ZEN.CODEC[dest] = new_codec(dest, {zentype = 'element' })
end)

When("create the number from ''", function(from)
	empty'number'
	local get = have(from)
	ACK.number = BIG.from_decimal(get:octet():string())
	ZEN.CODEC.number = new_codec('number', {zentype = 'element' })
end)

When("set '' to '' as ''", function(dest, content, format)
	empty(dest)
	local guess = input_encoding(format)
	guess.raw = content
	guess.name = dest
	if format == 'number' then
		ACK[dest] = BIG.from_decimal( operate_conversion(guess) )
	else
		ACK[dest] = operate_conversion(guess)
	end
--	ZEN.CODEC[dest] = new_codec(dest, { luatype = luatype(ACK[dest]), zentype = 'element' })
end)

When("create the json of ''", function(src)
	have(src)
	empty'json'
	ACK.json = OCTET.from_string( JSON.encode(ACK[src]) )
end)

-- numericals
When("set '' to '' base ''", function(dest, content, base)
	empty(dest)
	local bas = tonumber(base)
	ZEN.assert(bas, "Invalid numerical conversion for base: "..base)
	local num = tonumber(content,bas)
	ZEN.assert(num, "Invalid numerical conversion for value: "..content)
	ACK[dest] = num
	ZEN.CODEC[dest] = new_codec(dest,
				    {encoding = 'number',
				     luatype = 'number',
				     zentype = 'element' })
end)

local function _delete_f(name)
   have(name)
   ACK[name] = nil
   ZEN.CODEC[name] = nil
end
When("delete ''", _delete_f)
When("remove ''", _delete_f)


When("rename the '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = ACK[old]
	ACK[old] = nil
	ZEN.CODEC[new] = ZEN.CODEC[old]
	ZEN.CODEC[old] = nil
end)
When("rename '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = ACK[old]
	ACK[old] = nil
	ZEN.CODEC[new] = ZEN.CODEC[old]
	ZEN.CODEC[old] = nil
end)
When("rename the object named by '' to ''", function(old,new)
	local oldo = have(old)
	local olds = oldo:octet():string()
	have(olds)
	empty(new)
	ACK[new] = ACK[olds]
	ACK[olds] = nil
	ZEN.CODEC[new] = ZEN.CODEC[olds]
	ZEN.CODEC[olds] = nil
end)
When("rename '' to named by ''", function(old,new)
	have(old)
	local newo = have(new)
	local news = newo:octet():string()
	empty(news)
	ACK[news] = ACK[old]
	ACK[old] = nil
	ZEN.CODEC[news] = ZEN.CODEC[old]
	ZEN.CODEC[old] = nil
end)
When("rename the object named by '' to named by ''", function(old,new)
	local oldo = have(old)
	local olds = oldo:octet():string()
	have(olds)
	local newo = have(new)
	local news = newo:octet():string()
	empty(news)
	ACK[news] = ACK[olds]
	ACK[olds] = nil
	ZEN.CODEC[news] = ZEN.CODEC[olds]
	ZEN.CODEC[olds] = nil
end)

When("copy the '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = deepcopy(ACK[old])
	new_codec(new, { }, old)
end)
When("copy '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = deepcopy(ACK[old])
	new_codec(new, { }, old)
end)

When("copy contents of '' in ''", function(src,dst)
	local obj = have(src)
	have(dst)
	for k, v in pairs(obj) do
	   ACK[dst][k] = v -- no deepcopy
	   -- no new codec (using dst)
	end
end)

When("copy contents of '' named '' in ''", function(src,name,dst)
	local obj = have(src)
	have(dst)
	for k, v in pairs(obj) do
	   if k == name then
	      ACK[dst][k] = v -- no deepcopy
	   end
	   -- no new codec (using dst)
	end
end)

When("copy the '' in '' to ''", function(old,inside,new)
	ZEN.assert(ACK[inside][old], "Object not found: "..old.." inside "..inside)
	empty(new)
	ACK[new] = deepcopy(ACK[inside][old])
	new_codec(new, { }, inside)
end)

When("split the rightmost '' bytes of ''", function(len, src)
	local obj = have(src)
	empty'rightmost'
	local s = tonumber(len)
	ZEN.assert(s, "Invalid number arg #1: "..type(len))
	local l,r = OCTET.chop(obj,#obj-s)
	ACK.rightmost = r
	ACK[src] = l
	new_codec('rightmost', { }, src)
end)

When("split the leftmost '' bytes of ''", function(len, src)
	local obj = have(src)
	empty'leftmost'
	local s = tonumber(len)
	ZEN.assert(s, "Invalid number arg #1: "..type(len))
	local l,r = OCTET.chop(obj,s)
	ACK.leftmost = l
	ACK[src] = r
	new_codec('leftmost', { }, src)
end)

local function _numinput(num)
	local t = type(num)
	if not iszen(t) then
		if t == 'table' then -- TODO: only numbers supported, not zenroom.big
			local aggr = 0
			for _,v in pairs(num) do
				aggr = aggr + _numinput(v)
			end
			return aggr, false
		elseif t ~= 'number' then
			error('Invalid numeric type: ' .. t, 2)
		end
		return num, false
	end
	if t == 'zenroom.octet' then
		return BIG.new(num), true
	elseif t == 'zenroom.big' then
		return num, true
	else
		return BIG.from_decimal(num:octet():string()), true -- may give internal errors
	end
	error("Invalid number", 2)
	return nil, false
end

-- escape math function overloads for pointers
local function _add(l,r) return(l + r) end
local function _sub(l,r) return(l - r) end
local function _mul(l,r) return(l * r) end
local function _div(l,r) return(l / r) end
local function _mod(l,r) return(l % r) end

local function _math_op(op, l, r, bigop)
	local left, lz  = _numinput(l)
	local right, rz = _numinput(r)
	if lz ~= rz then error("Incompatible numeric arguments", 2) end
	local codec
	ACK.result = true -- new_codec checks existance
	if lz and rz then
		codec = new_codec('result',
				  {encoding = CONF.output.encoding.name,
				   luatype = 'string',
				   zentype = 'big' })
	else
		codec = new_codec('result',
				  {encoding = 'number',
				   luatype = 'number',
				   zentype = 'element' })
	end
        if type(left) == 'zenroom.big'
          and type(right) == 'zenroom.big' then
          if bigop then
            op = bigop
          -- -- We should check if the operatoin is supported
          --else
          --  error("Operation not supported on big integers")
          end
        end
	return op(left, right), codec
end

When("create the result of '' inverted sign", function(left)
	local l = have(left)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_sub, 0, l)
end)

When("create the result of '' + ''", function(left,right)
	local l = have(left)
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_add, l, r, BIG.zenadd)
        print(ACK.result:decimal())
end)

When("create the result of '' in '' + ''", function(left, dict, right)
	local d = have(dict)
	local l = d[left]
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_add, l, r, BIG.zenadd)
end)

When("create the result of '' in '' + '' in ''", function(left, ldict, right, rdict)
	local ld = have(ldict)
	local l = ld[left]
	local rd = have(rdict)
	local r = rd[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_add, l, r, BIG.zenadd)
end)

When("create the result of '' - ''", function(left,right)
	local l = have(left)
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_sub, l, r, BIG.zensub)
        print(ACK.result:decimal())
end)

When("create the result of '' in '' - ''", function(left, dict, right)
	local d = have(dict)
	local l = d[left]
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_sub, l, r, BIG.zensub)
end)

When("create the result of '' in '' - '' in ''", function(left, ldict, right, rdict)
	local ld = have(ldict)
	local l = ld[left]
	local rd = have(rdict)
	local r = rd[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_sub, l, r, BIG.zensub)
end)

When("create the result of '' * ''", function(left,right)
	local l = have(left)
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mul, l, r, BIG.zenmul)
        print(ACK.result:decimal())
end)

When("create the result of '' in '' * ''", function(left, dict, right)
	local d = have(dict)
	local l = d[left]
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mul, l, r, BIG.zenmul)
end)

When("create the result of '' * '' in ''", function(left, right, dict)
	local l = have(left)
	local d = have(dict)
	local r = d[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mul, l, r, BIG.zenmul)
end)

When("create the result of '' in '' * '' in ''", function(left, ldict, right, rdict)
	local ld = have(ldict)
	local l = ld[left]
	local rd = have(rdict)
	local r = rd[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mul, l, r, BIG.zenmul)
end)

When("create the result of '' / ''", function(left,right)
	local l = have(left)
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_div, l, r)
end)

When("create the result of '' in '' / ''", function(left, dict, right)
	local d = have(dict)
	local l = d[left]
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_div, l, r)
end)

When("create the result of '' / '' in ''", function(left, right, dict)
	local l = have(left)
	local d = have(dict)
	local r = d[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_div, l, r)
end)

When("create the result of '' in '' / '' in ''", function(left, ldict, right, rdict)
	local ld = have(ldict)
	local l = ld[left]
	local rd = have(rdict)
	local r = rd[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_div, l, r)
end)

When("create the result of '' % ''", function(left,right)
	local l = have(left)
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mod, l, r)
end)

When("create the result of '' in '' % ''", function(left, dict, right)
	local d = have(dict)
	local l = d[left]
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mod, l, r)
end)

When("create the result of '' in '' % '' in ''", function(left, ldict, right, rdict)
	local ld = have(ldict)
	local l = ld[left]
	local rd = have(rdict)
	local r = rd[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mod, l, r)
end)

-- TODO:
-- When("set '' as '' with ''", function(dest, format, content) end)
-- When("append '' as '' to ''", function(content, format, dest) end)
-- When("write '' as '' in ''", function(content, dest) end)
-- implicit conversion as string

-- https://github.com/dyne/Zenroom/issues/175
When("remove zero values in ''", function(target)
	have(target)
	ACK[target] = deepmap(function(v)
		if luatype(v) == 'number' then
			if v == 0 then
				return nil
			else
				return v
			end
		else
			return v
		end
	end, ACK[target])
end)

-- When("remove all empty strings in ''", function(target)
-- 	have(target)
-- 	ACK[target] = deepmap(function(v) if trim(v) == '' then return nil end, ACK[target])
-- end)
