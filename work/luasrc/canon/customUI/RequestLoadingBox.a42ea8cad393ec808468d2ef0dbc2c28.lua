local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local loadingLayer_zOrder = 100002
local loadingLayer = nil

local loadingRefCount = 0

RequestLoadingBox = class()
function RequestLoadingBox:createLoadingBox(enableTouch)
	if not loadingLayer and g_isRetryShowing == 0 then
		loadingLayer = Layer:create()
		--loadingLayer:setColor(ccc3( 0, 0, 0 ))
		--loadingLayer.refCocosObj:setOpacity( 170 )
		--loadingLayer:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
		--loadingLayer:setPosition(ccp( 0, 0 ))

		local loadingSprite = FlashSprite:create("EVO2/Loading_lvbu")
		math.randomseed(os.time())
		local rand = math.random(3) - 1
		loadingSprite:changeAnimation(rand)
		loadingLayer:addChild(CocosObject.new(loadingSprite))

		local function onTouch(event, x, y)
			if event == CCTOUCHBEGAN then
				return true
			else
				return
			end
		end
		loadingLayer:registerScriptTouchHandler(onTouch, false, -100, true)
		loadingLayer:setTouchEnabled(true)
    
    local RunningScene = Director:sharedDirector():getRunningScene()
    if RunningScene ~= nil then
      if RunningScene.rootLayer ~= nil then
        CCDirector:sharedDirector():getRunningScene():addChild(loadingLayer.refCocosObj, loadingLayer_zOrder)
      end
    end
		
		loadingLayer:setVisible(false)
	end
	loadingRefCount = loadingRefCount + 1;
end

function RequestLoadingBox:showLoadingBox()
	if loadingLayer and loadingLayer.refCocosObj then
		loadingLayer:setVisible(true)
	end
end

function RequestLoadingBox:removeLoadingBox()
	loadingRefCount = loadingRefCount - 1;
	if loadingRefCount <= 0 then
		loadingRefCount = 0
		if loadingLayer and loadingLayer.refCocosObj then
			loadingLayer.refCocosObj:removeFromParentAndCleanup(true)
		end
		loadingLayer = nil
	end
end

function RequestLoadingBox.isExist()
	return loadingLayer ~= nil
end
