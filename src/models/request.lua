-- class's resource's
local Request = { };

-- util's resource's
local function execute (method, ...)
	if (not method) then
		return Request;
	end

	method = Request[method];
	if (type (method) ~= 'function') then
		return Request;
	end
	return method (Request, ...);
end

-- method's resource's
function Request:constructor ()
	register ('request', execute);

	return self;
end

-- event's resource's
addEventHandler (EVENT_NAME .. ':loaded', resourceRoot,
	function ()
		return Request:constructor ();
	end
);