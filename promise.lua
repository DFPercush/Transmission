
local debug_prints = false

if windower == nil then
	-- for testing outside game
	require("util")
end

local R = {}

local WAITING = 1
local RESOLVING = 2
local RESOLVED = 3
local REJECTING = 4
local REJECTED = 5
local ABORT = 6

local ANY = 7
local ALL = 8


local this_file = debug.getinfo(0, "S").source
local promise_object_type = this_file .. "<Promise>"
local function is_promise(x)
	return type(x) == "table" and x.object_type == promise_object_type
end

-- Used to avoid recursion
local processing_chain_now = false
local abort_chain = false
local repeat_chain_element = false

local function chain(p)
	if processing_chain_now then return end
	processing_chain_now = true
	abort_chain = false
	local cur = p --.downstream
	
	local dbg_str, dbg_next_obj
	if debug_prints then print( "CHAIN START " .. quick_trace(" > ")) end
	--dbg_str = "Chain start"
	--dbg_next_obj = p
	--while dbg_next_obj do
	--	dbg_str = dbg_str .. " -> " .. (dbg_next_obj.debug_name or "anon") .. "(" .. dbg_next_obj.state .. ")"
	--	dbg_next_obj = dbg_next_obj.downstream
	--end
	--print(dbg_str)
	
	--local prev = p
	local unhandled_rejection = false
	local unhandled_rejection_msg = ""
	while cur do --.can_finish() do
		
		if debug_prints then
			dbg_str = "Chain continue"
			dbg_next_obj = cur
			while dbg_next_obj do
				dbg_str = dbg_str .. " -> " .. (dbg_next_obj.debug_name or "anon") .. "(" .. dbg_next_obj.state .. ")["
				local firstup = true
				for _,up in ipairs(dbg_next_obj.upstream) do
					dbg_str = dbg_str .. ((not firstup and ",") or "") .. (up.debug_name or "?")
					firstup = false
				end
				dbg_str = dbg_str .. "]"
				dbg_next_obj = dbg_next_obj.downstream
			end
			print(dbg_str)
		end
		
		--print("chain() cur.state ==" .. cur.state .. ", downstream is " .. tostring(cur.downstream and cur.downstream.state) .. ", unhandled_rejection == " .. tostring(unhandled_rejection))
		
		repeat_chain_element = false
		
		if cur.state == ABORT then return end
		--if cur.state == WAITING and #(cur.upstream) > 0 then
		if not cur.finished then
			local any_resolved = reduce(cur.upstream, false, function(v,k,accum) return accum or (v.state == RESOLVED) end)
			local any_rejected = reduce(cur.upstream, false, function(v,k,accum) return accum or (v.state == REJECTED) end)
			local all_resolved = reduce(cur.upstream, true, function(v,k,a) return a and (v.state == RESOLVED) end)
			local all_rejected = reduce(cur.upstream, true, function(v,k,a) return a and (v.state == REJECTED) end)
			if #cur.upstream == 0 then
				all_resolved = false
				all_rejected = false
			end
			local first_resolved = reduce(cur.upstream, nil,
				function(v,k,a)
					if (not a) and (v.state == RESOLVED) then
						return v
					end
					return a
				end
			)
			local first_rejected = reduce(cur.upstream, nil,
				function(v,k,a)
					if (not a) and (v.state == REJECTED) then
						return v
					end
					return a
				end
			)

			if cur.mode == ANY then
				if any_resolved then
					if cur.state == WAITING then
						cur:resolve(R.unwrap(first_resolved))
					elseif cur.state == RESOLVING then
						cur:finish()
					end
					unhandled_rejection = false
				elseif all_rejected then
					if cur.state == REJECTING then
						cur:finish()
					else
						cur:reject(first_rejected.err)
						if (cur.reject_callback == nil) then
							unhandled_rejection = true
							unhandled_rejection_msg = first_rejected.err
							--print("passing unhandled_rejection = " .. tostring(unhandled_rejection))
						else
							unhandled_rejection = false
						end
					end
				end
			elseif cur.mode == ALL then
				if any_rejected then
					if cur.state == REJECTING then
						cur:finish()
					else
						cur:reject(first_rejected.err)
						if (cur.reject_callback == nil) then
							unhandled_rejection = true
							unhandled_rejection_msg = first_rejected.err
							--print("passing unhandled_rejection = " .. tostring(unhandled_rejection))
						else
							unhandled_rejection = false
						end
					end
				elseif all_resolved then
					if cur.state == RESOLVING then
						cur:finish()
					else
						cur:resolve(map(cur.upstream, function(v) return (((type(v) == "table") and v.value) or v) end))
					end
					unhandled_rejection = false
					--print("dbg: should reset unhandled rejection flag? #2")
				end
			end -- if mode
			
			--if cur.state == REJECTED and cur.reject_callback == nil and not unhandled_rejection then
			--	unhandled_rejection = true
			--	unhandled_rejection_msg = "Unhandled promise rejection at " .. quick_trace(" > ")
			--	break
			--end
			
		end -- if not finished

		if cur.state == ABORT or cur.state == WAITING or abort_chain then
			unhandled_rejection = false
			break
		end

		if not repeat_chain_element then
			cur = cur.downstream
		end
	end -- element loop
	abort_chain = false
	
	--if (cur ~= nil) and (cur.downstream == nil) and (cur.state == REJECTED) and (cur.reject_callback == nil) then
	if unhandled_rejection then
		error("Unhandled promise rejection: " .. tostring(unhandled_rejection_msg))
	end
	--print(" ---------- CHAIN END ---------")
	processing_chain_now = false
