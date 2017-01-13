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

	-- dictionary of functions
	self.functions = {}
	self.functions.cos = function(state, nargs)
		state:push_num(math.cos(state:pop_num()))
	end
	self.functions.sin = function(state, nargs)
		state:push_num(math.sin(state:pop_num()))
	end
	self.functions.tan = function(state, nargs)
		state:push_num(math.tan(state:pop_num()))
	end
	self.functions.rad = function(state, nargs)
		state:push_num(math.rad(state:pop_num()))
	end
	self.functions.deg = function(state, nargs)
		state:push_num(math.deg(state:pop_num()))
	end

	-- list of vars that can't be modified
	self.const = {}
	for i, v in pairs(self.vars) do
		self.const[i] = true
	end
	for i, v in pairs(self.functions) do
		self.const[i] = true
	end

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

	local calc = self
	
	local state = {}
	state.stack = {}
	
	function state:push(t)
		table.insert(self.stack, t)
	end

	function state:push_num(n)
		table.insert(self.stack, {
			kind = "number";
			n = n;
		})
	end

	function state:push_id(id)
		table.insert(self.stack, {
			kind = "identifier";
			id = id;
		})
	end
	
	function state:pop()
		return table.remove(self.stack, #self.stack)
	end

	function state:pop_num()
		return table.remove(self.stack, #self.stack).n
	end
	
	function state:die(msg, ...)
		print("error: " .. string.format(msg, ...))
	end

	local function exec_tree(t)
		if not t then
			return
		end
		if t.kind == "number" then
			state:push(t)	
		elseif t.kind == "identifier" then
			if self.functions[t.id] then
				state:die("'%s' is a function", t.id)
			end
			state:push_num(self.vars[t.id] or 0)	
		elseif t.kind == "binop" then
			exec_tree(t.left)
			exec_tree(t.right)
			local b = state:pop_num()	
			local a = state:pop_num()
			if t.op == "=" then
				return state:die("the '=' operator can only be used if it is top-level")
			end
			if t.op == "+" then
				state:push_num(a + b)
			elseif t.op == "-" then
				state:push_num(a - b)
			elseif t.op == "*" then
				state:push_num(a * b)
			elseif t.op == "/" then
				state:push_num(a / b)
			elseif t.op == "%" then
				state:push_num(a % b)
			elseif t.op == ">" then
				state:push_num(a > b and 1 or 0)
			elseif t.op == ">=" then
				state:push_num(a >= b and 1 or 0)
			elseif t.op == "<" then
				state:push_num(a < b and 1 or 0)
			elseif t.op == "<=" then
				state:push_num(a <= b and 1 or 0)
			elseif t.op == "==" then
				state:push_num(a == b and 1 or 0)
			elseif t.op == "^" then
				state:push_num(math.pow(a, b))
			end
		elseif t.kind == "unop" then
		
		elseif t.kind == "call" then
			local fname = t.name
			local args = t.args	
			local scan = t.args
			local nargs = 0
			if t.args then
				nargs = 1
			end
			while scan and scan.kind == "binop" and scan.op == "," do
				nargs = nargs + 1
				scan = scan.left
			end
			exec_tree(args)
			calc.functions[fname](state, nargs)
		end
	end

	if tree and tree.kind == "binop" and tree.op == "=" then
		local var = tree.left.id
		if not var then
			return state:die("invalid variable name")
		end
		if self.const[var] then
			return state:die("the variable '%s' cannot be modified", var)
		end
		exec_tree(tree.right)
		local result = state:pop_num()
		self.vars[tree.left.id] = result 
		print(result)
	else 
		exec_tree(tree)
		local result = state:pop_num()
		print(result)
	end

end

return calc
