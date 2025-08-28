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

function Inventory:sync (to, from)
	if (not isElement (to)) then
		return false;
	end

	local elemType = getElementType (to);
	if (elemType ~= 'player') then
		return false;
	end

	if (not isElement (from)) then
		return false;
	end

	local ownerId = getOwnerId (from);
	if (not ownerId) then
		return false;
	end
	ownerId = tostring (ownerId);

	local inventory = call ('database', 'get', 'all', ownerId);
	-- call client's side sending: inventory.

	return true;
end

-- event's resource's
addEventHandler (EVENT_NAME .. ':loaded', resourceRoot,
	function ()
		return Inventory:constructor ();
	end
);