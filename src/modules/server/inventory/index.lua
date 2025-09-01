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

	local cache = {
		items = { },
		slots = { },
	};
	for key, item in pairs (ownerItems) do
		cache.items[item.item] = item;
		cache.slots[key] = toJSON (item);
	end

	local function validate ()
		local matched, values = false, false;

		for slot, data in pairs (items) do
			if (not cache.items[data.item]) then
				matched = data.item;

				break
			end

			local diff = table.key (cache.items[data.item],
				function (key, value)
					local parse = data[key];
					if (not parse) then
						return true;
					end

					local valueType = type (value);
					if (valueType == 'table') then
						value = toJSON (value);
					end

					local parseType = type (parse);
					if (parseType == 'table') then
						parse = toJSON (parse);
					end

					if (parse ~= value) then
						return true;
					end

					return false;
				end
			);
			
			if (diff) then
				matched = data.item;

				break
			end

			if (not ownerItems[slot]) then
				if (tonumber (slot) > inventory.slots) then
					matched = data.item;

					break
				end

				values = { id = data.id, slot = slot };
			end

			local json = toJSON (data);
			if (cache.slots[slot] ~= json) then
				if (not values) then
					values = { };
				end

				values[#values + 1] = { id = data.id, slot = slot };
			end
		end

		return matched, values;
	end

	local parsed, values = validate ();
	if (parsed) then
		return false;
	end

	if (not values) then
		return false;
	end

	if (type (values) ~= 'table') then
		return false;
	end

	call ('database', 'update', 'allItems', ownerId, values, items);
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