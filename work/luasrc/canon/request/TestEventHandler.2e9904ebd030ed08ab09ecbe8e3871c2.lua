
local TestEventHandler = class(EventDispatcher)

function TestEventHandler:ctor()
	self.endpoint = "testEvent"
end

function TestEventHandler:handle(data)
	he_log_info("testEvent " .. table.serialize(data))
end

return TestEventHandler.new()
