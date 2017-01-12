local parse = {}

local function lex(exp)
	local tokens = {}
	local i = 1
	while i <= exp:len() do
		local c = exp:sub(i, i)
		if c:match("%d") then
			local num = ""
			local decimal = false
			while c:match("%d") or (c == "." and not decimal) do
				if c == "." then
					decimal = true
				end
				num = num .. c
				i = i + 1
				c = exp:sub(i, i)
			end
			table.insert(tokens, {
				kind = "number";
				word = num;
				n    = tonumber(num);
			})
		elseif c:match("%p") then
			table.insert(tokens, {
				kind = "operator";
				word = c;
			})	
			i = i + 1
		elseif c:match("%w") then
			local word = ""
			while c:match("%w") do
				word = word .. c
				i = i + 1
				c = exp:sub(i, i)
			end
			table.insert(tokens, {
				kind = "identifier";
				word = word;
			})
		else
			i = i + 1
		end
	end	
	return tokens
end

local function to_tree(tokens)
	
	if not tokens then
		return nil
	end

	local op_info = {
		["="] = {1, "right", "binary"};
		["+"] = {2, "left", "binary"};
		["-"] = {2, "left", "binary"};
		["*"] = {3, "left", "binary"};
		["/"] = {3, "left", "binary"};
		["%"] = {3, "left", "binary"};
		["^"] = {4, "right", "binary"};
	}
	
	local postfix = {}
	local operators = {}

	local function die(msg, ...)
		print("error: " .. string.format(msg, ...))
	end

	for i, v in ipairs(tokens) do
		if v.kind == "number" or v.kind == "identifier" then
			table.insert(postfix, v)
		elseif v.kind == "operator" then
			if v.word == "(" then
				table.insert(operators, v)
			elseif v.word == ")" then
				while true do
					local popped = table.remove(operators, #operators)
					if not popped then
						return die("syntax")
					end
					if popped.word == "(" then
						break
					end
					table.insert(postfix, popped)
				end
			else
				local info = op_info[v.word]
				if not info then
					return die("unknown operator '%s'", v.word)
				end
				while true do
					local top = operators[#operators]
					if not top then
						break
					end
					local top_info = op_info[top.word]
					if top.word == "(" then
						break
					end
					if top_info[2] == "left" then
						if info[1] > top_info[1] then
							break
						end
					else
						if info[1] >= top_info[1] then
							break
						end
					end
					table.insert(postfix, table.remove(operators, #operators))
				end
				table.insert(operators, v)
			end
		else
			return die("unknown token with word '%s'", v.word)
		end
	end

	while #operators > 0 do
		table.insert(postfix, table.remove(operators, #operators))
	end

	-- postfix is now an array of tokens in postfix notation....
	-- now convert it to an expression tree

	local stack = {}

	for i, v in ipairs(postfix) do
		if v.kind == "number" then
			table.insert(stack, {
				kind   = "number";
				n      = v.n;
				parent = nil;	
				side   = nil;
			})
		elseif v.kind == "identifier" then 
			table.insert(stack, {
				kind   = "identifier";
				id	   = v.word;
				parent = nil;
				side   = nil;
			})
		elseif v.kind == "operator" then
			if op_info[v.word][3] == "binary" then
				local b = table.remove(stack, #stack)
				local a = table.remove(stack, #stack)
				if not (a and b) then
					return die("syntax")
				end
				local operator = {
					kind   = "binop";
					op     = v.word;
					left   = a;
					right  = b;
					parent = nil;
					side   = nil;
				}
				a.parent = operator
				a.side = "left"
				b.parent = operator
				b.side = "right"
				table.insert(stack, operator)
			else
				local operand = table.remove(stack, #stack)
				if not operand then
					return die("syntax") 
				end
				local operator = {
					kind    = "unop";
					op      = v.word;
					operand = operand;
					parent  = nil;
					side    = nil	
				}
				table.insert(stack, operator)
			end
		end
	end

	if #stack ~= 1 then
		return die("an expression must result in exactly one value")
	end

	return stack[1]
end

function parse:print_tree(tree, indent)
	indent = indent or 0

	local function make_indent()
		for i = 1, indent do
			io.write("\t")
		end
	end
	
	make_indent()

	if tree.kind == "number" then
		print(tree.n)
	elseif tree.kind == "identifier" then
		print(tree.id)
	elseif tree.kind == "binop" then
		print(tree.op)
		self:print_tree(tree.left, indent + 1)
		self:print_tree(tree.right, indent + 1)
	elseif tree.kind == "unop" then
		print(tree.op)
		self:print_tree(tree.operand, indent + 1)
	end

end

function parse:make_tree(expression)
	return to_tree(lex(expression))
end

return parse
