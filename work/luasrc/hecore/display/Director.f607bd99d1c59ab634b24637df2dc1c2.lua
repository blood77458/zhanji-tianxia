require "hecore.display.Scene"

--
-- Director ---------------------------------------------------------
--

-- initialize
local instance = nil;
local globalUpdateID = -1;
local sceneStack={};
Director = {resourceAnimationFPS = 30, gameFPS = 30, __runningScene = nil};

function Director.sharedDirector()
	if not instance then
		instance = Director;
		print("=========================Startup Director============================");
		
		--update
		if globalUpdateID > -1 then CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(globalUpdateID) end
		local function onUpdateGlobal(dt)
			local runningScene = Director.__runningScene;
			if runningScene then runningScene:onUpdate(dt) end;
		end
		globalUpdateID = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(onUpdateGlobal,0,false);
	end
	return instance;
end

--
-- public props -------------------
--

function Director:getAnimationInterval() return CCDirector:sharedDirector():getAnimationInterval() end;
function Director:isDisplayStats() return CCDirector:sharedDirector():isDisplayStats() end;
function Director:setDisplayStats(v) CCDirector:sharedDirector():setDisplayStats(v) end;
function Director:isPaused() return CCDirector:sharedDirector():isPaused() end;
function Director:getTotalFrames() return CCDirector:sharedDirector():getTotalFrames() end;
function Director:getWinSize() return CCDirector:sharedDirector():getWinSize() end;
function Director:getWinSizeInPixels() return CCDirector:sharedDirector():getWinSizeInPixels() end;
function Director:getContentScaleFactor() return CCDirector:sharedDirector():getContentScaleFactor() end;
function Director:getZEye() return CCDirector:sharedDirector():getZEye() end;
--CCScheduler
function Director:getScheduler() return CCDirector:sharedDirector():getScheduler() end;
--CCActionManager
function Director:getActionManager() return CCDirector:sharedDirector():getActionManager() end;
--CCTouchDispatcher
function Director:getTouchDispatcher() return CCDirector:sharedDirector():getTouchDispatcher() end;
--CCKeypadDispatcher
function Director:getKeypadDispatcher() return CCDirector:sharedDirector():getKeypadDispatcher() end;
--CCAccelerometer
function Director:getAccelerometer() return CCDirector:sharedDirector():getAccelerometer() end;
--CCNode
function Director:getNotificationNode() return CCDirector:sharedDirector():getNotificationNode() end;
--CCSize
function Director:getVisibleSize() return CCDirector:sharedDirector():getVisibleSize() end;
--CCPoint
function Director:getVisibleOrigin() return CCDirector:sharedDirector():getVisibleOrigin() end;
--CCPoint
function Director:convertToGL(v) return CCDirector:sharedDirector():convertToGL(v) end;
function Director:convertToUI(v) return CCDirector:sharedDirector():convertToUI(v) end;
--CCEGLViewProtocol
function Director:getOpenGLView() return CCDirector:sharedDirector():getOpenGLView() end;
--ccDirectorProjection
function Director:getProjection() return CCDirector:sharedDirector():getProjection() end;
function Director:setProjection(v) CCDirector:sharedDirector():setProjection(v) end;

--
-- public control -------------------
--

function Director:pause() CCDirector:sharedDirector():pause() end;
function Director:resume() CCDirector:sharedDirector():resume() end;
function Director:purgeCachedData() CCDirector:sharedDirector():purgeCachedData() end;

local function indexOf(scene)
	if not scene then return -1 end;
	local idx = -1;
	for i, v in ipairs(sceneStack) do
		if v == scene then
			idx = i;
			break;
		end
	end
	return idx;
end

function Director:numOfStack()
	return #sceneStack
end

function Director:getRunningScene()
	local s = CCDirector:sharedDirector():getRunningScene();
	for i, v in ipairs(sceneStack) do
		if v.refCocosObj == s then return v end;
	end
	return nil;
end

function Director:runWithScene(s)
	local idx = indexOf(s);
	if s and idx == -1 then
		table.insert(sceneStack, s);
		CCDirector:sharedDirector():runWithScene(s.refCocosObj);
		s:onEnter();
		self.__runningScene = s;
	end
