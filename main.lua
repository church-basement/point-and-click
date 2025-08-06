
local save = require('save')
save.colorTables = save.colorTables or {}

local function getName(str)
	return str:match('(.*)%..*$')
end

local currentImage
local currentLocation = '1'
local validExtrentions = {
	['.jpg']='image',['.png']='image',
	['.wav']='audio',
	['.txt']='txt',
}

local directory = 'media/'
local imageHistory = {}
function loadImage(name)
	for i,item in ipairs(love.filesystem.getDirectoryItems(directory)) do
		print(name, item)
		if name == getName(item) then
			local extention = item:match('.*(%..*)$'):lower()
			local path = directory..item
			local fileType = validExtrentions[extention]
			print(fileType)
			if fileType == 'image' then
				currentImage = love.graphics.newImage(path)
				table.insert(imageHistory, name) 
				currentLocation = name
			elseif fileType == 'audio' then
				local source = love.audio.newSource(path,'static')
				source:play()
			elseif fileType == 'txt' then
				textBoxTable = {index = 1}
				local str = love.filesystem.read(path)
				local lastReturn = 1
				while true do
					local currReturn = str:find('\n',lastReturn)
					table.insert(textBoxTable, str:sub(1,currReturn or #str))
					if not currReturn then
						break
					end
					lastReturn = currReturn + 1
				end
			end
		end
	end
	
end
loadImage(currentLocation)

local brushIndex = 1
local colors = {
	{.7,.7,0},
	{0,.7,.7},
	{.7,0,.7},
	{.7,0,0},
	{0,.7,0},
	{0,0,.7},
}
for _,color in ipairs(colors) do
	for i=1,3 do
		color[i] = math.floor(color[i] / .1 + .5) * .1
	end
end

local colorCanvas = love.graphics.newCanvas(1000,1000)

local font = love.graphics.setNewFont(50)
local fontHeight = font:getHeight('0')

--

local editorMode = false
local textBoxText = ''
local textBoxTable = {}
local charPause = {
	['.'] = 1/2,
	[','] = 1/4,
	[' '] = 0,
}
local timeOffset = 0
local currentCharPause = 0

local mouseColorIndex

local function updateMouseColor()
	print('updateMouseColor()',love.timer.getTime())
	local mx, my = love.mouse.getPosition()
	mouseColorIndex = nil
	local r, g, b, a = colorCanvas:newImageData():getPixel(mx, my)
	r = math.floor(r / .1 + .5) * .1
	g = math.floor(g / .1 + .5) * .1
	b = math.floor(b / .1 + .5) * .1
	for i,color in ipairs(colors) do
		print(i,'---')
		print(color[1],color[2],color[3])
		print(r,g,b)
		if color[1] == r and color[2] == g and color[3] == b then
			print('  ^ match')
			mouseColorIndex = i
			break
		end
 	end
end

function love.draw()
	-- drawing to the color canvas
	local mx, my = love.mouse.getPosition()
	if editorMode then
		love.graphics.setBlendMode('replace')
		love.graphics.setCanvas(colorCanvas)
		if love.mouse.isDown(1) then
			local color = colors[brushIndex]
			love.graphics.setColor(color)
			love.graphics.circle('fill', mx, my, 50)
		end
		if love.mouse.isDown(2) then
			love.graphics.setColor(0,0,0,0)
			love.graphics.circle('fill', mx, my, 50)
		end
		love.graphics.setBlendMode('alpha')
	end

	love.graphics.setColor(1,1,1)
	love.graphics.setCanvas()
	love.graphics.draw(currentImage)

	if editorMode then
		love.graphics.setColor(1,1,1,.5)
		love.graphics.draw(colorCanvas)
		-- draw color names
		save.colorTables[currentLocation] = save.colorTables[currentLocation] or {}
		for i,name in ipairs(save.colorTables[currentLocation]) do
			love.graphics.setColor(colors[i])
			love.graphics.print(name, 0, (i-1)*fontHeight)
		end
		-- draw box for context
		local width, height = love.graphics.getWidth(), love.graphics.getHeight()
		love.graphics.rectangle('line',1.5,1.5,width-2,height-2)
	else
		updateMouseColor()
	 	if mouseColorName then
	 		love.graphics.setColor(1,1,1)
			love.graphics.circle('line',mx,my,5)
	 	end
	end

	local targetString = textBoxTable[textBoxTable.index]--'aos.idjoijfeoiewjfoiewjf'
	if targetString then
		local time = love.timer.getTime() - timeOffset
		if time > currentCharPause then
			textBoxText = targetString:sub(1, #textBoxText+1)
			local char = textBoxText:sub(#textBoxText, #textBoxText)
			currentCharPause = charPause[char] or 1/10
			
			timeOffset = love.timer.getTime()
		end
	end

	love.graphics.setColor(1,1,1)
	love.graphics.print(textBoxText, 0, fontHeight*3)
end

function love.filedropped(file)
	updateMouseColor()
	if mouseColorIndex then
		local path = file:getFilename()
		local preSlash = 1
		while true do
			local slash = path:find('/', preSlash)
			if not slash then
				break
			end
			preSlash = slash + 1
		end
		local filename = path:sub(preSlash, #path)
		save.colorTables[currentLocation][mouseColorIndex] = getName(filename)
	end
end

function love.mousepressed(mx, my, btn)
	if not editorMode then
		if textBoxText ~= '' then
			local targetText = textBoxTable[textBoxTable.index]
			if textBoxText ~= targetText then
				-- finish current phrase
				textBoxText = targetText
			else
				-- go to the next phrase
				textBoxTable.index = textBoxTable.index + 1
				textBoxText = ''
			end
		elseif mouseColorName then
			loadImage(mouseColorName)
		end
	 end
end

function love.keypressed(key)
	if key == 'e' then
		editorMode = not editorMode
	end
	if key == 'backspace' and #imageHistory > 1 then
		print('go back!')
		loadImage(imageHistory[#imageHistory-1])
		imageHistory[#imageHistory] = nil
	end
	if tonumber(key) then
		brushIndex = (tonumber(key) -1) % #colors + 1
	end
end

--[[local buckWild = love.quit()
function love.quit()
	
	buckWild()
end]]
