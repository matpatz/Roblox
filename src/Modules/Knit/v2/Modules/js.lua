js:call(function()
	error("this error")
end):catch(function(errormessage)
	if errormessage == "this error" then
		print(errormessage, "uwu") --> this error uwu
	end
end)

-- return values, then/finally
js:call(function(a, b)
	return a + b
end, 2, 3):Then(function(sum)
	print(sum) --> 5
end):finally(function()
	print("done")
end)

-- trace as 3rd argument
js:call(function()
	error({ code = 404 }) -- table errors pass through untouched
end):catch(function(err, raw, trace)
	print(err.code) --> 404
end)