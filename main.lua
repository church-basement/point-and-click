
local save = require('save')
save.colorTables = save.colorTables or {}
save.currentLocation = save.currentLocation or '1'
math.randomseed(os.time())

local function getName(str)
	return str:match('(.*)%..*$')
end

local function fitDimentions(w1,h1,w2,h2)
	local ratio1 = w1/h1
	local ratio2 = w2/h2
	if ratio2 < ratio1 then
		local scale = w2 / w1
		return scale, 0, h2/2-h1*scale/2
	else
		local scale = h2 / h1
		return scale, w2/2-w1*scale/2, 0
	end
end
-- screen shinanigans
local screenDiv = 5
local screenHeight = 1080 / screenDiv
local screenWidth = screenHeight * 3 / 2
local screenRatio = screenWidth / screenHeight
local screen = love.graphics.newCanvas(screenWidth,screenHeight)
local ditheredScreen = love.graphics.newCanvas(screenWidth,screenHeight)
ditheredScreen:setFilter('nearest','nearest')
local screenScale
local screenCanvas
local screenCanvasWidth, screenCanvasHeight
function love.resize(x,y)
	local ratio = x/y
	if screenRatio < ratio then
		print('screenRatio < ratio')
		screenCanvasHeight = y
		screenCanvasWidth = y * 3 / 2
	else
		print('screenRatio > ratio')
		print(x)
		screenCanvasWidth = x
		screenCanvasHeight = x * 2 / 3
	end
	screenCanvasWidth = math.max(
		math.floor(screenCanvasWidth/screenWidth),
		1)*screenWidth
	screenCanvasHeight = math.max(
		math.floor(screenCanvasHeight/screenHeight),
		1)*screenHeight
	screenCanvas = love.graphics.newCanvas(screenCanvasWidth,screenCanvasHeight)
	screenScale = math.max(math.floor(screenCanvasWidth/screenWidth),1)
	print(screenScale)
end
love.window.setMode(500,500,{resizable=true})
love.resize(500,500)

-- font
local font = love.graphics.setNewFont(20)
local fontHeight = font:getHeight('0')
local editorMode = false
-- text box
local textBoxString = ''
local textBoxText = love.graphics.newText(font)
local textBoxTable = {}
local charPause = {
	['.'] = 1/2,
	[','] = 1/4,
	[' '] = 0,
}
local timeOffset = 0
local currentCharPause = 0
-- color stuff
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
local colorCanvas
local mouseColorIndex
local brushRadius = screenWidth / 30
-- location vars
local currentImage
local validExtrentions = {
	['.jpg']='image', ['.png']='image',
	['.wav']='audio', ['.ogg']='audio', ['.mp3'] = 'audio', ['.flac'] = 'audio',
	['.txt']='txt',
}

love.filesystem.createDirectory('colorCanvases/')

local function saveColorCanvas()
	if colorCanvas then
		local path = 'colorCanvases/'..save.currentLocation..'.png'
		colorCanvas:newImageData():encode('png',path)
	end
end

