local ret = {}

function ret.printTable(tbl)
	for k, v in pairs(tbl) do
		print(k, v)
	end
end

return ret
