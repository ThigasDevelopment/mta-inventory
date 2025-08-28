-- class's resource's
local Panel = { };

-- util's resource's
local function execute (method, ...)
	if (not method) then
		return Panel;
	end

	method = Panel[method];
	if (type (method) ~= 'function') then
		return Panel;
	end
	return method (Panel, ...);
end

-- method's resource's
function Panel:constructor ()
	register ('panel', execute);

	local UI = call ('ui');
	self.ui = UI;

	self.hover, self.state = false, false;

	self.events = {
		['__state'] = false,

		['__onClientRender__'] = function ()
			return self:onRender ();
		end,
	};

	self.animation = {
		from = 0,
		to = 1,

		tick = 0,
		time = 350,
	};

	bindKey (CONFIG.key, 'down',
		function ()
			local state = (not self.state);
			return self:toggle (state);
		end
	);
	return self;
end

function Panel:onRender ()
	local tickNow = getTickCount ();
	self.hover = false;

	local progress = (tickNow - self.animation.tick) / self.animation.time;
	if (progress > 1) and (self.animation.to == 0) then
		return self:close ();
	end

	local alpha = interpolateBetween (self.animation.from, 0, 0, self.animation.to, 0, 0, progress, 'Linear');

	return true;
end

function Panel:close ()
	if (self.state) then
		return false;
	end

	if (self.events['__state']) then
		removeEventHandler ('onClientRender', root, self.events['__onClientRender__']);
	end
	return true;
end

function Panel:toggle (state)
	if (self.state == state) then
		return false;
	end

	local tickNow = getTickCount ();
	self.state = state;

	if (self.state) then
		if (not self.events['__state']) then
			addEventHandler ('onClientRender', root, self.events['__onClientRender__']);

			self.events['__state'] = true;
		end

		self.animation.from, self.animation.to = 0, 1;
		self.animation.tick = tickNow;
	else
		self.animation.from, self.animation.to = 1, 0;
		self.animation.tick = tickNow;
	end
	return true;
end

-- event's resource's
addEventHandler (EVENT_NAME .. ':loaded', resourceRoot,
	function ()
		return Panel:constructor ();
	end
);