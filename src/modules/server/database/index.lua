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