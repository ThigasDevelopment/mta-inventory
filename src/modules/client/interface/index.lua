-- class's resource's
local UI = { };

-- util's resource's
local function execute (method, ...)
	if (not method) then
		return UI;
	end

	method = UI[method];
	if (type (method) ~= 'function') then
		return UI;
	end
	return method (UI, ...);
end

-- method's resource's
function UI:constructor ()
	register ('ui', execute);

	self.w, self.h = guiGetScreenSize ();
	self.scale = math.max (0.85, self.h / 1080);

	return self;
end

function UI:resp (num)
	num = tonumber (num);
	if (not num) then
		return 0;
	end

	return (num * self.scale);
end

-- event's resource's
addEventHandler (EVENT_NAME .. ':loaded', resourceRoot,
	function ()
		return UI:constructor ();
	end
);

-- export's resource's
function resp (num)
	return UI:resp (num);
end