local Knit = {}

Knit.require = function()
end

--@param1 Options: player, conmanager, whatnot
Knit.new = function(desiredmodules)
    local bundle = {}
    for i, v in next, desiredmodules do
        local bundlekey = Knit.require(v) -- exept not really, keep knit.require the same
        bundle[bundlekey] = bundlekey
    end
end