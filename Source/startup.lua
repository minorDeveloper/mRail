if fs.exists("updateProgram.lua") then 
		shell.run("rm ".."updateProgram.lua")
	end
shell.run("pastebin get wwdTVTi5 updateProgram.lua")
shell.run("updateProgram.lua")