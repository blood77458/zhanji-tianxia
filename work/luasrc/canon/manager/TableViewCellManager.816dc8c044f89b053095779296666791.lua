-- TableViewCellManager.lua
-- 2015-3-6
-- zheng.che
-- tableview单元格管理器

TableViewCellManager = {}

function TableViewCellManager.setTableIndexTxt(table, key, display, index)
	if not table.currentIndex then
		table.currentIndex = -5000
	end
	if not table.hash then
		table.hash = {}
		local mode = {__mode = "v"}
		setmetatable(table.hash, mode)--弱引用 防止内存泄露
	end

	table.hash[key] = 1
end


function TableViewCellManager.addNameTag(table, name)
	if not table.currentIndex then
		table.currentIndex = -5000
	end
	if not table.hash then
		table.hash = {}
		local mode = {__mode = "v"}
		setmetatable(table.hash, mode)--弱引用 防止内存泄露
	end

	table.hash[key] = 1
end
