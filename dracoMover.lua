print("Beginning Draco Mover. . . ")

local component = require("component")
local robot = require("robot")
local sides = require("sides")

local rs = component.redstone
local ic = component.inventory_controller

rs.setOutput(sides.front, 0)

local function moveError(drc)
	msg = "Tried moving " .. drc .. " but something bad happened"
	print(msg)
end

local function moveForward(i)
	for j = 1, i, 1 do
		local attempt = robot.forward()
		if attempt ~= true then
			moveError("forward")
			break
		end
	end
end

local function moveBack(i)
	for j = 1, i, 1 do
		local attempt = robot.back()
		if attempt ~= true then
			moveError("backward")
			break
		end
	end
end

local function moveLeft(i)
	robot.turnLeft()
	for j = 1, i, 1 do
		local attempt = robot.forward()
		if attempt ~= true then
			moveError("left")
			break
		end
	end
	robot.turnRight()
end

local function moveRight(i)
	robot.turnRight()
	for j = 1, i, 1 do
		local attempt = robot.forward()
		if attempt ~= true then
			moveError("right")
			break
		end
	end
	robot.turnLeft()
end

local function moveUp(i)
	for j = 1, i, 1 do
		local attempt = robot.up()
		if attempt ~= true then
			moveError("up")
			break
		end
	end
end

local function moveDown(i)
	for j = 1, i, 1 do
		local attempt = robot.down()
		if attempt ~= true then
			moveError("down")
			break
		end
	end
end

local function lenTable(t)
	local lengthNum = 0
	for k, v in pairs(t) do
		lengthNum = lengthNum + 1
	end
	return lengthNum
end

local function makeRun()
	-- Check chest at start position
	startContents = {}
	robot.turnRight()
	local chest_slots = ic.getInventorySize(sides.front)
	for slot = 1, chest_slots, 1 do 
		item = ic.getStackInSlot(sides.front, slot)
		if item then
			startContents[item.name] = {["size"] = item.size, ["slot"] = slot}
		end
	end

	-- Move start chest contents to internal inventory and select recipe
	local wyvernCore = nil
	local number2make = 0
	for item, values in pairs(startContents) do
		ic.suckFromSlot(sides.front, startContents[item].slot)
		if item == "minecraft:emerald_block" then
			wyvernCore = true
			number2make = startContents[item].size / 1
		end
	end
	internalInventorySize = robot.inventorySize()
	for internalSlot = 1, internalInventorySize, 1 do
		for item, values in pairs(startContents) do 
			itemInSlot = ic.getStackInInternalSlot(internalSlot)
			if itemInSlot then
				if itemInSlot.name == item then
					startContents[item].slot = internalSlot
				end
			end
			
		end
	end
	robot.turnLeft()

	-- Move from start to first crafters
	moveForward(2)
	moveUp(1)
	moveForward(1)

	-- Place items in first set of crafters
	if wyvernCore == true then
		for item, values in pairs(startContents) do
			-- Place stars
			if item == "minecraft:nether_star" then
				local invSlot = startContents[item].slot
				robot.select(invSlot)
				ic.dropIntoSlot(sides.top, 1, number2make)
				ic.dropIntoSlot(sides.bottom, 1, number2make)
			end
			-- Place draco blocks
			if item == "draconicevolution:draconium_block" then
				local invSlot = startContents[item].slot
				robot.select(invSlot)
				robot.turnLeft()
				ic.dropIntoSlot(sides.front, 1, number2make)
				robot.turnAround()
				ic.dropIntoSlot(sides.front, 1, number2make)
				robot.turnLeft()
			end
		end
	end

	-- Move from first set of crafters to second
	moveBack(1)
	moveDown(1)
	moveLeft(4)
	moveForward(4)
	moveUp(1)
	moveRight(1)
	robot.turnRight()

	-- Place item in second set of crafters
	if wyvernCore == true then
		for item, values in pairs(startContents) do
			-- Place Draco Cores
			if item == "draconicevolution:draconic_core" then
				local invSlot = startContents[item].slot
				robot.select(invSlot)
				ic.dropIntoSlot(sides.top, 1, number2make)
				ic.dropIntoSlot(sides.bottom, 1, number2make)
				robot.turnLeft()
				ic.dropIntoSlot(sides.front, 1, number2make)
				robot.turnAround()
				ic.dropIntoSlot(sides.front, 1, number2make)
				robot.turnLeft()
			end
		end
	end

	-- See if third set is needed
	thirdNeeded = nil
	if wyvernCore then
		thirdNeeded = true
	end

	if thirdNeeded then
		-- Move from second set of crafters to third
		moveBack(1)
		moveDown(1)
		moveLeft(4)
		moveForward(4)
		moveUp(1)
		moveRight(1)
		robot.turnRight()

		-- Place item in third set of crafters
		if wyvernCore == true then
			for item, values in pairs(startContents) do
				-- Place Draco Cores
				if item == "draconicevolution:draconic_core" then
					local invSlot = startContents[item].slot
					robot.select(invSlot)
					ic.dropIntoSlot(sides.bottom, 1, number2make)
				end
			end
		end
	end

	-- Move to fusion crafter
	moveForward(2)

	-- Place items in fusion crafter
	if wyvernCore == true then
		for item, values in pairs(startContents) do
			-- Place Emerald Blocks
			if item == "minecraft:emerald_block" then
				local invSlot = startContents[item].slot
				robot.select(invSlot)
				ic.dropIntoSlot(sides.front, 1, number2make)
			end
		end
	end

	-- Trigger crafting
	rs.setOutput(sides.front, 0)
	os.sleep(1)
	rs.setOutput(sides.front, 15)
	os.sleep(1)
	rs.setOutput(sides.front, 0)
	os.sleep(1)
	
	-- Move back to start
	if thirdNeeded then
		moveRight(1)
		moveDown(1)
		moveForward(6)
		moveLeft(1)
		moveForward(1)
		robot.turnAround()
	else
		moveDown(1)
		moveRight(6)
		moveForward(1)
		moveRight(1)
		robot.turnLeft()
	end
end

local function startSignal()
	local result = nil
	local test = rs.getInput(sides.back)
	if test > 0 then
		result = true
	end
	return result
end

while true do
	rs.setOutput(sides.front, 0)
	local go = startSignal()
	if go then
		makeRun()
	end
	os.sleep(2)
end

--[[
**** Other crap ****

local internalSize = robot.inventorySize()
print("Internal inventory size: " .. internalSize)

]]


--print("Draco Mover has stopped")