end

function Director:pushScene(s,params)
	local idx = indexOf(s);
	if s and idx == -1 then
		local runningScene_ = self:getRunningScene();
		table.insert(sceneStack, s);
		
		CCDirector:sharedDirector():pushScene(s.refCocosObj);
		s:onEnter(params);
		self.__runningScene = s;
        
		if runningScene_ then
			runningScene_.touchEnabled = false;
			s.touchEnabled = false;
			local onResetPrevSceneFunc = -1;
			local function onResetPrevScene()
				runningScene_.touchEnabled = true;
				s.touchEnabled = true;
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(onResetPrevSceneFunc);
			end
			onResetPrevSceneFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(onResetPrevScene,0.35,false);
		end
	end
end

function Director:popToRootScene(paramsToRootScene)
  local s = self:getRunningScene();
  local rootScene = sceneStack[1];
  if (not s) or (not rootScene) or (s == rootScene) then return end;
  
  for i = #sceneStack, 2, -1 do
    local current = sceneStack[i];
    CCDirector:sharedDirector():popScene();
    current:onExit();
    current:dispose();
    table.remove(sceneStack, i);
  end
  
  rootScene:onEnter(paramsToRootScene);
end
function Director:popScene(cleanup, paramsToPrevScene)
	local s = self:getRunningScene();
	if s then
		local idx = indexOf(s);
		if idx ~= -1 then table.remove(sceneStack, idx) end;
		CCDirector:sharedDirector():popScene();
		s:onExit();
		local isCleanup = true;
		if cleanup ~= nil then isCleanup = cleanup end;
		if isCleanup then s:dispose() end;
    
		local length = table.getn(sceneStack); 
		if length > 0 then
		    sceneStack[length]:onEnter(paramsToPrevScene);
		    self.__runningScene = sceneStack[length];
		else
		    self.__runningScene = nil;
		end
    
		local runningScene_ = self.__runningScene;
		if runningScene_ then runningScene_.touchEnabled = false end;
		s.touchEnabled = false;
		local onResetPrevSceneFunc = -1;
		local function onResetPrevScene()
		  if runningScene_ then runningScene_.touchEnabled = true end;
		  s.touchEnabled = true;
		  CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(onResetPrevSceneFunc);
		end
		onResetPrevSceneFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(onResetPrevScene,0.35,false);
	end
end

function Director:replaceScene(s)
	local currentRunningScene = nil;
	local currentRunningIndex = -1;
	--print("replaceScene", table.getn(sceneStack));
	
	local ccRunning = CCDirector:sharedDirector():getRunningScene();
	for i, v in ipairs(sceneStack) do
		if v.refCocosObj == ccRunning then
			currentRunningScene = v;
			currentRunningIndex = i;
			break;
		end
	end

	local idx = indexOf(s);
	if idx == -1 then
		table.insert(sceneStack, s);
		CCDirector:sharedDirector():replaceScene(s.refCocosObj);
		s:onEnter();
		self.__runningScene = s;

		if currentRunningScene then 
		  currentRunningScene:onExit();
		  currentRunningScene:dispose();
		  if currentRunningIndex ~= -1 then table.remove(sceneStack, currentRunningIndex) end;
		end
	end

	local runningScene_ = currentRunningScene;
	if runningScene_ then runningScene_.touchEnabled = false end;

	-- 注释掉这里解决新手引导的bug
	-- s.touchEnabled = false;
	-- local onResetPrevSceneFunc = -1;
	-- local function onResetPrevScene()
    -- if runningScene_ then runningScene_.touchEnabled = true end;
		-- s.touchEnabled = true;
		-- CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(onResetPrevSceneFunc);
	-- end
	-- onResetPrevSceneFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(onResetPrevScene,0.35,false);

end

--short name
Director.mgr = Director.sharedDirector
Director.run = Director.getRunningScene
Director.push = Director.pushScene
Director.pop = Director.popScene
Director.rep = Director.replaceScene