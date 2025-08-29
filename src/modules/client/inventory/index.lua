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

	self.slots, self.total = { }, 0;
	self.items = { };

	return self;
end

function Inventory:sync (data)
	if (not self.data) then
		self.data = { };
	end

	self.data, self.items = data.inventory, data.items;

	local function createSlots ()
		local size, padding = 65, 10;
		self.slots = { };

		local total = math.min (CONFIG.default.slots.max, (self.data.slots + 10));
		for i = 1, total do
			local col, row = ((i - 1) % 5), math.floor ((i - 1) / 5);
			self.slots[#self.slots + 1] = {
				x = 0 + (size + padding) * col,
				y = 0 + (size + padding) * row,

				size = size,
			};
		end

		return true;
	end
	createSlots ();

	local function getCurrentWeight ()
		self.total = 0;

		local size = table.size (self.items);
		if (size < 1) then
			return false;
		end

		for slot, data in pairs (self.items) do
			local config = ITEMS[data.item];
			if (config) then
				local current = (data.amount * config.weight);
				self.total = (self.total + current);
			end
		end

		return true;
	end
	getCurrentWeight ();

	local panel = call ('panel');
	panel:onUpdate (panel.target.offset, false);
	
	return true;
end

-- event's resource's
addEventHandler (EVENT_NAME .. ':loaded', resourceRoot,
	function ()
		return Inventory:constructor ();
	end
);