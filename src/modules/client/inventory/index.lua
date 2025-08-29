-- class's resource's
local Inventory = { };

-- util's resource's
local function execute (method, ...)
	if (not method) then
		return Inventory;
	end

	method = Inventory[method];
	if (type (method) ~= 'function') then
		return Inventory;
	end
	return method (Inventory, ...);
end

-- method's resource's
function Inventory:constructor ()
	register ('inventory', execute);

	return self;
end

-- event's resource's
addEventHandler (EVENT_NAME .. ':loaded', resourceRoot,
	function ()
		return Inventory:constructor ();
	end
);