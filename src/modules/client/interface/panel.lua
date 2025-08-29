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
			self.x, self.y = (cx * UI.w), (cy * UI.h);

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

		['__onClientKey__'] = function (key, press)
			return self:onKey (key, press);
		end,

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

function Panel:onKey (key, press)
	local scroll = self.target.elements.scroll.element;
	if (not scroll) then
		return false;
	end

	key = key:lower ();
	if (not press) then
		return false;
	end

	local avaliableKeys = {
		['mouse_wheel_up'] = true,
		['mouse_wheel_down'] = true,
	};
	if (not avaliableKeys[key]) then
		return false;
	end

	local state = self.target.can_scroll;
	if (not state) then
		return false;
	end

	local current = scroll:get ();
	if (key == 'mouse_wheel_up') then
		scroll:set (math.max (0, (current - self.target.update)));
	elseif (key == 'mouse_wheel_down') then
		scroll:set (math.min (self.target.total, (current + self.target.update)));
	end
	return true;
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

	dxDrawImage (self.ui.positions['ball'].x, self.ui.positions['ball'].y, self.ui.positions['ball'].w, self.ui.positions['ball'].h, 'assets/images/ball.png', 0, 0, 0, tocolor (255, 255, 255, 255 * alpha), false);
	dxDrawText ('Inventário', self.ui.positions['title'].x, self.ui.positions['title'].y, self.ui.positions['title'].w, self.ui.positions['title'].h, tocolor (241, 241, 241, 255 * alpha), 1, self.ui.fonts['regular']['default']['14'], 'left', 'center');

	local target = self.target.elements.target.element;
	if (not isElement (target)) then
		return false;
	end

	local inRenderTarget = isCursorOnElement (self.ui.positions['target'].x, self.ui.positions['target'].y, self.ui.positions['target'].w, self.ui.positions['target'].h);
	dxDrawImage (self.ui.positions['target'].x, self.ui.positions['target'].y, self.ui.positions['target'].w, self.ui.positions['target'].h, target, 0, 0, 0, tocolor (255, 255, 255, 255 * alpha), false);

	local scroll = self.target.elements.scroll.element;
	if (scroll) then
		local current = scroll:get ();
		if (current ~= self.target.offset) then
			self:onUpdate (current, false);
		end

		scroll:draw (self.ui.positions['scroll'].x, self.ui.positions['scroll'].y, {
			effect = tocolor (241, 241, 241, 255 * alpha),

			default = tocolor (241, 241, 241, 127 * alpha),
			background = tocolor (255, 255, 255, 12 * alpha),
		}, false);

		self.target.can_scroll = false;
	end

	if (inRenderTarget) then
		self.target.can_scroll = true;
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
				dxDrawRectangle (0, 0, self.target.elements.target.size.w, self.target.elements.target.size.h, tocolor (255, 0, 0, 55), false);

				local slots = 40;
				for i = 1, slots do
					local col, row = ((i - 1) % 5), math.floor ((i - 1) / 5);
					dxDrawRectangle (0 + (65 + 10) * col, 0 + (65 + 10) * row - current, 65, 65, tocolor (255, 255, 255, 255), false);
					dxDrawText (i, 0 + (65 + 10) * col, 0 + (65 + 10) * row - current, 65, 65, tocolor (0, 0, 0, 255), 1, 'default', 'center', 'center');

					if (i >= slots) then
						posY = (posY + (65 + 10) * (row + 1));
					end
				end
				posY = (posY - 10);
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

	local ratio = (sizeH - resp (self.target.total));
	if (ratio < resp (self.target.update)) then
		ratio = resp (self.target.update);
	elseif (ratio > sizeH) then
		ratio = sizeH;
	end
	self.target.elements.scroll.element = Scrollbar.new (sizeW, sizeH, ratio, 0, self.target.total);

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
		removeEventHandler ('onClientKey', root, self.events['__onClientKey__']);
		removeEventHandler ('onClientRender', root, self.events['__onClientRender__']);
		removeEventHandler ('onClientRestore', root, self.events['__onClientRestore__']);

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

	showCursor (false);
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
			addEventHandler ('onClientKey', root, self.events['__onClientKey__']);
			addEventHandler ('onClientRender', root, self.events['__onClientRender__']);
			addEventHandler ('onClientRestore', root, self.events['__onClientRestore__']);

			self.events['__state'] = true;
		end

		local function createRenderTarget ()
			if (isElement (self.target.elements.target.element)) then
				destroyElement (self.target.elements.target.element);
			end

			local sizeW, sizeH = self.target.elements.target.size.w, self.target.elements.target.size.h;
			self.target.elements.target.element = dxCreateRenderTarget (sizeW, sizeH, true);

			self.target.total, self.target.offset = 0, 0;

			self:onUpdate (self.target.offset, false);
			return true;
		end
		createRenderTarget ();

		showCursor (true);

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