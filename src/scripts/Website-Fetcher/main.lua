local Response = request({
    Url = getgenv().url,
    Method = "GET",
})

print(Response.StatusCode)
print(Response.Body)
