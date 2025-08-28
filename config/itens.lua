-- item's resource's
local ITEMS = {
	['ak47'] = {
		name = 'AK-47',
		icon = 'assets/images/icons/ak47.png',
		description = 'Rifle de Assalto com munição 7.62mm',

		weight = 3.5,
	},
};

-- export's resource's
function getItems ()
	return ITEMS;
end