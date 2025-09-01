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
	call ('request', 'send', 'inventory', 'sync', to, inventory);

	return true;
end

function Inventory:update (player, items)
	print 'CHEGOU AQ'

	if (not isElement (player)) then
		return false;
	end

	local ownerId = getOwnerId (player);
	if (not ownerId) then
		return false;
	end
	ownerId = tostring (ownerId);

	local inventory = call ('database', 'get', 'inventory', ownerId);
	if (not inventory) then
		return false;
	end

	local ownerItems = call ('database', 'get', 'items', ownerId);
	if (table.size (ownerItems) ~= table.size (items)) then
		return false;
	end

	local success = table.key (items,
		function (slot, data)
			local match = false;

			for ownerSlot, ownerData in pairs (ownerItems) do
				if (data.item ~= ownerData.item) then
					match = data.item;

					break
				end
			end
			return match;
		end
	);
	print (success, getTickCount ());

	return true;
end

function Inventory:request (player)
	if (not isElement (player)) then
		return false;
	end

	local ownerId = getOwnerId (player);
	if (not ownerId) then
		return false;
	end
	ownerId = tostring (ownerId);

	local inventory = call ('database', 'get', 'inventory', ownerId);
	if (not inventory) then
		return call ('database', 'create', ownerId,
			function (success, ownerId, player)
				if (not success) then
					return CONFIG.utils.server:notify (player, 'Failed to create your inventory on database, contact an Administrator.', 'error');
				end

				return self:sync (player, player);
			end, player
		);
	end

	return self:sync (player, player);
end

-- event's resource's
addEventHandler (EVENT_NAME .. ':loaded', resourceRoot,
	function ()
		return Inventory:constructor ();
	end
);