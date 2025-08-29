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

	self.fonts, self.positions = { }, { };

	self.fonts['medium'] = {
		['target'] = {
			['14'] = dxCreateFont ('assets/fonts/medium.ttf', 14, false),
		},

		['default'] = { },
	};

	self.fonts['regular'] = {
		['target'] = {
			['11'] = dxCreateFont ('assets/fonts/regular.ttf', 11, false),
			['12'] = dxCreateFont ('assets/fonts/regular.ttf', 12, false),
		},
		
		['default'] = {
			['12'] = dxCreateFont ('assets/fonts/regular.ttf', resp (12), false),
			['14'] = dxCreateFont ('assets/fonts/regular.ttf', resp (14), false),
		},
	};

	self.positions['background'] = {
		x = (self.w - resp (400)) / 2,
		y = (self.h - resp (460)) / 2,

		w = resp (400),
		h = resp (460),
	};

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
	return call ('ui', 'resp', num);
end