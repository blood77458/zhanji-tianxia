-- PageListView.lua
-- 2014-11-12
-- zheng.che
-- 带翻页的列表显示

PageListView = class()

----------------------------------------------
-- 初始化
----------------------------------------------
function PageListView:ctor()
	self.currentPageIndex = 0
	self.dataList = {}
	self.listView = nil
	self.display = nil
	self.params = {}
end

--------------------------------------------------------------------------------------------------------------------------------------------初始化接口

----------------------------------------------
-- 创建
----------------------------------------------
function PageListView:create(listView)
	local s = PageListView.new()
	s:init(listView)
	return s
end

----------------------------------------------
-- 初始化接口
----------------------------------------------
function PageListView:init(listView)
	self.listView = listView
end

--------------------------------------------------------------------------------------------------------------------------------------------对外查询接口

function PageListView:getCurrentPageIndex()
	return self.currentPageIndex
end

function PageListView:getMaxPageNum()
	if not self.listView then
		return 0
	end

	local count = #self.dataList
	local cellCount = self.listView:getCellCount()

	local reslut = math.floor((count-1) / cellCount) + 1
	return reslut
end

--------------------------------------------------------------------------------------------------------------------------------------------对外操作接口

----------------------------------------------
-- 关联资源
-- containerDisplay  容器资源
-- params 配置参数
-- params.prevBtnName 上一页按钮层名称
-- params.nextBtnName 下一页按钮层名称
-- params.pageTextName 页码文本框层名称
-- params.pageTextInfoName 页码说明文字层名称
----------------------------------------------
function PageListView:setDisplay(containerDisplay, params)
	self.display = containerDisplay
	self.params = params
	if not self.params then
		self.params = {}
	end
	if not self.params.prevBtnName then
		self.params.prevBtnName = "btn_prev"
	end
	if not self.params.nextBtnName then
		self.params.nextBtnName = "btn_next"
	end
	if not self.params.pageTextName then
		self.params.pageTextName = "txt_page"
	end
	
	if self.params.pageTextInfoName then
		self.display:getChildByName(self.params.pageTextInfoName):getChildByName("txt"):setString(getTextByKey("cardExchange_choice_page"))--页码：
	end
	
	if self.params.prevBtnName then
		local function onPervBtnClick(evt)
			--
			--print("onPervBtnClick")
			if self:havePrev() then
				--print("havePrev")
				self:gotoPage(self.currentPageIndex - 1)
			end
		end
		self.display:getChildByName(self.params.prevBtnName):getChildByName("txt"):setString(getTextByKey("cardExchange_choice_previouspage"))--上一页
		local pervBtn = Button:create(self.display:getChildByName(self.params.prevBtnName))
		pervBtn:addEventListener(Events.kStart, onPervBtnClick, self)
	end
	
	if self.params.nextBtnName then
		local function onNextBtnClick(evt)
			--
			--print("onNextBtnClick")
			if self:haveNext() then
				--print("haveNext")
				self:gotoPage(self.currentPageIndex + 1)
			end
		end
		self.display:getChildByName(self.params.nextBtnName):getChildByName("txt"):setString(getTextByKey("cardExchange_choice_nextpage"))--下一页
		local nextBtn = Button:create(self.display:getChildByName(self.params.nextBtnName))
		nextBtn:addEventListener(Events.kStart, onNextBtnClick, self)
	end
end

----------------------------------------------
-- 填入数据列表
-- aDataList要显示的数据内容数组
----------------------------------------------
function PageListView:setDataList(aDataList)
	self.dataList = aDataList or {}
	if #self.dataList <= 0 then
		--没有第一页
		self:gotoPage(0)
	else
		self:gotoPage(1)
	end
end

----------------------------------------------
-- 刷新当前页
----------------------------------------------
function PageListView:refreshCurrentPage()
	self:gotoPage(self.currentPageIndex)
end

----------------------------------------------
-- 销毁
----------------------------------------------
function PageListView:dispose()
	if self.listView then
		self.listView:dispose()
	end
	self.currentPageIndex = 0
	self.dataList = {}
	self.listView = nil
	self.display = nil
	self.params = {}
end

--------------------------------------------------------------------------------------------------------------------------------------------内部操作接口

----------------------------------------------
-- 
----------------------------------------------
function PageListView:gotoPage(pageIndex)
	self.currentPageIndex = pageIndex
	local pageDataList = {}
	local cellCount = self.listView:getCellCount()

	local beginIndex = cellCount * (self.currentPageIndex-1) + 1
	local endIndex = beginIndex + cellCount
	-- print("self.currentPageIndex = " .. tostringRich(self.currentPageIndex))
	-- print("cellCount = " .. tostringRich(cellCount))
	-- print("beginIndex = " .. tostringRich(beginIndex))
	-- print("endIndex = " .. tostringRich(endIndex))
	for i = beginIndex, endIndex, 1 do
		local data = self.dataList[i]
		if data then
			table.insert(pageDataList, data)
		else
			break
		end
	end
	--print("pageDataList = " .. tostringRich(pageDataList))

	if self.listView then
		self.listView:setDataList(pageDataList)
	end

	local maxPageIndex = self:getMaxPageNum()
	if self.display and self.params.pageTextName then
		self.display:getChildByName(self.params.pageTextName):getChildByName("txt"):setString(self.currentPageIndex .. "/" .. maxPageIndex)
	end
end
----------------------------------------------
-- 
----------------------------------------------
function PageListView:havePrev()
	if self.currentPageIndex <= 1 then
		return false
	end
	return true
end
----------------------------------------------
-- 
----------------------------------------------
function PageListView:haveNext()
	local maxPageIndex = self:getMaxPageNum()
	--print("maxPageIndex = " .. tostringRich(maxPageIndex))
	if self.currentPageIndex >= maxPageIndex then
		return false
	end
	return true
end