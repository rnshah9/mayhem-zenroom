-- this is a simple rsp parser by jaromil@dyne.org
-- an rsp file must be loaded in DATA
-- the kind of hash must be indicated in KEYS
-- public domain (and thanks for all the NIST)

local function newline_iter(text)
	s = trim(text) -- implemented in zen_io.c
	if s:sub(-1) ~= '\n' then
		s = s .. '\n'
	end
	return s:gmatch('(.-)\n') -- iterators return functions
end

local QP = require'qp'
local curr_fields = 0
local test = { }
local nr = 0
for line in newline_iter(DATA) do
   if line:sub(1,1) ~= "#" then
      local rule = strtok(line)

      if #rule > 0 and rule[1]:lower() ~= "count" and rule[1]:lower() ~= "mlen" and rule[1]:lower() ~= "smlen" then
	 curr_fields = curr_fields+1

	 test[rule[1]:lower()] = O.from_hex(rule[3])
      end
      
      if curr_fields == 5 then
	 -- I should check the name of the fields
	 nr = nr + 1

	 -- Here starts the test
	 assert(test.pk == QP.kempubgen(test.sk))
	 assert(QP.kempubcheck(test.pk))
	 assert(QP.kemsscheck(test.ss))
	 assert(QP.kemctcheck(test.ct))
	 assert(test.ss == QP.dec(test.sk, test.ct))

	 curr_fields = 0
	 test = { }
      end
   end
end
print(nr)
