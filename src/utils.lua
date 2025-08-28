-- config's resource's
CONFIG, ITEMS = getConfig (), getItems ();

-- util's resource's
VALID_ELEMENTS = {
	['ped'] = true,

	['player'] = true,
	['object'] = true,

	['vehicle'] = true,
};

function getOnwerId (owner)
	if (not isElement (owner)) then
		return false;
	end

	local elemType = getElementType (owner);
	if (not VALID_ELEMENTS[elemType]) then
		return false;
	end

	if (elemType == 'player') then
		local account = getPlayerAccount (owner);
		if (not account) then
			return false;
		end

		local name = getAccountName (account);
		return name;
	end
	
	return false;
end

-- lib's resource's
function table.size (t)
	local size = 0;
	if (type (t) ~= 'table') then
		return size;
	end

	for _ in pairs (t) do
		size = (size + 1);
	end
	return size;
end

function table.key (t, c)
	local size = table.size (t);
	if (size < 1) then
		return false;
	end

	local cType = type (c);
	if (cType ~= 'function') then
		return false;
	end

	for k, v in pairs (t) do
		if (c (k, v)) then
			return k;
		end
	end
	return false;
end