tst = require("tst")

local t = tst.TernarySearchTree:new()

t:add("kent", "all songs")
t:add("ff", "kent - ff")
t:add("pärlor", "kent - pärlor")
t:add("foo", "kent - foo")

print("TST:\n" .. tostring(t))

print("exact search: " .. t:search("kent"))

for value in t:prefix_search("pä") do
  print("prefix match: " .. value)
end
