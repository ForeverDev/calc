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
	self.vars.pi = 3.141592653
	self.vars.e  = 2.718281828

	-- list of vars that can't be modified
	self.const = {}
	self.const.e = true
	self.const.pi = true

	-- screen pixels
	self.screen = {}
	for i = 1, self.SCREEN_X do
		self.screen[i] = {}
		for j = 1, self.SCREEN_Y do
			table.insert(self.screen[i], {px = " "})
		end
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

function calc:display()
	for j = 1, self.SCREEN_X do
		for i = 1, self.SCREEN_Y do
			local pixel = self.screen[i][j]
			io.write(pixel.px .. " ")
		end
		print()
	end
end

function calc:cls()
	for i = 1, 100 do
		print()
	end
end

function calc:border()
	for i = 1, self.SCREEN_X do
		self.screen[i][1].px = self.BORDER_CHAR
		self.screen[i][self.SCREEN_Y].px = self.BORDER_CHAR
	end
	for i = 1, self.SCREEN_Y do
		self.screen[1][i].px = self.BORDER_CHAR
		self.screen[self.SCREEN_X][i].px = self.BORDER_CHAR
	end
end

function calc:scroll()

end

function calc:putstr(x, y, str, ...)
	local dx = constrain(x, 2, self.SCREEN_X - 1)
	local dy = constrain(y, 2, self.SCREEN_Y - 1)	
	local formatted = string.format(str, ...)
	for i = 1, formatted:len() do
		self.screen[dx][dy].px = formatted:sub(i, i)	
		dx = dx + 1
		if dx > self.SCREEN_X - 1 then
			dy = dy + 1
			dx = 2
		end
		if dy > self.SCREEN_Y - 1 then
			self:scroll()
			dy = self.SCREEN_Y - 1
			dx = 2
		end
	end
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
		if self.const[var] then
			return die("the variable '%s' cannot be modified", var)
		end
		exec_tree(tree.right)
		self.vars[tree.left.id] = pop()
	else 
		exec_tree(tree)
		local result = pop()
		print(result)
	end

end

return calc
