
mortar_pestle = {
  setting = {
    item_displacement = -1/16,
  }
}
minetest.register_tool("food_expansion:pestle", {
	description = "Pestle",
	inventory_image = "unknown.png",
})

local tmp = {}

minetest.register_entity("food_expansion:item2",{
	hp_max = 1,
	visual="wielditem",
	visual_size={x=.33,y=.33},
	collisionbox = {0,0,0,0,0,0},
	physical=false,
	textures={"air"},
	on_activate = function(self, staticdata)
		if tmp.nodename ~= nil and tmp.texture ~= nil then
			self.nodename = tmp.nodename
			tmp.nodename = nil
			self.texture = tmp.texture
			tmp.texture = nil
		else
			if staticdata ~= nil and staticdata ~= "" then
				local data = staticdata:split(';')
				if data and data[1] and data[2] then
					self.nodename = data[1]
					self.texture = data[2]
				end
			end
		end
		if self.texture ~= nil then
			self.object:set_properties({textures={self.texture}})
		end
	end,
	get_staticdata = function(self)
		if self.nodename ~= nil and self.texture ~= nil then
			return self.nodename .. ';' .. self.texture
		end
		return ""
	end,
})

local remove_item = function(pos, node)
	local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y + mortar_pestle.setting.item_displacement, z = pos.z}, .5)
	if objs then
		for _, obj in ipairs(objs) do
			if obj and obj:get_luaentity() and obj:get_luaentity().name == "food_expansion:item2" then
				obj:remove()
			end
		end
	end
end

local update_item = function(pos, node)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if not inv:is_empty("input") then
		pos.y = pos.y + mortar_pestle.setting.item_displacement
		tmp.nodename = node.name
		tmp.texture = inv:get_stack("input", 1):get_name()
		local e = minetest.add_entity(pos,"food_expansion:item2")
		local yaw = math.pi*2 - node.param2 * math.pi/2
		e:setyaw(yaw)
	end
end


minetest.register_node("food_expansion:mortar", {
	description = "Mortar",
	tiles = {"mortar_pestle.png"},
	groups = {cracky=1},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1875, -0.5, -0.1875, 0.1875, -0.4375, 0.1875}, -- NodeBox2
			{-0.25, -0.5, 0.1875, 0.25, -0.0625, 0.25}, -- NodeBox3
			{-0.25, -0.5, -0.25, 0.25, -0.0625, -0.1875}, -- NodeBox4
			{-0.25, -0.5, -0.25, -0.1875, -0.0625, 0.25}, -- NodeBox5
			{0.1875, -0.5, -0.25, 0.25, -0.0625, 0.25}, -- NodeBox6
			{-0.3125, -0.4375, -0.25, -0.25, 3.72529e-009, 0.25}, -- NodeBox7
			{0.25, -0.4375, -0.25, 0.3125, 3.72529e-009, 0.25}, -- NodeBox8
			{-0.3125, -0.4375, -0.3125, 0.3125, 2.04891e-008, -0.25}, -- NodeBox9
			{-0.3125, -0.4375, 0.25, 0.3125, 2.98023e-008, 0.3125}, -- NodeBox10
		}
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("input", 1)
	end,

	can_dig = function(pos,player)
		local meta  = minetest.get_meta(pos)
		local inv   = meta:get_inventory()
	
		if not inv:is_empty("input") then
			return false
		end
		return true
	end,
	
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if listname~="input" then
			return 0
		end
		if stack:get_name() == "food_expansion:pestle"  then
			return 0
		end
		
		if meta:get_inventory():room_for_item("input", stack) then
			return stack:get_count()
		end
		return 0
	end,
	
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if listname~="input" then
			return 0
		end
		return stack:get_count()
	end,
	
	on_rightclick = function(pos, node, clicker, itemstack)
		if itemstack:get_count() == 0 then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if not inv:is_empty("input") then
				local return_stack = inv:get_stack("input", 1)
				inv:set_stack("input", 1, nil)
				local wield_index = clicker:get_wield_index()
				clicker:get_inventory():set_stack("main", wield_index, return_stack)
				remove_item(pos, node)
				return return_stack
			end		
		end
		local this_def = minetest.registered_nodes[node.name]
		if this_def.allow_metadata_inventory_put(pos, "input", 1, itemstack:peek_item(), clicker) > 0 then
			local s = itemstack:take_item()
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			inv:add_item("input", s)
			update_item(pos,node)
		end
		return itemstack
	end,
	on_punch = function(pos, node, puncher)
		local wielded = puncher:get_wielded_item()
		local meta = minetest.get_meta(pos)
		local inv  = meta:get_inventory()
		
		if wielded:get_name() ~= 'food_expansion:pestle' then
			return
		end
		
	local input = inv:get_stack('input',1)		
	
	local function register_grind(inp, outp)
		if input:get_name() == inp then
			pos.y = pos.y + mortar_pestle.setting.item_displacement
			minetest.sound_play({name="default_dig_cracky"}, {pos=pos})
			inv:set_stack("input", 1, nil)
			remove_item(pos,node)
			update_item(pos,node)
			minetest.spawn_item(pos, outp)
		end
	end	
	register_grind("default:stone", "default:cobble")

		-- damage the pestle slightly
	wielded:add_wear(500)
	puncher:set_wielded_item(wielded)
	end,
	is_ground_content = false,
})

-- automatically restore entities lost due to /clearobjects or similar
minetest.register_lbm({
	name = "food_expansion:mortar_pestle_item_restoration",
	nodenames = { "food_expansion:mortar" },
	run_at_every_load = true,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local test_pos = {x=pos.x, y=pos.y + mortar_pestle.setting.item_displacement, z=pos.z}
		if #minetest.get_objects_inside_radius(test_pos, 0.5) > 0 then return end
		update_item(pos, node)
	end
})
