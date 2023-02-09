----------------------------
-- Metamorphosis Analyzer --
----------------------------
--------- Ver 1.0 ----------
-----------------------
-- Initial Functions --
-----------------------
local S = metamorphosis.translator;

metamorphosis.metamorphosis_analyzer = appliances.appliance:new(
    {
      node_name_inactive = "hades_metamorphosis:metamorphosis_analyzer",
      node_name_active = "hades_metamorphosis:metamorphosis_analyzer_active",
      
      node_description = S("Metamorphosis analyzer"),
    	node_help = S("Connect to power 200 EU (LV) and computiong power 10 GFLOPS.").."\n"..S("Analyze nodes and return some informations about them."),
      
      output_stack_size = 2,
      
      supply_connect_sides = {"right", "left"},
      need_supply = true,
    })

local metamorphosis_analyzer = metamorphosis.metamorphosis_analyzer

metamorphosis_analyzer:power_data_register(
  {
    ["LV_power"] = {
        demand = 200,
        run_speed = 1,
        disable = {"no_power"},
      },
    ["power_generators_power"] = {
        demand = 200,
        run_speed = 1,
        disable = {"no_power"},
      },
    ["no_power"] = {
      },
  })
metamorphosis_analyzer:supply_data_register(
  {
    ["super_computer_mflops_supply"] = {
        demand = 10000,
        run_speed = 1,
        disable = {"no_supply"},
      },
    ["no_supply"] = {
      },
  })

--------------
-- Formspec --
--------------

function metamorphosis_analyzer:get_formspec(meta, production_percent, consumption_percent)
  local progress = "image[3.6,0.5;5.5,0.95;appliances_production_progress_bar.png^[transformR270]]";
  if production_percent then
    progress = "image[3.6,0.5;5.5,0.95;appliances_production_progress_bar.png^[lowpart:" ..
            (production_percent) ..
            ":appliances_production_progress_bar_full.png^[transformR270]]";
  end
  if consumption_percent then
    progress = progress.."image[3.6,1.35;5.5,0.95;appliances_consumption_progress_bar.png^[lowpart:" ..
            (consumption_percent) ..
            ":appliances_consumption_progress_bar_full.png^[transformR270]]";
  else
    progress = progress.."image[3.6,1.35;5.5,0.95;appliances_consumption_progress_bar.png^[transformR270]]";
  end
  
  local formspec =  "formspec_version[3]" .. "size[12.75,8.5]" ..
                    "background[-1.25,-1.25;15,10;appliances_appliance_formspec.png]" ..
                    progress..
                    "list[current_player;main;0.3,3;10,4;]" ..
                    "list[context;"..self.input_stack..";2,0.25;1,1;]" ..
                    "list[context;"..self.use_stack..";2,1.5;1,1;]" ..
                    "list[context;"..self.output_stack..";9.75,0.25;1,2;]" ..
                    "listring[current_player;main]" ..
                    "listring[context;"..self.input_stack.."]" ..
                    "listring[current_player;main]" ..
                    "listring[context;"..self.use_stack.."]" ..
                    "listring[current_player;main]"..
                    "listring[context;"..self.output_stack.."]" ..
                    "listring[current_player;main]";
  return formspec;
end

--------------------
-- Node callbacks --
--------------------

function metamorphosis_analyzer:recipe_aviable_input(inventory)
  local input = nil
  
  local input_stack = inventory:get_stack(self.input_stack, 1)
  local input_name = input_stack:get_name()
  input = self.recipes.inputs[input_name]
  if (input==nil) then
    return nil, nil
  end
  
  local usage_stack = inventory:get_stack(self.use_stack, 1)
  local usage_name = usage_stack:get_name()
  if (usage_name=="") then
    return nil, nil
  end
  
  local usage = {
    outputs = {usage_name},
    consumption_time = input.production_time,
    production_step_size = 1,
  }
  return input, usage
end

function metamorphosis_analyzer:time_update(timer_step)
  timer_step.production_step_size = self:recipe_step_size(timer_step.use_usage.production_step_size*timer_step.speed)
  timer_step.consumption_step_size = timer_step.production_step_size
  
  timer_step.production_time = timer_step.production_time + timer_step.production_step_size
  timer_step.consumption_time = timer_step.consumption_time + timer_step.consumption_step_size
