--
-- ListView.lua
-- Author: zheng.che
-- Date: 2014-04-30 10:31:55
-- 列表UI组件
--

ListView = class()

----------------------------------------------
-- 初始化
----------------------------------------------
function ListView:ctor()
	--元件列表
	self.cellList = {}
	--数据列表
	self.dataList = {}

	--添加数据cb
	self.setDataCB = nil
	--清除数据cb
	self.removeDataCB = nil
	--销毁cb
	self.disposeCB = nil
end

--------------------------------------------------------------------------------------------------------------------------------------------初始化接口

----------------------------------------------
-- 创建
----------------------------------------------
function ListView:create(setDataCB, removeDataCB, cilckCellCB, disposeCB)
	local s = ListView.new()
	s:setCallback(setDataCB, removeDataCB, cilckCellCB, disposeCB)
	return s
end

----------------------------------------------
-- 初始化回调接口
-- setDataCB(aCell) 装填新数据时调用(aCell.data为nil表示装填了空数据 这里会自动隐藏)
-- removeDataCB(aCell) 装填新数据之前 or 销毁之前 调用 此时aCell.data可能有值
-- cilckCellCB(evt={context=cell}) 点击cell时调用
-- disposeCB(aCell) 销毁时调用 此时aCell.data应该是空的
----------------------------------------------
function ListView:setCallback(setDataCB, removeDataCB, cilckCellCB, disposeCB)
	self.setDataCB = setDataCB
	self.removeDataCB = removeDataCB
	self.cilckCellCB = cilckCellCB
	self.disposeCB = disposeCB
end

--------------------------------------------------------------------------------------------------------------------------------------------对外查询接口

----------------------------------------------
-- 获得能显示的最大个数
----------------------------------------------
function ListView:getCellCount()
	return #self.cellList
end

--------------------------------------------------------------------------------------------------------------------------------------------对外操作接口

----------------------------------------------
-- 关联资源
-- containerDisplay  容器资源 列表项要放在在此元件中
-- listNameFlag 列表项命名共同点 (如美术提供的是"icon1", "icon2"等等, 则应该填"icon") 默认不填是"list" 因此最好美术直接提供"list+数字"命名的元件
----------------------------------------------
function ListView:setDisplay(containerDisplay, listNameFlag)
	if not listNameFlag then
		listNameFlag = "list"
	end
	for i = 1, 100 do
		local child = containerDisplay:getChildByName(listNameFlag .. i)
		if child then
			local cell = {}
			cell.displayIndex = i
			cell.display = child
			table.insert(self.cellList, cell)

			if self.cilckCellCB then
				--可点击
				local cellBtn = Button:create(child)
				cellBtn:addEventListener(Events.kStart, self.cilckCellCB, cell)
			end
		else
			break
		end
	end
end

----------------------------------------------
-- 填入数据列表
-- aDataList要显示的数据内容数组
----------------------------------------------
function ListView:setDataList(aDataList)
	self.dataList = aDataList or {}

	for k, aCell in ipairs(self.cellList) do
		--先清除数据
		if aCell.data ~= nil then
			self:cellRemoveData(aCell)
		end

		--开始装填新数据
		local aData = self.dataList[k]
		aCell.dataIndex = k
		aCell.data = aData
		self:cellSetData(aCell)
	end
end

----------------------------------------------
-- 刷新显示
----------------------------------------------
function ListView:refresh()
	self:setDataList(self.dataList)
end

----------------------------------------------
-- 销毁
----------------------------------------------
function ListView:dispose()
	for k, aCell in ipairs(self.cellList) do
		self:cellRemoveData(aCell)
		aCell.data = nil
		self:cellDisopse(aCell)
	end
	
	self.cellList = {}
	self.dataList = {}
	self.setDataCB = nil
	self.removeDataCB = nil
	self.disposeCB = nil
end

--------------------------------------------------------------------------------------------------------------------------------------------内部cell操作接口 禁止外部调用

----------------------------------------------
-- 单元设置数据
----------------------------------------------
function ListView:cellSetData(aCell)
	aData = aCell.data
	if aData == nil then
		--没有数据 默认不显示
		aCell.display:setVisible(false)
	else
		--有数据 显示
		aCell.display:setVisible(true)
	end

	if self.setDataCB then
		self.setDataCB(aCell)
	end
end

----------------------------------------------
-- 单元移除数据
----------------------------------------------
function ListView:cellRemoveData(aCell)
	if self.removeDataCB then
		self.removeDataCB(aCell)
	end
end

----------------------------------------------
-- 单元销毁
----------------------------------------------
function ListView:cellDisopse(aCell)
	if self.disposeCB then
		self.disposeCB(aCell)
		aCell.displayIndex = nil
		aCell.display = nil
	end
end