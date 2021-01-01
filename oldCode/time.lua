
while true do
	local currentTime = os.time()
	
	if currentTime >= 6.0 and currentTime <= 6.15 then
		redstone.setOutput("right",true)
	else
		redstone.setOutput("right",false)
	end
	sleep(5)
end