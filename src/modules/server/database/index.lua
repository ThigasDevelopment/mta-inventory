-- class's resource's
local Database = { };

-- util's resource's
local function execute (method, ...)
	if (not method) then
		return Database;
	end

	method = Database[method];
    if (type (method) ~= 'function') then
        return method;
    end
    return method (Database, ...);
end

-- method's resource's
function Database:constructor ()
	register ('database', execute);

	self.data, self.connection = { }, false;
	self:connect ();

	return self;
end

function Database:connect ()
	if (isElement (self.connection)) then
		return false;
	end

	self.connection = dbConnect ('sqlite', '__database__/database.db');
	if (not isElement (self.connection)) then
		return false;
	end

	self:load ();
	return true;
end

function Database:load ()
	if (not isElement (self.connection)) then
		return false;
	end

	-- load table's schema.
	dbExec (self.connection, [[
		CREATE TABLE IF NOT EXISTS `items` (
			`id` INTEGER PRIMARY KEY AUTOINCREMENT,
			`owner` TEXT NOT NULL,

			`item` TEXT NOT NULL,
			`slot` TEXT NOT NULL DEFAULT "1",
			`amount` INTEGER NOT NULL DEFAULT 0,

			`data` JSON NOT NULL,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);
	]]);

	if (not self.data['items']) then
		self.data['items'] = { };
	end

	dbExec (self.connection, [[
		CREATE TABLE IF NOT EXISTS `inventory` (
			`id` INTEGER PRIMARY KEY AUTOINCREMENT,
			`owner` TEXT UNIQUE NOT NULL,

			`slots` INTEGER NOT NULL DEFAULT 20,
			`weight` INTEGER NOT NULL DEFAULT 100,

			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);
	]]);

	if (not self.data['inventory']) then
		self.data['inventory'] = { };
	end

	-- load data's from schema.
	dbQuery (
		function (qh)
			local result = dbPoll (qh, -1);
			if (#result < 1) then
				return false;
			end

			for _, row in pairs (result) do
				if (not self.data['items'][row.owner]) then
					self.data['items'][row.owner] = { };
				end

				self.data['items'][row.owner][row.slot] = {
					id = row.id,

					item = row.item,
					amount = row.amount,

					data = fromJSON (row.data),
				};
			end
			return true;
		end, self.connection, 'SELECT * FROM `items`;'
	);

	dbQuery (
		function (qh)
			local result = dbPoll (qh, -1);
			if (#result < 1) then
				return false;
			end

			for _, row in pairs (result) do
				if (not self.data['inventory'][row.owner]) then
					self.data['inventory'][row.owner] = { };
				end

				self.data['inventory'][row.owner] = {
					id = row.id,

					slots = row.slots,
					weight = row.weight,
				};
			end
			return true;
		end, self.connection, 'SELECT * FROM `inventory`;'
	);

	return true;
end

function Database:get (schema, ...)
	if (not isElement (self.connection)) then
		return false;
	end

	local schemaType = type (schema);
	if (schemaType ~= 'string') then
		return false;
	end

	local ownerId = arg[1];
	if (type (ownerId) ~= 'string') then
		return false;
	end

	if (schema == 'all') then
		local items, inventory = (self.data['items'][ownerId] or { }), (self.data['inventory'][ownerId] or { });
		return { items = items, inventory = inventory };
	end
	return (self.data[schema][ownerId] or false);
end

function Database:update (schema, ownerId, ...)
	if (not isElement (self.connection)) then
		return false;
	end

	local schemaType = type (schema);
	if (schemaType ~= 'string') then
		return false;
	end

	local ownerType = type (ownerId);
	if (ownerType ~= 'string') then
		return false;
	end

	if (schema == 'allItems') then
		local values, items = ...;
		if (not values) then
			return false;
		end

		if (type (values) ~= 'table') then
			return false;
		end

		if (table.size (items) < 1) then
			return false;
		end

		if (#values == 2) then
			local old, new = items[values[1].slot], items[values[2].slot];
			self.data['items'][ownerId][values[1].slot], self.data['items'][ownerId][values[2].slot] = nil, nil;
			
			dbExec (self.connection, 'UPDATE `items` SET `slot` = ? WHERE `id` = ? AND `owner` = ?;', values[1].slot, old.id, ownerId);
			dbExec (self.connection, 'UPDATE `items` SET `slot` = ? WHERE `id` = ? AND `owner` = ?;', values[2].slot, new.id, ownerId);

			self.data['items'][ownerId][values[1].slot], self.data['items'][ownerId][values[2].slot] = old, new;
			return true;
		end

		local id = values.id;
		if (not id) then
			return false;
		end

		local old = false;
		for slot, data in pairs (self.data['items'][ownerId]) do
			if (data.id == id) then
				old = slot;

				break
			end
		end

		dbExec (self.connection, 'UPDATE `items` SET `slot` = ? WHERE `id` = ? AND `owner` = ?;', values.slot, id, ownerId);

		local item = self.data['items'][ownerId][old];
		self.data['items'][ownerId][old] = nil;

		self.data['items'][ownerId][values.slot] = item;
		return true;
	end

	local schema = self.data[schema];
	if (not schema) then
		return false;
	end

	local id, key, value = ...;
	if (not id) or (not key) or (not value) then
		return false;
	end
	
	local valueType = type (value);
	if (valueType == 'table') then
		value = toJSON (value);
	end

	if (value == 'id') then
		return false;
	end

	return true;
end

function Database:create (ownerId, callback, ...)
	if (not isElement (self.connection)) then
		return false;
	end
	
	local ownerType = type (ownerId);
	if (ownerType ~= 'string') then
		return false;
	end

	local callbackType = type (callback);
	if (callbackType ~= 'function') then
		return false;
	end

	local inventory = self:get ('inventory', ownerId);
	if (inventory) then
		return false;
	end

	return dbQuery (
		function (qh, ...)
			local result, rows, id = dbPoll (qh, -1);
			if (not result) then
				return callback (false, ownerId, ...);
			end

			self.data['inventory'][ownerId] = {
				id = id,

				slots = CONFIG.default.slots.min,
				weight = CONFIG.default.weight,
			};
			return callback (true, ownerId, ...);
		end, { ... }, self.connection, 'INSERT INTO `inventory` (owner, slots, weight) VALUES (?, ?, ?);', ownerId, CONFIG.default.slots.min, CONFIG.default.weight
	);
end

-- event's resource's
addEventHandler (EVENT_NAME .. ':loaded', resourceRoot,
	function ()
		return Database:constructor ();
	end
);

-- export's resource's
function getConnection ()
	return call ('database').connection;
end