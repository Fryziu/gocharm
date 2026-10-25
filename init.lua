-- gocharm/init.lua

gocharm = {}

local S = minetest.get_translator("gocharm")

-- Konfiguracja z minetest.conf
local max    = tonumber(minetest.settings:get("gocharm.max") or minetest.settings:get("multihome.max")) or 5
local compat = minetest.settings:get("gocharm.compatibility") or minetest.settings:get("multihome.compatibility") or "none"

if max < 2 or max > 10000 then
	minetest.log("error", "[gocharm] max value outside of 2 - 10000 range. Resetting to 5.")
	max = 5
end

---
--- API DANYCH (Z automatyczną migracją z multihome)
---

local function get_player_meta(player)
	if type(player) == "string" then
		player = minetest.get_player_by_name(player)
	end
	if not player then return nil end
	return player:get_meta()
end

function gocharm.get_homes_table(player)
	local meta = get_player_meta(player)
	if not meta then return {} end

	local raw = meta:get_string("gocharm:homes")
	-- Płynna migracja: jeśli brak nowych danych, sprawdź czy są zapisane pod starą nazwą multihome
	if raw == "" then
		raw = meta:get_string("multihome")
		if raw ~= "" then
			meta:set_string("gocharm:homes", raw)
			meta:set_string("gocharm:master", meta:get_string("multihome:master"))
		end
	end

	if raw == "" then return {} end
	return minetest.deserialize(raw) or {}
end

local function count_homes(list)
	local count = 0
	for _, _ in pairs(list) do
		count = count + 1
	end
	return count
end

-- [function] Set / Update home
function gocharm.set(player, name, pos)
	local meta = get_player_meta(player)
	if not meta then return false, "Player offline" end
	if type(player) == "string" then
		player = minetest.get_player_by_name(player)
	end

	local pos = pos or vector.round(player:get_pos())
	local homes = gocharm.get_homes_table(player)
	local home_count = count_homes(homes)

	if not homes[name] and home_count >= max then
		return false, "Error: too many locations. Limit is " .. tostring(max)
	end

	homes[name] = pos
	meta:set_string("gocharm:homes", minetest.serialize(homes))

	local current_master = meta:get_string("gocharm:master")
	if current_master == "" or home_count == 0 then
		meta:set_string("gocharm:master", name)
	end

	return true, "Set location \"" .. name .. "\" to " .. minetest.pos_to_string(pos)
end

-- [function] Delete home
function gocharm.delete(player, name)
	local meta = get_player_meta(player)
	if not meta then return false, "Player offline" end

	local homes = gocharm.get_homes_table(player)
	if homes[name] then
		homes[name] = nil
		meta:set_string("gocharm:homes", minetest.serialize(homes))

		if meta:get_string("gocharm:master") == name then
			local next_home = next(homes)
			meta:set_string("gocharm:master", next_home or "")
		end
		return true, "Removed location \"" .. name .. "\""
	else
		return false, "Location \"" .. name .. "\" does not exist!"
	end
end
gocharm.remove = gocharm.delete -- Alias wsteczny

-- [function] Get home position
function gocharm.get(player, name)
	local homes = gocharm.get_homes_table(player)
	return homes[name]
end

-- [function] Get MASTER / Default home
function gocharm.get_default(player)
	local meta = get_player_meta(player)
	if not meta then return nil end

	local master = meta:get_string("gocharm:master")
	local homes = gocharm.get_homes_table(player)
	if master ~= "" and homes[master] then
		return master
	end

	local default = next(homes)
	return default
end

-- [function] List homes
function gocharm.list(player)
	local meta = get_player_meta(player)
	local homes = gocharm.get_homes_table(player)
	local master = meta and meta:get_string("gocharm:master") or ""
	if homes then
		local list = "None"
		for name, h in pairs(homes) do
			local prefix = (name == master) and "[MASTER] " or ""
			local entry = prefix .. name .. " " .. minetest.pos_to_string(h)
			if list == "None" then
				list = entry
			else
				list = list .. ", " .. entry
			end
		end
		return true, "Your Locations (" .. count_homes(homes) .. "/" .. max .. "): " .. list
	end
