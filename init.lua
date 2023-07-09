mcl_debug_stick = {}
mcl_debug_stick.registered_functions = {}

local S = minetest.get_translator("mcl_debug_stick")

local function check_modname_prefix(name) -- from builtin/game/register.lua
	if name:sub(1,1) == ":" then
		-- If the name starts with a colon, we can skip the modname prefix
		-- mechanism.
		return name:sub(2)
	else
		-- Enforce that the name starts with the correct mod name.
		local expected_prefix = core.get_current_modname() .. ":"
		if name:sub(1, #expected_prefix) ~= expected_prefix then
			error("Name " .. name .. " does not follow naming conventions: " ..
				"\"" .. expected_prefix .. "\" or \":\" prefix required")
		end

		-- Enforce that the name only contains letters, numbers and underscores.
		local subname = name:sub(#expected_prefix+1)
		if subname:find("[^%w_]") then
			error("Name " .. name .. " does not follow naming conventions: " ..
				"contains unallowed characters")
		end

		return name
	end
end

function mcl_debug_stick.register_function(name,def)
	name = check_modname_prefix(name)
	mcl_debug_stick.registered_functions[name] = def
end

function mcl_debug_stick.unregister_function(name)
	mcl_debug_stick.registered_functions[name] = nil
end

mcl_debug_stick.register_function("mcl_debug_stick:rotate",{
	short_description = S("rotate"),
	description = S("Rotate the node though 4 facings"),
	func = function(player,pos,node)
		local ndef = minetest.registered_nodes[node.name]
		if ndef.paramtype2 ~= "facedir" then -- TODO: add colorfacedir support
			return false, S("Param2 type isn't facedir!")
		elseif node.param2 < 0 or node.param2 > 3 then
			return false, S("The facing direction of this node is irregular!")
		end
		node.param2 = node.param2 + (player:get_player_control().sneak and -1 or 1)
		if node.param2 > 3 then
			node.param2 = 0
		elseif node.param2 < 0 then
			node.param2 = 3
		end
		minetest.swap_node(pos,node)
		return true, S("facedir: @1",node.param2)
	end
})

mcl_debug_stick.register_function("mcl_debug_stick:rotate_extended",{
	short_description = S("extended rotate"),
	description = S("Rotate the node though 24 facings"),
	func = function(player,pos,node)
		local ndef = minetest.registered_nodes[node.name]
		if ndef.paramtype2 ~= "facedir" then
			return false, S("Param2 type isn't facedir!")
		elseif node.param2 < 0 or node.param2 > 23 then
			return false, S("The facing direction of this node is irregular!")
		end
		node.param2 = node.param2 + (player:get_player_control().sneak and -1 or 1)
		if node.param2 > 23 then
			node.param2 = 0
		elseif node.param2 < 0 then
			node.param2 = 23
		end
		minetest.swap_node(pos,node)
		return true, S("facedir: @1",node.param2)
	end
})

mcl_debug_stick.register_function("mcl_debug_stick:rotate_4dir",{
	short_description = S("4dir rotate"),
	description = S("Rotate the node though 4 facings"),
	func = function(player,pos,node)
		local ndef = minetest.registered_nodes[node.name]
		if ndef.paramtype2 ~= "facedir" then
			return false, S("Param2 type isn't 4dir!")
		elseif node.param2 < 0 or node.param2 > 3 then
			return false, S("The facing direction of this node is irregular!")
		end
		node.param2 = node.param2 + (player:get_player_control().sneak and -1 or 1)
		if node.param2 > 3 then
			node.param2 = 0
		elseif node.param2 < 0 then
			node.param2 = 3
		end
		minetest.swap_node(pos,node)
		return true, S("4dir: @1",node.param2)
	end
})

mcl_debug_stick.register_function("mcl_debug_stick:rotate_wallmounted",{
	short_description = S("wallmounted rotate"),
	description = S("Mount the node of 6 different directions"),
	func = function(player,pos,node)
		local ndef = minetest.registered_nodes[node.name]
		if ndef.paramtype2 ~= "wallmounted" then
			return false, S("Param2 type isn't wallmounted!")
		elseif node.param2 < 0 or node.param2 > 5 then
			return false, S("The facing direction of this node is irregular!")
		end
		node.param2 = node.param2 + (player:get_player_control().sneak and -1 or 1)
		if node.param2 > 5 then
			node.param2 = 0
		elseif node.param2 < 0 then
			node.param2 = 5
		end
		minetest.swap_node(pos,node)
		return true, S("wallmounted: @1",node.param2)
	end
})

local huds = {}
local huds_last_change = {}

minetest.register_on_joinplayer(function(player)
	minetest.after(1,function()
		local player_name = player:get_player_name()
		huds[player_name] = player:hud_add({
			hud_elem_type = "text",
			position = {x=0.5, y=1},
			offset = {x=0, y=-99},
			alignment = {x=0, y=0},
			number = 0xFFFFFF,
			text = "",
			z_index = 100,
		})
	end)
end)

local function showhud(player,text,color)
	local player_name = player:get_player_name()
	player:hud_change(huds[player_name], 'text', text)
	player:hud_change(huds[player_name], 'number', color or 0xFFFFFF)
	local now = os.time()
	huds_last_change[player_name] = now
	minetest.after(5,function()
		if huds_last_change[player_name] == now then
			huds_last_change[player_name] = nil
			player:hud_change(huds[player_name], 'text', "")
		end
	end)
end

minetest.register_on_leaveplayer(function(player)
	local player_name = player:get_player_name()
	huds[player_name] = nil
end)

local function inlist(list,val)
	for x,y in ipairs(list) do
		if y == val then
			return x
		end
	end
	return nil
end

minetest.register_tool("mcl_debug_stick:debug_stick",{
	description = S("Debug Stick"),
	_doc_items_longdesc = S("Use to edit the block states of blocks."),
	_doc_items_hidden = true,
	inventory_image = "default_stick.png" .. mcl_enchanting.overlay,
	not_in_creative_inventory = true,
	on_place = function(itemstack, placer, pointed_thing)
		if not placer:is_player() then return end
		if not minetest.check_player_privs(placer:get_player_name(),{maphack=true}) then
			showhud(placer,S("Not allowed to use a debug stick!"),0xFF0000)
			return itemstack
		end
		local pos = pointed_thing.under
		local node = minetest.get_node_or_nil(pos)
		if not node then
			showhud(placer,S("The area is unloaded!"),0xFF0000)
			return itemstack
		end
		local meta = itemstack:get_meta()
		local def = minetest.registered_nodes[node.name]
		local poshash = minetest.pos_to_string(pos)
		local meta_pos = meta:get_string("pos")
		if poshash ~= meta_pos then
			meta:set_string("pos",poshash)
			meta:set_string("func","")
			showhud(placer,S("Please use leftclicks to choose a function!") .. " (P)",0xFF0000)
			return itemstack
		end
		local func_name = meta:get_string("func")
		if func_name ~= "" and not def._debug_stick_func and inlist(def._debug_stick_func,func_name) then
			meta:set_string("func","")
			showhud(placer,S("Please use leftclicks to choose a function!") .. " (F)",0xFF0000)
			return itemstack
		end
		local func_def = mcl_debug_stick.registered_functions[func_name]
		if not func_def then
			meta:set_string("func","")
			showhud(placer,S("Please use leftclicks to choose a function!") .. " (F)",0xFF0000)
			return itemstack
		end
		local func = func_def.func
		local status, display = func(placer,pos,node)
		local desc = func_def.short_description or func_def.description or func_name
		if not status then
			showhud(placer,S("[@1] @2",desc,display),0xFF0000)
		else
			showhud(placer,S("[@1] @2",desc,display),0xFFFFFF)
		end
		return itemstack
	end,
	on_use = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then return end
		if not placer:is_player() then return end
		if not minetest.check_player_privs(placer:get_player_name(),{maphack=true}) then
			showhud(placer,S("Not allowed to use a debug stick!"),0xFF0000)
			return itemstack
		end
		local pos = pointed_thing.under
		local node = minetest.get_node_or_nil(pos)
		if not node then
			showhud(placer,S("The area is unloaded!"),0xFF0000)
			return itemstack
		end
		local meta = itemstack:get_meta()
		local def = minetest.registered_nodes[node.name]
		local poshash = minetest.pos_to_string(pos)
		local meta_pos = meta:get_string("pos")
		local func_name = meta:get_string("func")
		local index = 0
		if not def._debug_stick_func or #def._debug_stick_func == 0 then
			showhud(placer,S("The node does not support using debug sticks!"),0xFF0000)
			return itemstack
		end
		if poshash == meta_pos and func_name ~= "" then
			index = inlist(def._debug_stick_func,func_name) or 0
		else
			meta:set_string("pos",poshash)
		end
		index = index + 1
		if index > #def._debug_stick_func then
			index = 1
		end
		func_name = def._debug_stick_func[index]
		meta:set_string("func",func_name)
		local func_def = mcl_debug_stick.registered_functions[func_name]
		local desc = func_def.short_description or func_def.description or func_name
		showhud(placer,S("Function: @1",desc),0xFFFFFF)
		return itemstack
	end
})

minetest.register_alias("minecraft:debug_stick","mcl_debug_stick:debug_stick")
minetest.register_alias("ddebug_stick","mcl_debug_stick:debug_stick")

minetest.register_on_mods_loaded(function()
	for x,y in pairs(minetest.registered_nodes) do
		local func_list = nil
		if y.paramtype2 == "facedir" then
			func_list = {"mcl_debug_stick:rotate"}
		elseif y.paramtype2 == "4dir" then
			func_list = {"mcl_debug_stick:rotate_4dir"}
		elseif y.paramtype2 == "wallmounted" then
			func_list = {"mcl_debug_stick:rotate_wallmounted"}
		end
		if func_list then
			minetest.override_item(x,{_debug_stick_func=func_list})
		end
	end
end)



