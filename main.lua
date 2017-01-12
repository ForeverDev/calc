calc = dofile "calculator.lua"
parse = dofile "parse.lua"

local function entry()
	calc:init()	
	calc:cls()
	calc:border()
	calc:putstr(30, 7, "hello, world!")
	calc:display()
	while true do
		calc:handle_input()
	end
end

return entry()
