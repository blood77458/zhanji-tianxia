---------------------------------
-- Author: l1ghtsaber
-- Date: 2015-02-10
-- 自定义位运算
---------------------------------

BitOperManager = {
	data = {}, --data[i]表示2的i-1次方
	maxbit = 32
}

function BitOperManager:ctor()
	for i = 1,self.maxbit do
		self.data[i] = 2^(i-1)
	end
end
BitOperManager:ctor()

function BitOperManager:ChangetoBit(fig,dig)
	if not dig then dig = self.maxbit end
	local tmp = fig
	local ret = {}
	for i = dig,1,-1 do
		if 2^(i-1) <= tmp then 
			tmp = tmp - 2^(i-1)
			ret[i] = 1
		else
			ret[i] = 0
		end 
	end
	return ret
end

function BitOperManager:ChangetoFig(bit,dig)
	if not dig then dig = self.maxbit end
	local tmp = 0
	for i = 1,dig do
		tmp = tmp + 2^(i-1)
	end
	return tmp
end

function BitOperManager:_and(a,b,d)
	if not d then d = self.maxbit end
	local op_a = self:ChangetoBit(a,d)
	local op_b = self:ChangetoBit(b,d)
	local ret = 0
	for i = 1,d do 
		if op_a[i] == 1 and op_b[i] == 1 then
			ret = ret + 2^(i-1)
		end 
	end
	return ret
end

function BitOperManager:_or(a,b,d)
	if not d then d = self.maxbit end
	local op_a = self:ChangetoBit(a,d)
	local op_b = self:ChangetoBit(b,d)
	local ret = 0
	for i = 1,d do 
		if op_a[i] == 1 or op_b[i] == 1 then
			ret = ret + 2^(i-1)
		end 
	end
	return ret
end

function BitOperManager:_xor(a,b,d)
	if not d then d = self.maxbit end
	local op_a = self:ChangetoBit(a,d)
	local op_b = self:ChangetoBit(b,d)
	local ret = 0
	for i = 1,d do 
		if op_a[i] ~= op_b[i] then
			ret = ret + 2^(i-1)
		end 
	end
	return ret
end

function BitOperManager:_shl(a,n,d)
	if not n then n = 1 end
	if not d then d = self.maxbit end
	local op_a = self:ChangetoBit(a,d)
	local ret = 0
	for i = d,n+1,-1 do 
		if op_a[i-n] == 1 then
			ret = ret + 2^(i-1)
		end 
	end
	return ret
end

function BitOperManager:_shr(a,n,d)
	if not n then n = 1 end
	if not d then d = self.maxbit end
	local op_a = self:ChangetoBit(a,d)
	local ret = 0
	for i = 1,d-n do 
		if op_a[i+n] == 1 then
			ret = ret + 2^(i-1)
		end 
	end
	return ret
end