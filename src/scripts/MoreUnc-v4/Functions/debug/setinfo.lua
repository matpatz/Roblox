type func = typeof(function() end)

return function(func: func, info)
    -- hook getinfo, and info on func to return what we want
end

--[[ -- anything you would see in debug.getinfo
local info = {
  name = "bar",
  source = "bar",
  short_src = "bar",
  currentline = 123
}
]]