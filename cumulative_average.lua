
local R = {}

function R.new()
	local ret = {
		average = 0,
		count = 0,
		accum_count = 0,
		accum_value = 0,
		latest_values = {},
	}
	function ret.add_value(self, value)
		self.latest_values[#self.latest_values+1] = value
		local sum = 0
		for _, v in pairs(self.latest_values) do
			sum = sum + v
		end
		if #self.latest_values > (self.accum_count / 1000) then
			self.accum_value = ((self.accum_value * self.accum_count) + (#self.latest_values * sum)) / (self.accum_count + #self.latest_values)
			self.accum_count = self.accum_count + #self.latest_values
			self.latest_values = {}
		end
		self.count = self.count + 1
		self.average = ((self.accum_value * self.accum_count) + (#self.latest_values * sum)) / (self.accum_count + #self.latest_values)
	end
	function ret.clear(self)
		self.average = 0
		self.count = 0
		self.accum_value = 0
		self.accum_count = 0
		self.latest_values = {}
	end
	return ret
end

return R
