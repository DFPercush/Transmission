
--require("util")

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
local promise_object_type = this_file .. "<promise>"
local function is_promise(x)
	return type(x) == "table" and x.object_type == promise_object_type
end

-- Used to avoid recursion
local processing_chain_now = false
local function chain(p)
	if processing_chain_now then return end
	processing_chain_now = true
	local cur = p --.downstream
	
	--print( "------- CHAIN START ---------")
	--local dbg_str = "Chain started:"
	--local dbg_next_obj = p
	--while dbg_next_obj do
	--	dbg_str = dbg_str .. " -> " .. (dbg_next_obj.debug_name or "anon")
	--	dbg_next_obj = dbg_next_obj.downstream
	--end
	--print(dbg_str)
	
	--local prev = p
	local unhandled_rejection = false
	local unhandled_rejection_msg = ""
	while cur do --.can_finish() do
		--print("chain() cur.state ==" .. cur.state .. ", downstream is " .. tostring(cur.downstream and cur.downstream.state) .. ", unhandled_rejection == " .. tostring(unhandled_rejection))
		if cur.state == ABORT then return end
		if cur.state == WAITING and #(cur.upstream) > 0 then
			local any_resolved = reduce(cur.upstream, false, function(v,k,accum) return accum or (v.state == RESOLVED) end)
			local any_rejected = reduce(cur.upstream, false, function(v,k,accum) return accum or (v.state == REJECTED) end)
			local all_resolved = reduce(cur.upstream, true, function(v,k,a) return a and (v.state == RESOLVED) end)
			local all_rejected = reduce(cur.upstream, true, function(v,k,a) return a and (v.state == REJECTED) end)
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
					cur:resolve(R.unwrap(first_resolved))
					unhandled_rejection = false
				elseif all_rejected then
					cur:reject(first_rejected.err)
					if (cur.reject_callback == nil) then
						unhandled_rejection = true
						unhandled_rejection_msg = first_rejected.err
						--print("passing unhandled_rejection = " .. tostring(unhandled_rejection))
					else
						unhandled_rejection = false
					end
				end
			elseif cur.mode == ALL then
				if any_rejected then
					cur:reject(first_rejected.err)
					if (cur.reject_callback == nil) then
						unhandled_rejection = true
						unhandled_rejection_msg = first_rejected.err
						--print("passing unhandled_rejection = " .. tostring(unhandled_rejection))
					else
						unhandled_rejection = false
					end
				elseif all_resolved then
					cur:resolve(map(cur.upstream, function(v) return v.value end))
					unhandled_rejection = false
					--print("dbg: should reset unhandled rejection flag? #2")
				end
			end
		end

		if cur.state == ABORT or cur.state == WAITING then
			unhandled_rejection = false
			break
		end

		cur = cur.downstream
	end
	
	--if (cur ~= nil) and (cur.downstream == nil) and (cur.state == REJECTED) and (cur.reject_callback == nil) then
	if unhandled_rejection then
		error("Unhandled promise rejection: " .. tostring(unhandled_rejection_msg))
	end
	--print(" ---------- CHAIN END ---------")
	processing_chain_now = false
end


-- When a resolve callback returns a promise, inserts it as downstream of current
local function insert_next(r, n)
	n.downstream = r.downstream
	r.downstream = n
	if n.downstream ~= nil then
		for k,v in pairs(n.downstream.upstream) do
			if v == r then
				n.downstream.upstream[k] = nil
			end
		end
		table.insert(n.downstream.upstream, n)
	end
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
		--print("resolve from " .. from_where.short_src .. ":" .. from_where.currentline .. " " .. from_where.name)
		self.state = RESOLVING
		self.err = nil
		if self.resolve_callback then
			local ok, result = pcall(self.resolve_callback, R.unwrap(value))
			if is_promise(result) then
				insert_next(self, result)
				self.state = RESOLVED
				self.finished = true
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
		--print("reject")
		self.state = REJECTING
		self.value = nil
		if self.reject_callback then
			--self.value = self.reject_callback(err)
			local ok, result = pcall(self.reject_callback, err)
			if is_promise(result) then
				insert_next(self, result)
				self.state = RESOLVED
				self.finished = true
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

	function P:next(next_resolve_callback, next_reject_callback, debug_name)
		local nx = R.new(next_resolve_callback, next_reject_callback, debug_name)
		table.insert(nx.upstream, self)
		--print("setting downstream")
		self.downstream = nx
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

local function test02()
	local outer = R.new(nil, nil, "outer")
	local inner
	--outer:resolve(1)
	outer:next(
		function(v)
			print("outer n1")
			inner = R.new(
			--return inner:next(
				function(v)
					print("inner 1")
				end,
				nil, "inner_1"
			)
			return inner:next(
				function(v)
					print("inner n2")
				end,
				nil, "inner_n2"
			)
		end,
		nil,"outer_n1"
	):next(
		function(v)
			print("outer n2")
		end,
		nil, "outer_n2"
	)
	print("Calling outer resolve")
	outer:resolve(1)
	print("outer resolve control returned, now calling inner resolve")
	inner:resolve(1)
end

--test01()
--test02()
return R
