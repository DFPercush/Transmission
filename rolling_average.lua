
local RA = {}

function RA.new()
	local self = {
		cached_average = nil,
		capacity = 20,
		current_index = 1,
		wrapped = false,
		values = {},
	}
	function self.add(value)
		self.cached_average = nil
		self.values[self.current_index] = value
		self.current_index = self.current_index + 1
		if (self.current_index > self.capacity) then
			self.current_index = 1
			self.wrapped = true
		end
	end

	function self.fill(value)
		for i=1,self.capacity do
			self.values[i] = value
		end
		self.wrapped = true
		self.current_index = 1
	end

	function self.clear(capacity_optional)
		self.cached_average = nil
		self.capacity = capacity_optional or 20
		self.current_index = 1
		self.wrapped = false
		self.values = {}
	end

	function self.set_capacity(new_capacity)
		self.cached_average = nil
		local new_values = {}
		local count = 0
		if self.wrapped then
			for i = self.current_index, self.capacity do
				count = count + 1
				if (count > new_capacity) then break end
				new_values[count] = self.values[i]
			end
			for i=1,self.current_index - 1 do
				count = count + 1
				if (count > new_capacity) then break end
				new_values[count] = self.values[i]
			end
		else
			for i=1,self.current_index - 1 do
				count = count + 1
				if (count > new_capacity) then break end
				new_values[count] = self.values[i]
			end
		end
		self.values = new_values
		self.capacity = new_capacity
		if (count >= new_capacity) then
			self.wrapped = true
			self.current_index = 1
		else
			self.wrapped = false
			self.current_index = count + 1
		end
	end

	function self.get_average()
		local sum = 0
		local count
		if (self.cached_average ~= nil) then return self.cached_average end
		if self.wrapped then
			count = self.capacity
		else 
			count = self.current_index - 1
		end
		if count == 0 then return 0 end
		for i=1,count do
			sum = sum + self.values[i]
		end
		self.cached_average = sum / count
		return self.cached_average
	end

	function self.get_count()
		if self.wrapped then
			return capacity
		else
			return current_index - 1
		end
	end

	return self
end

return RA
