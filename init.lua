
metamorphosis = {};

local modpath = minetest.get_modpath(minetest.get_current_modname());

metamorphosis.translator = minetest.get_translator("metamorphosis");

dofile(modpath.."/functions.lua");

dofile(modpath.."/reports.lua");

dofile(modpath.."/metamorphosis_analyzer.lua")

dofile(modpath.."/crafting.lua");


