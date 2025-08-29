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

		local total = (self.data.slots + 10);
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