end


-- When a resolve callback returns a promise, inserts it as downstream of current
local function insert_next(r, n) --, is_resolve_return)
	
	if debug_prints then
		local debug_downstream_name
		if r.downstream then
			debug_downstream_name = r.downstream.debug_name or "(anon)"
		else
			debug_downstream_name = "(nil)"
		end
		print("Inserting " .. (n.debug_name or "(anon)") .. " between " .. (r.debug_name or "(anon)") .. " and " .. debug_downstream_name)
	end
	
	n.downstream = r.downstream
	--if #(n.upstream) == 0 then
	table.insert(n.upstream, r)
	--end
	r.downstream = n
	if n.downstream ~= nil then
		--for k,v in pairs(n.downstream.upstream) do
		--	if v == r then
		--		n.downstream.upstream[k] = nil
		--	end
		--end
		n.downstream.upstream = filter(n.downstream.upstream, function(v) return v ~= r end)
		table.insert(n.downstream.upstream, n)
	end
end

local function insert_previous(r, prev)
	--table.insert(r.upstream, prev)
	prev.upstream = r.upstream
	prev.downstream = r
	r.upstream = { prev }
end

-----------------------
--  PROMISE "CLASS"  --
-----------------------

function R.new(resolve_callback, reject_callback, debug_name)
	local P =
	{
		object_type = promise_object_type,
		state = WAITING,
		finished = false,
		value = nil, -- This line is more documentation than function
		err = nil,
		resolve_callback = resolve_callback,
		reject_callback = reject_callback,
		mode = ANY,
		upstream = {},  -- List of promises this one is waiting for
		downstream = nil, -- Next in sequence, a single promise
		timeout = nil,
		debug_name = debug_name,
	}

	function P:resolve(value)
		local from_where = debug.getinfo(2, "Sln")
		if debug_prints then
			print("Resolving " .. (self.debug_name or "anon") .. " from " .. from_where.short_src .. ":" .. from_where.currentline .. " " .. from_where.name .. "()")
		end
		self.state = RESOLVING
		self.err = nil
		if self.resolve_callback then
			local ok, result = pcall(self.resolve_callback, R.unwrap(value))
			if is_promise(result) then
				--insert_next(self, result)
				insert_previous(self, result)
				--self.state = RESOLVED
				--self.finished = true
				if result.state == WAITING then
					abort_chain = true
				else
					repeat_chain_element = true
				end
			elseif ok then
				--print("resolved")
				self.value = result
				self.state = RESOLVED
				self.finished = true
			else
				--print("Error in resolve callback, rejecting: " .. tostring(result))
				self:reject(result)
			end
		else
			self.value = value
			self.state = RESOLVED
			self.finished = true
		end
		chain(self)
		return self
	end

	function P:reject(err)
		local from_where = debug.getinfo(2, "Sln")
		if debug_prints then
			print("Rejecting " .. (self.debug_name or "anon") .. " from " .. from_where.short_src .. ":" .. from_where.currentline .. " " .. from_where.name)
		end
		self.state = REJECTING
		self.value = nil
		if self.reject_callback then
			--self.value = self.reject_callback(err)
			local ok, result = pcall(self.reject_callback, err)
			if is_promise(result) then
				--insert_next(self, result)
				insert_previous(self, result)
				self.state = RESOLVING
				--self.finished = true
				if result.state == WAITING then
					abort_chain = true
				else
					repeat_chain_element = true
				end
			elseif ok then
				self.value = result
				self.state = RESOLVED
				self.finished = true
			else
				self.err = result or err
				self.state = REJECTED
				self.finished = true
			end
		else
			self.err = err
			self.state = REJECTED
			self.finished = true
		end
		chain(self)
		return self
	end
	
	function P:finish()
		if self.state == RESOLVING then
			self.state = RESOLVED
		elseif self.state == REJECTING then
			self.state = REJECTED
		end
		self.finished = true
	end

	function P:next(next_resolve_callback, next_reject_callback, debug_name)
		local nx = R.new(next_resolve_callback, next_reject_callback, debug_name)
		--table.insert(nx.upstream, self)
		--print("setting downstream")
		--self.downstream = nx
		insert_next(self, nx)
		chain(self)
		return nx
	end

	function P:catch(catch_reject_callback)
		local ret = self:next(nil, catch_reject_callback)
		return ret
	end

	function P:can_finish()
		local ret
		if self.mode == ANY then
			ret = true
			for _,up in ipairs(self.upstream) do
				if up.finished then
					return up.state
				end
			end
		elseif self.mode == ALL then

		end
		return true
	end
	
	function P:is_waiting()
		return self.state == WAITING
	end
	
	function P:is_resolved()
		return self.state == RESOLVED
	end
	
	function P:is_rejected()
		return self.state == REJECTED
	end
	
	--print("new promise\n" .. tostring(P))
	return P
