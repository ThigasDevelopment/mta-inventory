-- config's resource's
local CONFIG = {
	key = 'i',

	default = {
		slots = 25,
		weight = 10.0,
	},

	utils = {
		client = {
			styles = {
				['info'] = '#5EADED',
				['error'] = '#ED5E5E',
				['success'] = '#5EED6F',
				['warning'] = '#EDA15E',
			},

			notify = function (self, message, style, ...)
				local color = (self.styles[style] or '#F1F1F1');

				return outputChatBox (color .. '[INVENTORY]: #FFFFFF' .. message, 255, 255, 255, true);
			end,
		},

		server = {
			styles = {
				['info'] = '#5EADED',
				['error'] = '#ED5E5E',
				['success'] = '#5EED6F',
				['warning'] = '#EDA15E',
			},

			notify = function (self, player, message, style, ...)
				local color = (self.styles[style] or '#F1F1F1');

				return outputChatBox (color .. '[INVENTORY]: #FFFFFF' .. message, player, 255, 255, 255, true);
			end,
		},
	},
};

-- export's resource's
function getConfig ()
	return CONFIG;
end