end
  
function metamorphosis_analyzer:recipe_inventory_can_put(pos, listname, index, stack, player)
  if player then
    if minetest.is_protected(pos, player:get_player_name()) then
      return 0
    end
  end
  
  if listname == self.input_stack then
    return self.recipes.inputs[stack:get_name()] and
                stack:get_count() or 0
  end
  if listname == self.use_stack then
    return stack:get_count() or 0
  end
  return 0
end

----------
-- Node --
----------

local node_def = {
    paramtype2 = "facedir",
    groups = {cracky = 2},
    legacy_facedir_simple = true,
    is_ground_content = false,
    sounds = hades_sounds.node_sound_stone_defaults(),
    drawtype = "node",
  }

local node_inactive = {
    tiles = {
        "metamorphosis_metamorphosis_analyzer_top.png",
        "metamorphosis_metamorphosis_analyzer_bottom.png",
        "metamorphosis_metamorphosis_analyzer_side.png",
        "metamorphosis_metamorphosis_analyzer_side.png",
        "metamorphosis_metamorphosis_analyzer_side.png",
        "metamorphosis_metamorphosis_analyzer_front.png"
    },
  }

local node_active = {
    tiles = {
        "metamorphosis_metamorphosis_analyzer_top.png",
        "metamorphosis_metamorphosis_analyzer_bottom.png",
        "metamorphosis_metamorphosis_analyzer_side.png",
        "metamorphosis_metamorphosis_analyzer_side.png",
        "metamorphosis_metamorphosis_analyzer_side.png",
        {
          image = "metamorphosis_metamorphosis_analyzer_front_active.png",
          backface_culling = true,
          animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 1.5
          }
        }
    },
  }

metamorphosis_analyzer:register_nodes(node_def, node_inactive, node_active)

-------------------------
-- Recipe Registration --
-------------------------

local analyze_time = 3600
-- analyze_time = 10

local function usbstick_output(self, timer_step)
  if (timer_step.production_time<analyze_time) then
    return "laptop:usbstick"
  end
  local input_stack = timer_step.inv:get_stack(self.input_stack, 1)
  local input_meta = input_stack:get_meta()
  local os_storage = minetest.deserialize(input_meta:get_string("os_storage"))
  
  local node_name = timer_step.use_usage.outputs[1]
  local node_report = S("This node looks to be stable in all natural conditions.")
  
  local node_def = minetest.registered_nodes[node_name]
  if node_def then
    local hlp = string.find(node_name, ":")
    node_name = node_def.short_description or node_def._tt_original_description or node_def.description or string.sub(node_name, hlp+1)
    node_name = string.gsub(node_name, " ", "_")
    if node_def._metamorphosis_report then
      node_report = node_def._metamorphosis_report
    end
  end
  local report_name = S("Report").."_"..node_name.."_"..minetest.get_gametime()
  local report = {
    owner = "", -- ??
    content = S("Node").." "..node_name.." "..S("analyze")..":\n\n"..node_report,
    ctime = os.time(),
  }
  
  if os_storage then
    if not os_storage["stickynote:files"] then
      os_storage["stickynote:files"] = {}
    end
    os_storage["stickynote:files"][report_name] = report
    
    input_meta:set_string("os_storage", minetest.serialize(os_storage))
  end
  
  return {input_stack}
end

appliances.register_craft_type("metamorphosis_metamorphosis_analyzer", {
    description = S("Store report"),
    width = 1,
    height = 1,
  })

appliances.register_craft_type("metamorphosis_metamorphosis_analyzer_use", {
    description = S("Analyze"),
    width = 1,
    height = 1,
  })
  
metamorphosis_analyzer:recipe_register_input(
  "laptop:usbstick",
  {
    inputs = 1,
    outputs = {usbstick_output},
    production_time = analyze_time,
    consumption_step_size = 1,
  });

--metamorphosis_analyzer:register_recipes("metamorphosis_metamorphosis_analyzer", "metamorphosis_metamorphosis_analyzer_use")

