local parse = {}

local function lex(expression)

end

local function to_tree(tokens)

end

function parse.make_tree(expression)
	return to_tree(lex(expression))
end

return parse
