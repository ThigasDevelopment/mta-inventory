-- class's resource's
local UI = { };

-- util's resource's
local function execute (method, ...)
	if (not method) then
		return UI;
	end

	method = UI[method];
	if (type (method) ~= 'function') then
		return UI;
	end
	return method (UI, ...);
end

-- method's resource's
function UI:constructor ()
	register ('ui', execute);

	return self;
end

-- event's resource's
addEventHandler (EVENT_NAME .. ':loaded', resourceRoot,
	function ()
		return UI:constructor ();
	end
);