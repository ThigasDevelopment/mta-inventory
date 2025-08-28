-- class's resource's
local Panel = { };

-- util's resource's
local function execute (method, ...)
	if (not method) then
		return Panel;
	end

	method = Panel[method];
	if (type (method) ~= 'function') then
		return Panel;
	end
	return method (Panel, ...);
end

-- method's resource's
function Panel:constructor ()
	register ('panel', execute);

	local UI = call ('ui');
	self.ui = UI;

	return self;
end

-- event's resource's
addEventHandler (EVENT_NAME .. ':loaded', resourceRoot,
	function ()
		return Panel:constructor ();
	end
);