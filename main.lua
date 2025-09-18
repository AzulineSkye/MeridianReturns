mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)

PATH = _ENV["!plugins_mod_folder_path"]
NAMESPACE = "mnr"

local init = function()
	local folders = {
		"Misc", -- load first cuz of the library
		"Enemies",
		"Elites",
		"Survivors",
		"Items",
		"Interactables",
		"Artifacts"
	}

	for _, folder in ipairs(folders) do
		local filepaths = path.get_files(path.combine(PATH, folder))
		for _, filepath in ipairs(filepaths) do
			if string.sub(filepath, -4, -1) == ".lua" then
				require(filepath)
			end
		end
	end
	require("stageLoader")
	
	gm.sprite_replace(gm.constants.sTitle, path.combine(PATH, "Sprites/UI/title.png"), 1, false, false, 410, 100)

	HOTLOADING = true
end
Initialize(init)

if HOTLOADING then
	init()
end
