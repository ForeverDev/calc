calc = dofile "calculator.lua"
parse = dofile "parse.lua"

local function entry()
	calc:init()	
	while true do
		calc:handle_input()
	end
end

return entry()
