local calc = {}

local function constrain(n, a, b)
	return n < a and a or n > b and b or n
end

function calc:init()
	
	-- constants
	self.SCREEN_X = 40
	self.SCREEN_Y = 40
	self.BORDER_CHAR = "#"

	-- list of possible states
	--	main
	self.state = "main"

	-- input currently being processed
	self.input = nil

	-- previous expression results
	self.history = {}
	
	-- dictionary of variables
	self.vars = {}
	self.vars.pi  = 3.14159265358979
	self.vars.e   = 2.71828182845905
	self.vars.phi = 1.61803398874989

	-- list of vars that can't be modified
	self.const = {}
	self.const.e = true
	self.const.pi = true
	self.const.phi = true

end

function calc:report_error(format, ...)
	print(string.format("** ERROR **\nmessage: %s", string.format(format, ...)))
end

function calc:get_input()
	io.write("> ")
	self.input = io.read()
end

function calc:handle_input()
	self:get_input()
	self:execute(self.input)
end

function calc:execute(exp)
	local tree = parse:make_tree(exp)
	if not tree then
		return
	end
	
	local stack = {}

	local function push(n)
		table.insert(stack, n)
	end

	local function pop()
		return table.remove(stack, #stack)
	end

	local function die(msg, ...)
		print("error: " .. string.format(msg, ...))
	end

	local function exec_tree(t)
		if not t then
			return
		end
		if t.kind == "number" then
			push(t.n)	
		elseif t.kind == "identifier" then
			push(self.vars[t.id] or 0)	
		elseif t.kind == "binop" then
			exec_tree(t.left)
			exec_tree(t.right)
			local b = pop()	
			local a = pop()
			if t.op == "=" then
				return die("the '=' operator can only be used if it is top-level")
			end
			if t.op == "+" then
				push(a + b)
			elseif t.op == "-" then
				push(a - b)
			elseif t.op == "*" then
				push(a * b)
			elseif t.op == "/" then
				push(a / b)
			elseif t.op == "%" then
				push(a % b)
			elseif t.op == "^" then
				push(math.pow(a, b))
			end
		elseif t.kind == "unop" then
		
		end	
	end

	if tree and tree.kind == "binop" and tree.op == "=" then
		local var = tree.left.id
		if not var then
			return die("invalid variable name")
		end
		if self.const[var] then
			return die("the variable '%s' cannot be modified", var)
		end
		exec_tree(tree.right)
		local result = pop()
		self.vars[tree.left.id] = result 
		print(result)
	else 
		exec_tree(tree)
		local result = pop()
		print(result)
	end

end

return calc
