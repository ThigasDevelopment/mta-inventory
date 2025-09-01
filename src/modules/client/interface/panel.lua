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

	self.options = { };

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

		update = 0,
		offset = 0,

		positions = { },
	};

	self.events = {
		['__state'] = false,

		['__onClientKey__'] = function (...)
			return self:onKey (...);
		end,

		['__onClientClick__'] = function (...)
			return self:onClick (...);
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
	if (not current) then
		return false;
	end

	if (key == 'mouse_wheel_up') then
		scroll:set (math.max (0, (current - self.target.update)));
	elseif (key == 'mouse_wheel_down') then
		scroll:set (math.min (self.target.total, (current + self.target.update)));
	end
	return true;
end

function Panel:onClick (button, state, x, y)
	if (button ~= 'left') then
		return false;
	end

	local options = self.options;
	self.options = false;

	local hover = self.hover;
	if (state == 'up') then
		if (not options) then
			return false;
		end

		local function onMouseDrop ()
			local inventory = call ('inventory');
			if (not hover) then
				return false, true;
			end

			local type = hover.type;
			if (type ~= 'slot') then
				return false, true;
			end

			local slot = hover.id;
			if (slot == options.slot) then
				return false, true;
			end

			if (tonumber (slot) > inventory.data.slots) then
				return CONFIG.utils.client:notify ('Você não possui esse slot [ ' .. slot .. ' ], adquira mais espaço no seu inventário.', 'error'), true;
			end

			local old, new = inventory.items[options.slot], inventory.items[slot];
			if (not old) then
				return false, true;
			end

			if (not new) then
				local items = inventory.items;
				items[options.slot], items[slot] = nil, old;

				inventory:sync ({ inventory = inventory.data, items = items }, true);
				return true, false;
			end

			return true, false;
		end

		local state, update = onMouseDrop ();
		if (update) then
			self:onUpdate (self.target.offset);
		end
		return state;
	end

	if (state == 'down') then
		if (not hover) then
			return false;
		end

		local type = hover.type;
		if (type == 'slot') then
			local inventory = call ('inventory');
			if (not inventory.data) then
				return false;
			end

			local items = inventory.items;
			if (table.size (items) < 1) then
				return false;
			end

			local slot = hover.id;
			if (not slot) then
				return false;
			end

			local item = items[slot];
			if (not item) then
				return false;
			end

			self.options = {
				slot = slot,
				type = 'item',

				default = {
					x = hover.position.x,
					y = hover.position.y,
				},

				position = {
					x = (x - hover.position.x),
					y = (y - hover.position.y),
				};
			};

			self:onUpdate (self.target.offset);
			return true;
		end

		return false;
	end
	return false;
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
	dxDrawImage (x, y, w, h, 'assets/images/bg.png', 0, 0, 0, tocolor (19, 19, 19, 255 * alpha), false);
	dxDrawRectangle (x, y + resp (44), w, 1, tocolor (241, 241, 241, 55 * alpha), false);

	dxDrawImage (self.ui.positions['ball'].x, self.ui.positions['ball'].y, self.ui.positions['ball'].w, self.ui.positions['ball'].h, 'assets/images/ball.png', 0, 0, 0, tocolor (241, 241, 241, 225 * alpha), false);
	dxDrawText ('Inventário', self.ui.positions['title'].x, self.ui.positions['title'].y, self.ui.positions['title'].w, self.ui.positions['title'].h, tocolor (241, 241, 241, 255 * alpha), 1, self.ui.fonts['medium']['default']['13'], 'left', 'center');

	local inventory = call ('inventory');
	if (not inventory.data) then
		if (not self.loading) then
			self.loading = 0;
		end
		self.loading = (self.loading + 1);
		if (self.loading > 360) then
			self.loading = 0;
		end

		dxDrawImage (self.ui.positions['loading'].x + resp (19), self.ui.positions['loading'].y, resp (140), resp (140), 'assets/images/effect-loading.png', self.loading, 0, 0, tocolor (255, 255, 255, 255 * alpha), false);
		dxDrawText ('Carregando seu inventário,\npor favor aguarde.', self.ui.positions['loading'].x, self.ui.positions['loading'].y + resp (140), self.ui.positions['loading'].w, resp (65), tocolor (241, 241, 241, 255 * alpha), 1, self.ui.fonts['medium']['default']['13'], 'center', 'center');
		return true;
	end

	dxDrawText (('%.1f'):format (inventory.total) .. '/' .. ('%.1f'):format (inventory.data.weight) .. 'kg', x + resp (163), y, resp (226), self.ui.positions['title'].h, tocolor (241, 241, 241, 255 * alpha), 1, self.ui.fonts['regular']['default']['10'], 'right', 'center');
	self.loading = nil;

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
			self:onUpdate (current);
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

		for _, button in pairs (self.target.positions) do
			local inButton = isCursorOnElement (self.ui.positions['target'].x + button.position[1], self.ui.positions['target'].y + button.position[2] - resp (self.target.offset), button.position[3], button.position[4]);
			if (inButton) then
				local id, type = button.id, button.type;
				self.hover = {
					id = id,
					type = type,

					position = {
						x = self.ui.positions['target'].x + button.position[1],
						y = self.ui.positions['target'].y + button.position[2] - resp (self.target.offset),
					},
				};

				break
			end
		end
	end

	local options = self.options;
	if (options) then
		local type = options.type;
		if (type == 'item') then
			local cursorX, cursorY, size = self.cursor.x, self.cursor.y, resp (50);
			cursorX, cursorY = (cursorX - (options.default.x + (options.position.x - options.default.x))), (cursorY - (options.default.y + (options.position.y - options.default.y)));

			local data = inventory.items[options.slot];
			if (data) then
				local config = ITEMS[data.item];
				dxDrawImage (cursorX, cursorY, size, size, config.icon, 0, 0, 0, tocolor (255, 255, 255, 255 * alpha), true);
			end
		end
	end

	return true;
end

function Panel:onUpdate (current)
	local target = self.target.elements.target.element;
	if (not isElement (target)) then
		return false;
	end

	local inventory = call ('inventory');
	if (not inventory.data) then
		return false;
	end

	local options = self.options;
	if (not options) then
		options = { };
	end

	local posY = 0;
	current = (current or 0);
	
	dxSetRenderTarget (target, true);
		dxSetBlendMode ('modulate_add');
			local function drawComponents ()
				self.target.positions = { };

				local slots = inventory.slots;
				for i = 1, #slots do
					local slot = slots[i];
					if (slot) then
						local x, y, size, slot = slot.x, slot.y, slot.size, tostring (i);

						if ((y - current) > -size and (y - current) < self.target.elements.target.size.h) then
							local path = (i > inventory.data.slots) and 'assets/images/bg-slot-locked.png' or 'assets/images/bg-slot.png';
							dxDrawImage (x, y - current, size, size, path, 0, 0, 0, tocolor (241, 241, 241, 95), false);

							local data = inventory.items[slot];
							if (data) and (i <= inventory.data.slots) and (slot ~= options.slot) then
								local config = ITEMS[data.item];
								dxDrawImage (x + 7, y + 7 - current, 50, 50, config.icon, 0, 0, 0, tocolor (255, 255, 255, 255), false);
								dxDrawText (data.amount .. 'x', x, y - current, size - 7, size - 7, tocolor (241, 241, 241, 255), 1, self.ui.fonts['regular']['target']['7'], 'right', 'bottom');
							end

							self.target.positions[#self.target.positions + 1] = { id = slot, type = 'slot', position = { resp (x), resp (y), resp (size), resp (size) } };
						end
					end
				end

				local total = (slots[#slots].y + slots[#slots].size);
				posY = total;

				local y = (posY - 133) - current;
				if (y < self.target.elements.target.size.h) and (#slots > inventory.data.slots) then
					dxDrawImage (167, y - 5, 35, 35, 'assets/images/icon-lock.png', 0, 0, 0, tocolor (255, 255, 255, 255), false);

					dxDrawText ('Slots bloqueados', 0, y + 24, self.target.elements.target.size.w, 34, tocolor (241, 241, 241, 255), 1, self.ui.fonts['medium']['target']['14'], 'center', 'center');
					dxDrawText ('Serão desbloqueados 5 novos slots\nno seu inventário.', 0, y + 54, self.target.elements.target.size.w, 34, tocolor (241, 241, 241, 255), 1, self.ui.fonts['regular']['target']['11'], 'center', 'center');

					dxDrawImage (103, y + 95, 158, 30, 'assets/images/bg-button.png', 0, 0, 0, tocolor (241, 241, 241, 255), false);
					dxDrawText ('Adquirir', 103, y + 95, 158, 28, tocolor (29, 29, 29, 255), 1, self.ui.fonts['medium']['target']['11'], 'center', 'center');

					table.insert (self.target.positions, 1, { id = 'buy:slots', type = 'button', position = { resp (103), resp (y + 95 + current), resp (158), resp (30) } });
				end
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
	self.target.update = math.max (5, math.min (65, (self.target.total / 65)));

	local ratio = (sizeH - resp (self.target.total));
	ratio = math.max (75, math.min (sizeH, ratio));

	self.target.elements.scroll.element = Scrollbar.new (sizeW, sizeH, ratio, 0, self.target.total);
	return true;
end

function Panel:onRestore ()
	local target = self.target.elements.target.element;
	if (not isElement (target)) then
		return false;
	end

	local offset = self.target.offset;
	return self:onUpdate (offset);
end

function Panel:close ()
	if (self.state) then
		return false;
	end

	if (self.events['__state']) then
		local function unloadEvents ()
			for event, callback in pairs (self.events) do
				local name = event:gsub ('__', '');

				local callbackType = type (callback);
				if (callbackType == 'function') then
					removeEventHandler (name, root, callback);
				end
			end
			return true;
		end
		unloadEvents ();

		self.events['__state'] = false;
	end

	local function destroyRenderTarget ()
		self.options = false;

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
			local function loadEvents ()
				for event, callback in pairs (self.events) do
					local name = event:gsub ('__', '');

					local callbackType = type (callback);
					if (callbackType == 'function') then
						addEventHandler (name, root, callback);
					end
				end
				return true;
			end
			loadEvents ();

			call ('request', 'send', 'inventory', 'request');

			self.events['__state'] = true;
		end

		local function createRenderTarget ()
			self.options = false;

			if (isElement (self.target.elements.target.element)) then
				destroyElement (self.target.elements.target.element);
			end

			local sizeW, sizeH = self.target.elements.target.size.w, self.target.elements.target.size.h;
			self.target.elements.target.element = dxCreateRenderTarget (sizeW, sizeH, true);

			self.target.total, self.target.offset = 0, 0;
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