end

-- [function] Teleport to home
function gocharm.go(player, name)
	if type(player) == "string" then
		player = minetest.get_player_by_name(player)
	end
	if not player then return false end

	local pos = gocharm.get(player, name)
	if pos then
		player:set_pos(pos)
		return true, "Teleported to \"" .. name .. "\""
	else
		return false, "Invalid location \"" .. tostring(name) .. "\""
	end
end

---
--- GUI AMULETU
---

local player_selected_home = {}
local player_home_cache = {}

function gocharm.show_amulet_formspec(player)
	local meta = get_player_meta(player)
	if not meta then return end
	local player_name = player:get_player_name()
	local homes = gocharm.get_homes_table(player)
	local master = meta:get_string("gocharm:master")
	local home_count = count_homes(homes)

	local sorted_keys = {}
	for k, _ in pairs(homes) do
		table.insert(sorted_keys, k)
	end
	table.sort(sorted_keys, function(a, b)
		if a == master then return true end
		if b == master then return false end
		return a < b
	end)

	player_home_cache[player_name] = sorted_keys

	local list_items = {}
	local selected_idx = 1
	local current_sel = player_selected_home[player_name]

	for i, name in ipairs(sorted_keys) do
		local pos = homes[name]
		local is_m = (name == master)
		local color_prefix = is_m and "#FFD700" or ""
		local tag = is_m and "[MASTER] " or "        "
		local raw_entry = color_prefix .. tag .. name .. " (" .. pos.x .. ", " .. pos.y .. ", " .. pos.z .. ")"

		table.insert(list_items, minetest.formspec_escape(raw_entry))

		if name == current_sel then
			selected_idx = i
		end
	end

	if #sorted_keys > 0 and not current_sel then
		player_selected_home[player_name] = sorted_keys[1]
		selected_idx = 1
	end

	local form = "size[9,7.2]" ..
		"label[0.3,0.35;" .. minetest.formspec_escape(S("Traveler's Amulet") .. " - " .. S("Locations (@1/@2)", tostring(home_count), tostring(max))) .. "]" ..
		"textlist[0.3,0.8;5.2,5.0;home_list;" .. table.concat(list_items, ",") .. ";" .. tostring(selected_idx) .. ";false]" ..
		"button[5.8,0.8;2.9,0.8;btn_teleport;" .. minetest.formspec_escape(S("Teleport")) .. "]" ..
		"button[5.8,1.8;2.9,0.8;btn_update;" .. minetest.formspec_escape(S("Update to My Pos")) .. "]" ..
		"button[5.8,2.8;2.9,0.8;btn_set_master;" .. minetest.formspec_escape(S("Set as MASTER")) .. "]" ..
		"button[5.8,5.0;2.9,0.8;btn_delete;" .. minetest.formspec_escape(S("Delete")) .. "]" ..
		"box[0.3,6.05;8.4,0.02;#555555]" ..
		"field[0.3,6.5;5.2,0.8;new_name;" .. minetest.formspec_escape(S("New location name:")) .. ";]" ..
		"field_close_on_enter[new_name;false]" ..
		"button[5.8,6.4;2.9,0.8;btn_save_new;" .. minetest.formspec_escape(S("Save Location")) .. "]"

	minetest.show_formspec(player_name, "gocharm:amulet", form)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "gocharm:amulet" or not player then return end

	local player_name = player:get_player_name()
	local cached_keys = player_home_cache[player_name] or {}

	if fields.home_list then
		local event = minetest.explode_textlist_event(fields.home_list)
		if event.type == "CHG" or event.type == "DCL" then
			local selected = cached_keys[event.index]
			if selected then
				player_selected_home[player_name] = selected
				if event.type == "DCL" then
					minetest.close_formspec(player_name, "gocharm:amulet")
					gocharm.go(player, selected)
					return
				end
			end
		end
	end

	local sel = player_selected_home[player_name]

	-- TELEPORT
	if fields.btn_teleport then
		if sel then
			minetest.close_formspec(player_name, "gocharm:amulet")
			gocharm.go(player, sel)
		else
			minetest.chat_send_player(player_name, S("No home selected!"))
		end
		return
	end

	-- AKTUALIZACJA POZYCJI
	if fields.btn_update then
		if sel then
			gocharm.set(player, sel, vector.round(player:get_pos()))
			minetest.chat_send_player(player_name, S('Home "@1" updated to current position.', sel))
			gocharm.show_amulet_formspec(player)
		else
			minetest.chat_send_player(player_name, S("No home selected!"))
		end
		return
	end

	-- USTAW JAKO MASTER
	if fields.btn_set_master then
		if sel then
			local meta = get_player_meta(player)
			if meta then meta:set_string("gocharm:master", sel) end
			minetest.chat_send_player(player_name, S('Set "@1" as MASTER home.', sel))
			gocharm.show_amulet_formspec(player)
		else
			minetest.chat_send_player(player_name, S("No home selected!"))
		end
		return
	end

	-- USUŃ
	if fields.btn_delete then
		if sel then
			gocharm.delete(player, sel)
			player_selected_home[player_name] = nil
			minetest.chat_send_player(player_name, S('Home "@1" has been deleted.', sel))
			gocharm.show_amulet_formspec(player)
		else
			minetest.chat_send_player(player_name, S("No home selected!"))
		end
		return
	end

	-- NOWA LOKACJA
	if fields.btn_save_new then
		local new_name = (fields.new_name or ""):gsub("^%s*(.-)%s*$", "%1")
		if new_name == "" then
			minetest.chat_send_player(player_name, S("Name cannot be empty!"))
			return
		end

		local homes = gocharm.get_homes_table(player)
		if homes[new_name] then
			minetest.chat_send_player(player_name, S('Home "@1" already exists! Choose another name.', new_name))
			return
		end

		if count_homes(homes) >= max then
			minetest.chat_send_player(player_name, S("Limit of @1 homes reached!", tostring(max)))
			return
		end

		gocharm.set(player, new_name, vector.round(player:get_pos()))
		player_selected_home[player_name] = new_name
		gocharm.show_amulet_formspec(player)
		return
	end
