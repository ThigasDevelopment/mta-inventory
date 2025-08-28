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
					created_at = row.created_at,
				};
			end
			return true;
		end, self.connection, 'SELECT * FROM `items`;'
	);

	return true;
end

-- event's resource's
addEventHandler (EVENT_NAME .. ':loaded', resourceRoot,
	function ()
		return Database:constructor ();
	end
);

-- export's resource's
function getConnection ()
	return execute ().connection;
end