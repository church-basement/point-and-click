

function saveTable(t,p,maxTab,tab,str,exclude)
   assert(type(t) == 'table','"t" is not a table')

   maxTab = maxTab or 1000
  
   -- this is the first line
   if not tab then
      str = 'return {\n'
      tab = '\t'
      exclude = {}
   end   

   -- break out
   for key,value in pairs(exclude) do
      if value == t then
         return str
      end
   end
   table.insert(exclude,t)
   
   -- loop through all values
   for key,value in pairs(t) do
      if key == '_' then goto nextValue end
      local t = type(value)
      if type(key) == 'string' then
         key = '"'..key..'"'
      end
      if t == 'table'
      and #tab < maxTab then
         str = str..tab..'['..key..'] = {\n'
         str = saveTable(value,p,maxTab,tab..'\t',str,exclude)
         str = str..tab..'},\n'
         goto nextValue
      end
      if t ~= 'boolean' 
      and t ~= 'number'
      and t ~= 'string' then
         goto nextValue
      end
      if t == 'string' then
         value = '[['..value..']]'
      end
      str = str..tab..'['..key..'] = '..tostring(value)..',\n'
      ::nextValue::
   end
   if tab == '\t' then
      str = str..'}'
      love.filesystem.write(p,str)
   else
      return str
   end
end

function loadTable(p)
   if love.filesystem.getInfo(p) then
      return love.filesystem.load(p)()
   end
   return {}
end

local save = {}

function save.__load()
	local table = loadTable('saveData.lua')
	for k,v in pairs(table) do
		save[k] = v
	end
	for k,v in pairs(save) do
		print(k,v)
	end
end 

function save.__save()
	saveTable(save,'saveData.lua')
end

function love.quit()
	save.__save()
end
save.__load()

return save