end)

---
--- REJESTRACJA PRZEDMIOTU: gocharm:amulet
---

local modpath = minetest.get_modpath("gocharm")
local texture_amulet = "gocharm_amulet.png"

-- Sprawdzenie czy istnieje własna grafika (lub ze starego folderu multihome)
local test_file = io.open(modpath .. "/textures/gocharm_amulet.png", "r") or io.open(modpath .. "/textures/multihome_amulet.png", "r")
if test_file then
	test_file:close()
	if io.open(modpath .. "/textures/multihome_amulet.png", "r") and not io.open(modpath .. "/textures/gocharm_amulet.png", "r") then
		texture_amulet = "multihome_amulet.png"
	end
else
	-- Bezpieczny fallback
	if minetest.get_modpath("mcl_core") then
		texture_amulet = "mcl_core_gold_ingot.png"
	elseif minetest.get_modpath("default") then
		texture_amulet = "default_tool_steelcompass.png"
	end
end

local amulet_def = {
	description = S("Traveler's Amulet") .. "\n" .. S("LMB: Open Menu\nRMB: Teleport to MASTER"),
	inventory_image = texture_amulet,
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		if user and user:is_player() then
			gocharm.show_amulet_formspec(user)
		end
		return itemstack
	end,

	on_place = function(itemstack, placer, pointed_thing)
		if not placer or not placer:is_player() then return itemstack end
		local controls = placer:get_player_control()
		if controls.sneak then
			gocharm.show_amulet_formspec(placer)
		else
			local master = gocharm.get_default(placer)
			if master then
				gocharm.go(placer, master)
			else
				minetest.chat_send_player(placer:get_player_name(), S("No MASTER home set!"))
			end
		end
		return itemstack
	end,

	on_secondary_use = function(itemstack, user, pointed_thing)
		if not user or not user:is_player() then return itemstack end
		local controls = user:get_player_control()
		if controls.sneak then
			gocharm.show_amulet_formspec(user)
		else
			local master = gocharm.get_default(user)
			if master then
				gocharm.go(user, master)
			else
				minetest.chat_send_player(user:get_player_name(), S("No MASTER home set!"))
			end
		end
		return itemstack
	end,
}

