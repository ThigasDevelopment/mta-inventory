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

	self.events = {
		['__response'] = function (module, method, ...)
			return self:response (module, method, ...);
		end,
	};
	addEventHandler (EVENT_NAME .. ':request', resourceRoot, self.events['__response']);

	return self;
end

function Request:send (module, method, ...)
	local isClient = (EVENT_SIDE == 'onClient');
	if (isClient) then
		if (self.requesting) then
			return false;
		end

		self.requesting = true;
		return triggerServerEvent (EVENT_NAME .. ':request', resourceRoot, module, method, ...);
	end

	local arguments = { ... };
	if (table.size (arguments) < 1) then
		return false;
	end

	local player = arguments[1];
	if (not isElement (player)) then
		return false;
	end

	table.remove (arguments, 1);
	return triggerClientEvent (player, EVENT_NAME .. ':request', resourceRoot, module, method, unpack (arguments));
end

function Request:response (module, method, ...)
	local isClient = (EVENT_SIDE == 'onClient');
	if (isClient) then
		if (self.requesting) then
			self.requesting = false;
		end

		return call (module, method, ...);
	end

	if (not isElement (client)) then
		return false;
	end

	call (module, method, client, ...);
	return true;
end

-- event's resource's
addEventHandler (EVENT_NAME .. ':loaded', resourceRoot,
	function ()
		return Request:constructor ();
	end
);

-- custom's event's resource's
addEvent (EVENT_NAME .. ':request', true);