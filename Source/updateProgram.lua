
local id = {
	"U12QGYKX",
	"e5VhnaQM",
	"UaRx0QD9",
	"C6HpZ6X8"
}
local name = {
	"depotCollection.lua",
	"depotRelease.lua",
	"mRail.lua",
	"json.lua"
}


for i = 1, #id do
	if fs.exists(name[i]) then 
		shell.run("rm "..name[i])
	end
	shell.run("pastebin get "..id[i].." "..name[i])
end

