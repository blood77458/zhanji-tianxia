--
-- CanonButton.lua
-- Author: zheng.che
-- Date: 2014-05-09 16:34:09
-- canon定制按钮组件
--

CanonButton = class(Button)

------------------------------------------------------------------------------------------------------------------------------------创建

function CanonButton:create(display, useLayerFrame)
	local button = CanonButton.new(display, useLayerFrame)
	button:initButton()
	button.useLayerFrame = useLayerFrame
	return button
end

------------------------------------------------------------------------------------------------------------------------------------对外接口


-------------------------------------------------
-- 设置按钮角标
-- aNum角标中数量 0表示不显示角标 最大位数由文本框长度决定
-------------------------------------------------
function CanonButton:setNum(aNum)
	local numDisplay = self:getNumDisplay()
	if numDisplay then
		if aNum <= 0 then
			numDisplay:setVisible(false)
		else
			numDisplay:setVisible(true)

			local bg2 = numDisplay:getChildByName("icn_tixing_kong")
			local bg3 = numDisplay:getChildByName("tips_big")
			if bg2 and bg3 then
				if aNum < 100 then
					--两位数
					bg2:setVisible(true)
					bg3:setVisible(false)
				else
					--大于两位数
					bg2:setVisible(false)
					bg3:setVisible(true)
				end
			end

			numDisplay:getChildByName("txt"):setString(tostring(aNum))
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------私用

function CanonButton:ctor( display, useLayerFrame )
	CanonButton.super.ctor(self, display, useLayerFrame)
end

function CanonButton:initButton()
	Button.initButton(self)

	local numDisplay = self:getNumDisplay()
	if numDisplay then
		numDisplay:setVisible(false)
	end
end

function CanonButton:getNumDisplay()
	if not self.display then
		print("getNumDisplay self.display is nil! ")
		return nil
	end
	local result = self.display:getChildByName("num")
	return result
end