end


---------------------------------
--  NAMESPACE LEVEL FUNCTIONS  --
---------------------------------

function R.resolve(value)
	--print("R.resolve")
	local ret = R.new():resolve(value)
	return ret, 0 -- trash to avoid tail call
end

function R.reject(err)
	--print("R.reject")
	local ret = R.new():reject(err)
	return ret, 0 -- trash to avoid tail call
end

-- Can accept multiple arguments, or a table of promise objects
function R.any(...)
	local nargs = select("#", ...)
	local ret = R.new()
	local cur_arg
	for i=1,nargs do
		cur_arg = select(i, ...)
		if (nargs == 1) and (type(cur_arg) == "table") then
			for _,p in pairs(cur_arg) do
				table.insert(ret.upstream, R.wrap(p))
			end
		else
			table.insert(ret.upstream, R.wrap(cur_arg))
		end
	end
	chain(ret)
	return ret, 0 -- trash to avoid tail call
end

-- Can accept multiple arguments, or a table of promise objects
function R.all(...)
	local nargs = select("#", ...)
	local ret = R.new()
	ret.mode = ALL
	local cur_arg
	local p
	for i=1,nargs do
		cur_arg = select(i, ...)
		if is_promise(cur_arg) then
			table.insert(ret.upstream, cur_arg)
			cur_arg.downstream = ret
		else
			for _,p in ipairs(cur_arg) do
				if is_promise(p) then
					table.insert(ret.upstream, p)
					p.downstream = ret
				end
			end
		end
		--if (nargs == 1) and (type(cur_arg) == "table") then
		--	for _,p in pairs(cur_arg) do
		--		table.insert(ret.upstream, R.wrap(p))
		--	end
		--else
		--	table.insert(ret.upstream, R.wrap(cur_arg))
		--end
	end
	chain(ret)
	return ret, 0 -- trash to avoid tail call
end

function R.wrap(value)
	if is_promise(value) then
		return value
	else
		local ret = R.new()
		ret.state = RESOLVED
		ret.value = value
		ret.finished = true
		return ret
	end
end

function R.unwrap(p)
	if is_promise(p) then
		if p.state == RESOLVED then
			return p.value
		end
	else
		return p
	end
end

-- Aborts the promise chain when returned from a resolve or reject handler.
-- This means no catch()/error handlers will be called.
function R.abort() 
	local ret = R.new()
	ret.state = ABORT
	return ret
end

function debug_promise_chain_str(promise_obj)
	local p = promise_obj
	local ret = "(chain start)"
	while p.upstream[1] do
		p = p.upstream[1]
	end
	local is_cur_str = ""
	while p.downstream do
		if p == promise_obj then is_cur_str = "*"
		else is_cur_str = ""
		end
		ret = ret .. " -> " .. is_cur_str .. (p.debug_name or "anon") .. "(" .. p.state .. ")"
	end
	return ret
end

local function test01()
	local p = R.new()
	p:next(function (r)
		local testing_intentional_error = nil
		testing_intentional_error[1] = 1
	end):next(function (r)
		print("TEST FAILED: Should not call this resolve, instead should be doing a catch()")
		return 3
	end):catch(function (err)
		print("TEST OK: promise test01() err = " .. tostring(err))
	end)
	p:resolve(1)
end

local function test02(bool_resolve_before_next)
	local outer = R.new(nil, nil, "outer")
	local inner
	if bool_resolve_before_next then
		print("Calling outer resolve")
		outer:resolve(1)
	end
	outer:next(
		function(v)
			print("#1 outer n1")
			inner = R.new(
			--return inner:next(
				function(v)
					print("#2 inner 1")
				end,
				nil, "inner_1"
			)
			return inner:next(
				function(v)
					print("#3 inner n2")
				end,
				nil, "inner_n2"
			)
		end,
		nil,"outer_n1"
	):next(
		function(v)
			print("#4 outer n2")
		end,
		nil, "outer_n2"
	)
	if not bool_resolve_before_next then
		print("Calling outer resolve")
		outer:resolve(1)
	end
	print("Calling inner resolve")
	inner:resolve(1)
end

local function test03()
	local all = R.new()
	local works = R.new()
	R.all(all, works):next(
		function(t)
			for _,v in pairs(t) do
				print(v)
			end
		end
	)
	all:resolve("all()")
	print("This should appear before 'all() works'")
	works:resolve("works")
	print("This should appear after 'all() works'")
end

if windower == nil then
	print("--------- Test error handling -------------")
	test01()
	print("--------- Test inner/outer pre-resolve -------------")
	test02(false)
	print("--------- Test inner/outer post-resolve -------------")
	test02(true)
	print("--------- Test Promise.all() -------------")
	test03()
end

return R
