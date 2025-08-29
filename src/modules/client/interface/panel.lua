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

	local cursor = {
		x = 0,
		y = 0,

		update = function (self)
			if (not isCursorShowing ()) then
				return false;
			end

			local cx, cy = getCursorPosition ();
			self.x, self.y = (cx * self.ui.w), (cy * self.ui.h);

			return true;
		end,

		onElement = function (self, x, y, w, h)
			if (not isCursorShowing ()) then
				return false;
			end

			return (
				self.x >= x and self.x <= (x + w) and
				self.y >= y and self.y <= (y + h)
			);
		end,
	};
	self.cursor = cursor;

	self.hover, self.state = false, false;

	self.target = {
		elements = {
			scroll = {
				element = false,

				size = {
					w = resp (4),
					h = resp (390),
				},
			},

			target = {
				element = false,

				size = {
					w = 367,
					h = 390,
				},
			},
		},

		total = 0,

		update = 30,
		offset = 0,
	};

	self.events = {
		['__state'] = false,

		['__onClientRender__'] = function ()
			return self:onRender ();
		end,

		['__onClientRestore__'] = function ()
			return self:onRestore ();
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
	self.cursor:update ();

	local x, y, w, h = self.ui.positions['background'].x, self.ui.positions['background'].y, self.ui.positions['background'].w, self.ui.positions['background'].h;
	dxDrawImage (x, y, w, h, 'assets/images/bg.png', 0, 0, 0, tocolor (255, 255, 255, 255 * alpha), false);

	local target = self.target.elements.target.element;
	if (not isElement (target)) then
		return false;
	end

	local scroll = self.target.elements.scroll.element;
	if (scroll) then
		-- scroll:render ();
	end

	return true;
end

function Panel:onUpdate (current, index)
	local target = self.target.elements.target.element;
	if (not isElement (target)) then
		return false;
	end

	local posY = 0;
	current = (current or 0);

	dxSetRenderTarget (target, true);
		dxSetBlendMode ('modulate_add');
			local function drawComponents ()

			end
			drawComponents ();
		dxSetBlendMode ('blend');
	dxSetRenderTarget ();

	self.target.total, self.target.offset = (posY - self.target.elements.target.size.h), current;

	local scroll = self.target.elements.scroll.element;
	if (scroll) then
		return false;
	end

	local sizeW, sizeH = self.target.elements.scroll.size.w, self.target.elements.scroll.size.h;
	-- self.target.elements.scroll.element = Scrollbar.new (sizeW, sizeH, (self.target.total / self.target.update), 0, self.target.total);

	return true;
end

function Panel:onRestore ()
	local target = self.target.elements.target.element;
	if (not isElement (target)) then
		return false;
	end

	local offset = self.target.offset;
	return self:onUpdate (offset, false);
end

function Panel:close ()
	if (self.state) then
		return false;
	end

	if (self.events['__state']) then
		removeEventHandler ('onClientRender', root, self.events['__onClientRender__']);
		removeEventHandler ('onClientRender', root, self.events['__onClientRestore__']);

		self.events['__state'] = false;
	end

	local function destroyRenderTarget ()
		if (isElement (self.target.elements.target.element)) then
			destroyElement (self.target.elements.target.element);
		end
		self.target.elements.target.element = false;

		if (self.target.elements.scroll.element) then
			self.target.elements.scroll.element:destroy ();
		end
		self.target.elements.scroll.element = false;

		self.target.total, self.target.offset = 0, 0;
		return true;
	end
	destroyRenderTarget ();

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
			addEventHandler ('onClientRender', root, self.events['__onClientRestore__']);

			self.events['__state'] = true;
		end

		local function createRenderTarget ()
			if (isElement (self.target.elements.target.element)) then
				destroyElement (self.target.elements.target.element);
			end

			local sizeW, sizeH = self.target.elements.target.size.w, self.target.elements.target.size.h;
			self.target.elements.target.element = dxCreateRenderTarget (sizeW, sizeH);

			self.target.total, self.target.offset = 0, 0;
			return true;
		end
		createRenderTarget ();

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

-- export's resource's
function isCursorOnElement (x, y, w, h)
	return call ('panel').cursor:onElement (x, y, w, h);
end