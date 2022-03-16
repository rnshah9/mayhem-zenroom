x = F.new(42)
xoct = x:octet()
y = F.new(xoct)
assert(x == y)


z = F.new(0)
assert(x ~= z)
assert(not (x ~= y))
assert(not (x == z))