local model_file = io.open(modpath .. "/models/gocharm_amulet.obj", "r") or io.open(modpath .. "/models/multihome_amulet.obj", "r")
if model_file then
	model_file:close()
	amulet_def.wield_mesh = io.open(modpath .. "/models/gocharm_amulet.obj", "r") and "gocharm_amulet.obj" or "multihome_amulet.obj"
	amulet_def.wield_scale = {x = 1, y = 1, z = 1}
else
	amulet_def.wield_image = texture_amulet
end

minetest.register_craftitem("gocharm:amulet", amulet_def)

---
--- CRAFTING (Magiczny Amulet Podróżnika)
---

if minetest.get_modpath("mcl_core") then
	local redstone_block = "mesecons_torch:redstoneblock"
	if minetest.registered_nodes["mcl_redstone:redstone_block"] then
		redstone_block = "mcl_redstone:redstone_block"
	end

	-- Wariant z brązowym grzybem
	minetest.register_craft({
		output = "gocharm:amulet",
		recipe = {
			{"mcl_books:book",          "mcl_copper:copper_ingot", redstone_block},
			{"mcl_core:gold_ingot",     "mcl_core:diamond",        "mcl_core:gold_ingot"},
			{"mcl_mobitems:spider_eye", "mcl_copper:copper_ingot", "mcl_mushrooms:mushroom_brown"}
		}
	})

	-- Wariant z czerwonym grzybem
	minetest.register_craft({
		output = "gocharm:amulet",
		recipe = {
			{"mcl_books:book",          "mcl_copper:copper_ingot", redstone_block},
			{"mcl_core:gold_ingot",     "mcl_core:diamond",        "mcl_core:gold_ingot"},
			{"mcl_mobitems:spider_eye", "mcl_copper:copper_ingot", "mcl_mushrooms:mushroom_red"}
		}
	})
elseif minetest.get_modpath("default") then
	minetest.register_craft({
		output = "gocharm:amulet",
		recipe = {
			{"default:book",           "default:copper_ingot", "default:mese"},
			{"default:gold_ingot",      "default:diamond",      "default:gold_ingot"},
			{"default:obsidian_shard", "default:copper_ingot", "flowers:mushroom_brown"}
		}
	})
end

---
--- KOMENDY CZATU: /gocharm <set | del | go | list>
---

minetest.register_privilege("gocharm", {
	description = "Can use /gocharm commands",
	give_to_singleplayer = false,
})

minetest.register_chatcommand("gocharm", {
	description = "Manage your teleport points",
	params = "<set | del | go | list> <name>",
	privs = {gocharm = true},
	func = function(name, params)
		local p = params:split(" ")
		local action = p[1]
		local target_name = p[2]

		if action == "set" and target_name then
			return gocharm.set(name, target_name)
		-- Obsługa preferowanego 'del' oraz tradycyjnych 'delete' / 'remove'
		elseif (action == "del" or action == "delete" or action == "remove") and target_name then
			return gocharm.delete(name, target_name)
		elseif action == "go" then
			local home = target_name or gocharm.get_default(name)
			if not home then
				return false, "Usage: /gocharm go <name>"
			end
			return gocharm.go(name, home)
		elseif action == "list" then
			return gocharm.list(name)
		else
			return false, "Usage: /gocharm <set | del | go | list> [name]"
		end
	end,
})

-- Szybki alias konsolowy: /h [nazwa] -> teleportuje do MASTER lub podanej lokacji
minetest.register_chatcommand("h", {
	description = "Quick teleport to MASTER or named location",
	privs = {interact = true},
	func = function(name, param)
		local target = (param ~= "" and param) or gocharm.get_default(name)
		if target then
			return gocharm.go(name, target)
		else
			return false, "No location set! Use /gocharm set <name>"
		end
	end,
})