local colorCanvasImage
local directory = 'media/'
local sources = {}
local locationHistory = {}
function loadImage(name, noHistory)
	if not name then return end
	mouseRadius = 0
	--print('go to '..'"'..name..'"')
	for i,item in ipairs(love.filesystem.getDirectoryItems(directory)) do
		if name == getName(item) then
			local extention = item:match('.*(%..*)$'):lower()
			local path = directory..item
			local fileType = validExtrentions[extention]
			if fileType == 'image' then
				saveColorCanvas()
				save.currentLocation = name
				currentImage = love.graphics.newImage(path)
				local path = 'colorCanvases/'..name..'.png'
				if love.filesystem.getInfo(path) then
					colorCanvasImage = love.graphics.newImage(path)
				end
				colorCanvas = love.graphics.newCanvas(screenWidth, screenHeight)
				for _,source in ipairs(sources) do
					source:stop()
				end
				if not noHistory then
					table.insert(locationHistory, name)
				end
			elseif fileType == 'audio' then
				local source = love.audio.newSource(path,'static')
				source:play()
				table.insert(sources, source)
			elseif fileType == 'txt' then
				-- parse text file and load it into the textbox
				textBoxTable = {index = 1}
				local str = love.filesystem.read(path)
				local lastReturn = 1
				local maxWidth, maxHeight
				local safty1 = 1
				while true do
					local currReturn = str:find('\n',lastReturn)
					local phrase = str:sub(lastReturn,(currReturn or #str+1)-1)
					local preSpace = 0
					local preReturn = 0
					local safty2 = 1
					local height = fontHeight
					-- make the phrase fit onto multiple lines
					while true do
						local space = phrase:find(' ',preSpace + 1)
						local width = font:getWidth(
							phrase:sub(1,(space or #phrase-1)+1)
						)
						if width > screenWidth/2 then
							phrase = (
								phrase:sub(1,preSpace-1)
								..'\n'
								..phrase:sub(preSpace+1,#phrase)
							)
							height = height + fontHeight
						end
						if not space then
							break
						end
						preSpace = space
						safty2 = safty2 + 1
						assert(safty2 < 100,'oops.  runnaway function')
					end
					-- finalize phrase and add it to the table
					local width = font:getWidth(phrase)
					maxWidth = math.max(maxWidth or width,width)
					maxHeight = math.max(maxHeight or height,height)
					if #phrase > 0 then
						table.insert(textBoxTable, phrase)
					end
					if not currReturn then
						break
					end
					lastReturn = currReturn + 1
					safty1 = safty1 + 1
					assert(safty1 < 100,'oops.  runnaway function')
				end
				print(maxHeight)
				textBoxx = math.random()*(screenWidth-maxWidth or 0)
				textBoxy = math.random()*(screenHeight-maxHeight or 0)
			end
		end
	end
end
loadImage(save.currentLocation)

-- Shader stuff -------------------------------------------------

local ditherSize = math.floor(screenWidth/5)
local imageData = love.image.newImageData(ditherSize,ditherSize)
for x=0 ,ditherSize-1 do
	for y = 0, ditherSize-1 do
		local value = math.random()
		imageData:setPixel(x,y,value,value,value,1)
	end
end
local ditherTexture = love.graphics.newImage(imageData)
local ditherShader = love.graphics.newShader([[
uniform float width;
uniform float height;
uniform Image ditherTexture;
uniform float ditherSize;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 rgba = Texel(tex, texture_coords);
    vec2 chords = vec2(
    	mod(texture_coords.x*width,ditherSize)/ditherSize, 
    	mod(texture_coords.y*height,ditherSize)/ditherSize);
    
    rgba.rgb = rgba.rgb + (Texel(ditherTexture, chords).rgb * .1 - .05)  ;
    rgba = rgba * color;
	
  	rgba.rgb = floor(rgba.rgb*7)/7;
    
    return rgba;
}
]])
ditherShader:send('ditherTexture',ditherTexture)
ditherShader:send('ditherSize',ditherSize)
ditherShader:send('height',screenHeight)
ditherShader:send('width',screenWidth)


local lastDropedTime = 0
function love.draw()
	local width, height = love.graphics.getWidth(), love.graphics.getHeight()
	local ratio = width / height
		
	if colorCanvasImage then
		love.graphics.setCanvas(colorCanvas)
		love.graphics.draw(colorCanvasImage,0,0,0,screenWidth/colorCanvasImage:getWidth())
		colorCanvasImage = nil
	end
	
	-- drawing to the color canvas
	local mx, my = love.mouse.getPosition()
	local scale,xOffset,yOffset = fitDimentions(screenWidth,screenHeight,width,height)
	mx = (mx - xOffset) / scale
	my = (my - yOffset) / scale
	if editorMode then
		love.graphics.setBlendMode('replace')
		love.graphics.setCanvas(colorCanvas)
		local color = colors[brushIndex]
		if love.mouse.isDown(1) then
			love.graphics.setColor(color)
			love.graphics.circle('fill', mx, my, brushRadius)
		elseif love.mouse.isDown(2) then
			love.graphics.setColor(0,0,0,0)
			love.graphics.circle('fill', mx, my, brushRadius*2)
		end
		love.graphics.setBlendMode('alpha')
	end

	love.graphics.setColor(1,1,1)
	love.graphics.setCanvas(screen)
	
	-- draw image
	local imgWidth,imgHeight = currentImage:getWidth(),currentImage:getHeight()
	local imgRatio = imgWidth / imgHeight
	local time = love.timer.getTime()*.5
	local xOffset = math.sin(time)*.2
	local yOffset = math.sin(time*2)*.1
	local scale
	if screenRatio > imgRatio then
		scale = screenWidth / imgWidth
		yOffset = yOffset + (screenHeight/2-imgHeight*scale/2)
	else
		scale = screenHeight / imgHeight
		xOffset = xOffset + (screenWidth/2-imgWidth*scale/2)
	end
	love.graphics.draw(currentImage,xOffset,yOffset,0,scale)


	
	
	if editorMode then
		love.graphics.setColor(1,1,1,.5)
		love.graphics.draw(colorCanvas)
		-- draw brush color box
		local color = colors[brushIndex]
		love.graphics.setColor(color[1],color[2],color[3],.5)
		local boxWidth = 5
		for i=0,6 do
			love.graphics.rectangle('line',.5+i,.5+i,screenWidth-1-i*2,screenHeight-1-i*2)
		end
		-- draw color names
		save.colorTables[save.currentLocation] = save.colorTables[save.currentLocation] or {}
		for i,name in pairs(save.colorTables[save.currentLocation]) do
			local color = colors[i]
			love.graphics.setColor(color[1],color[2],color[3],i==brushIndex and 1 or .25)
			love.graphics.print(name, boxWidth*2, (i-1)*fontHeight+boxWidth*2)
		end
		-- draw brush previews
		love.graphics.setColor(.5,.5,.5,.25)
		if not love.mouse.isDown(2) then
			love.graphics.circle('line', mx, my, brushRadius)
		end
		if not love.mouse.isDown(1) then
			love.graphics.circle('line', mx, my, brushRadius*2)
		end
	else
		-- draw text
		local targetString = textBoxTable[textBoxTable.index]--'aos.idjoijfeoiewjfoiewjf'
		if targetString then
			local time = love.timer.getTime() - timeOffset
			if time > currentCharPause then
				textBoxString = targetString:sub(1, #textBoxString+1)
				local char = textBoxString:sub(#textBoxString, #textBoxString)
				currentCharPause = charPause[char] or 1/20
				timeOffset = love.timer.getTime()
			end
		end
		love.graphics.setColor(1,1,1)
		love.graphics.print(textBoxString, textBoxx, textBoxy)--screenHeight-textBoxText:getHeight())
	
		if #textBoxString == 0 then
			mouseColorIndex = nil
			local r, g, b, a = colorCanvas:newImageData():getPixel(
				mx%screenWidth, my%screenHeight)
			r = math.floor(r / .1 + .5) * .1
			g = math.floor(g / .1 + .5) * .1
			b = math.floor(b / .1 + .5) * .1
			for i,color in ipairs(colors) do
				if color[1] == r and color[2] == g and color[3] == b then
					mouseColorIndex = i
					break
				end
		 	end
		 	love.graphics.setColor(1,1,1)
		 	
		 	local targetMouseRadius = 2
		 	if mouseColorIndex then
		 		targetMouseRadius = 5
		 	end
		 	mouseRadius = mouseRadius or 0
		 	mouseRadius = mouseRadius + (targetMouseRadius-mouseRadius)*.4
			love.graphics.circle('line',mx,my,mouseRadius)
		end
	end

	-- dither
	love.graphics.setColor(1,1,1)
	love.graphics.setShader(ditherShader)
	love.graphics.setCanvas(ditheredScreen)
	love.graphics.draw(screen)
	love.graphics.setShader()
	
	love.graphics.setCanvas(screenCanvas)
	love.graphics.clear(1,0,0)
	love.graphics.draw(ditheredScreen,0,0,0,screenScale)
	
	love.graphics.setCanvas()
	if ratio < screenRatio then
		local scale = width / screenCanvasWidth
		love.graphics.draw(
			screenCanvas,0,height/2-screenCanvasHeight*scale/2,0,scale)
	else
		local scale = height / screenCanvasHeight
		love.graphics.draw(
			screenCanvas,width/2-screenCanvasWidth*scale/2,0,0,scale)
	end

	if not love.window.hasFocus() then
		local color = colors[brushIndex]
		local delta = love.timer.getTime()-lastDropedTime
		love.graphics.setColor(color[1],color[2],color[3],math.min(delta, .5))
		love.graphics.rectangle('fill',0,0,width, height)
	end
end

function love.filedropped(file)
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
	save.colorTables[save.currentLocation][brushIndex] = getName(filename)
	lastDropedTime = love.timer.getTime()
end

function love.mousepressed(mx, my, btn)
	if not editorMode then
		if textBoxString ~= '' then
			local targetText = textBoxTable[textBoxTable.index]
			if textBoxString ~= targetText then
				-- finish current phrase
				textBoxString = targetText
			else
				-- go to the next phrase
				textBoxTable.index = textBoxTable.index + 1
				textBoxString = ''
				timeOffset = love.timer.getTime()-100
			end
		elseif mouseColorIndex then
			loadImage(save.colorTables[save.currentLocation][mouseColorIndex])
		end
	 end
end

function love.keypressed(key)
	if key == 'e' then
		editorMode = not editorMode
	end
	if key == 'd' then
		editorMode = not editorMode
	end
	if key == 'backspace' and #locationHistory>=2 then
		loadImage(locationHistory[#locationHistory-1],true)
		locationHistory[#locationHistory] = nil
	end
	if key == 'return' and love.keyboard.isDown('ralt') then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
	if tonumber(key) then
		editorMode = true
		brushIndex = (tonumber(key) - 1) % #colors + 1
	end
	if key == 'escape' then	
		love.event.quit()
	end
end

local buckWild = love.quit
function love.quit()
	saveColorCanvas()
	buckWild()
end
