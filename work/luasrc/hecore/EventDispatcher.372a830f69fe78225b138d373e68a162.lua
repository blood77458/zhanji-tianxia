-------------------------------------------------------------------------
--  Class include: Events, Event, DisplayEvents, DisplayEvent, EventDispatcher
-------------------------------------------------------------------------


require "hecore.class"

local debugEvent =false;

--
-- Events ---------------------------------------------------------
--
-- common event name we used in library.
Events = {
	kComplete = "complete",
	kCancel = "cancel",
	kConnect = "connect",
	kConfirm = "confirm",
	kError = "error",
	kStart = "start",
	kClose = "close",
	kAddToStage = "addToStage",
	kRemoveFromStage = "removeFromStage",
	kDispose = "disposing" ,
	kStartClickBegin = "startClickBegin"
}
--
-- Event ---------------------------------------------------------
--

Event = class();
function Event:ctor(name, data, target)
	self.name  = name;
	self.data = data;
	self.target = target;
	self.code = 0;
	self.context = nil;
end
function Event:dispose()
	self.name = nil;
	self.target = nil;
	self.data = nil;
	self.context = nil;
end
function Event:toString()
	return string.format("Event [%s]", self.name and self.name or "nil");
end

--
-- DisplayEvents ---------------------------------------------------------
--

DisplayEvents = {
-- touch
	kTouchBegin = "touchBegin",
	kTouchEnd = "touchEnd",
	kTouchMove = "touchMove",
	
	kTouchOut = "touchOut",
	kTouchOver = "touchOver",
	
	kTouchTap = "touchTap",

	kTouchItem = "touchItem",
  
  kSelectItem = "selectItem"
};

--
-- DisplayEvent ---------------------------------------------------------
--
DisplayEvent = class(Event);

function DisplayEvent:ctor(name, target, globalPosition)
	self.class = DisplayEvent;

	self.name  = name;
	self.data = nil;
	self.target = target;
	self.globalPosition = globalPosition;
	self.propagation = true;
end

--Prevents processing of any event listeners in nodes subsequent to the current node in the event flow.
function DisplayEvent:stopPropagation()
    self.propagation = false;
end

function DisplayEvent:toString()
	return string.format("DisplayEvent [%s]", self.name and self.name or "nil");
end

function DisplayEvent:clone()
	local evt = DisplayEvent.new(self.name, self.target);
	return evt;
end

--
-- EventDispatcher ---------------------------------------------------------
--

-- members
EventDispatcher = class();

-- initialize
function EventDispatcher:ctor()
	self.class = EventDispatcher;
	self.receivers  = {}; -- of <{function,function...}>
end

-- public methods
function EventDispatcher:toString()
	return "EventDispatcher";
end

--Dispatches an event into the event flow.
function EventDispatcher:dispatchEvent( event, whetherButton )
	if debugEvent then
		print("EventDispatcher:dispatchEvent", event.name, event.data, event.target);
	end
	local eventName = event.name;
	if not eventName then return end;

	local list = self.receivers[eventName]; --of <function>

	if (not list) or type(list) ~= "table" then return end;

	-- by default, iterator throw a table is a non-atom operation,
	-- to avoid modify table while iteration (by callback), we need a atom-table or just clone the old one as I did.
	local cached = {};
	for k, v in ipairs(list) do
		cached[k] = v;
	end

	for k, v in ipairs(cached) do
	    event.context = nil;
	    if v[2] then event.context = v[2] end;
	    v[1](event);
	end
end

--Checks whether the EventDispatcher object has any listeners registered for a specific type of event.
function EventDispatcher:hasEventListener(eventName, listener)
	if not eventName then
		return false;
	end

	if self.receivers then
		local list = self.receivers[eventName]; --of <function>
		if not list then return false end;

		for i, v in ipairs(list) do
			if v[1] == listener then return true, i end;
		end
	end

	return false;
end

--Checks whether the EventDispatcher object has any listeners registered for a specific type of event.
function EventDispatcher:hasEventListenerByName(eventName)
	if not eventName then
		return false;
	end

	if self.receivers then
		local list = self.receivers[eventName]; --of <function>
		if list and table.getn(list) > 0 then
			return true;
		end
	end

	return false;
end


--Registers an event listener object with an EventDispatcher object so that the listener receives notification of an event.
function EventDispatcher:addEventListener(eventName, listener, context)
	if debugEvent then
		print("EventDispatcher:addEventListener", eventName, listener);
	end

	if (not eventName) or (not listener) or (not self.receivers) then return end;

	local bool = self:hasEventListener(eventName, listener);
	if bool then
		if debugEvent then
			print("EventDispatcher:addEventListener event already add");
		end
	else
		local list = self.receivers[eventName]; --of <function>
		if (not list) or type(list) ~= "table" then
			list = {};
			self.receivers[eventName] = list;
		end
		table.insert(list, {listener, context});
	end
end


--Removes a listener from the EventDispatcher object.
function EventDispatcher:removeEventListener(eventName, listener)
	if debugEvent then
		print("EventDispatcher:removeEventListener", eventName, listener);
	end

	if (not eventName) or (not listener) or (not self.receivers) then return end;
	local bool, i = self:hasEventListener(eventName, listener);
	if bool then
		local list = self.receivers[eventName]; --of <function>
		table.remove(list, i);
	end
end


--Removes a listener from the EventDispatcher object.
function EventDispatcher:removeEventListenerByName(eventName)
	if debugEvent then
		print("EventDispatcher:removeEventListenerByName", eventName);
	end
	if (not eventName) or (not self.receivers) then return end;
	self.receivers[eventName] = nil;
end

function EventDispatcher:removeAllEventListeners()
	local list = self.receivers;
	for k, v in pairs(list) do
		self.receivers[k] = nil;
	end
end

--atlis
EventDispatcher.dp = EventDispatcher.dispatchEvent
EventDispatcher.he = EventDispatcher.hasEventListener
EventDispatcher.hn = EventDispatcher.hasEventListenerByName
EventDispatcher.ad = EventDispatcher.addEventListener
EventDispatcher.rm = EventDispatcher.removeEventListener
EventDispatcher.rma = EventDispatcher.removeAllEventListeners
