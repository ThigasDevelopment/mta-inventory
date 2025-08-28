-- class's resource's
Index = { };

-- util's resource's
local function getFileSide ()
	local isClientSide = isElement (localPlayer);
	if (isClientSide) then
		return 'onClient';
	end
	return 'on';
end

-- enum's resource's
EVENT_NAME = 'inventory';
EVENT_SIDE = getFileSide ();

-- method's resource's
function Index:constructor ()
	self.modules = { };
	self:load ();

	return self;
end

function Index:load ()
	return triggerEvent (EVENT_NAME .. ':loaded', resourceRoot);
end

function Index:unload ()
	return triggerEvent (EVENT_NAME .. ':unloaded', resourceRoot);
end

function Index:call (module, method, ...)
	local main = self.modules[module];
	if (not main) then
		return false;
	end

	return main (method, ...);
end

function Index:register (module, func)
	local moduleType = type (module);
	if (moduleType ~= 'string') then
		return false;
	end

	local funcType = type (func);
	if (funcType ~= 'function') then
		return false;
	end

	self.modules[module] = func;
	return true;
end

-- event's resource's
addEventHandler (EVENT_SIDE .. 'ResourceStop', resourceRoot,
	function ()
		return Index:unload ();
	end
);

addEventHandler (EVENT_SIDE .. 'ResourceStart', resourceRoot,
	function ()
		return Index:constructor ();
	end
);

-- custom's event's resource's
addEvent (EVENT_NAME .. ':loaded');
addEvent (EVENT_NAME .. ':unloaded');

-- export's resource's
function call (module, method, ...)
	return Index:call (module, method, ...);
end

function register (module, func)
	return Index:register (module, func);
end