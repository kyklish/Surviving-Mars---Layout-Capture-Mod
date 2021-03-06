-- File name explanation: "%build_category% - %build_pos% - %Id%.lua"
-- %build_pos% - two digit format only for file name, for natural sort in file manager

-- In-Game Layout Editor: ChoGGi's "Expanded Cheat Menu" -> "Debug" -> "Ged Presets" -> "LayoutConstruction"

-- classes not final yet
function OnMsg.ClassesPostprocess()
	if BuildingTemplates.Service_Slice_Simple then
		return
	end

	-- Common id string, for simplicity and correct logic used in several places below
	local id = "Service_Slice_Simple"
	-- Common id string, to identify menu, in which layout object will be placed
	local build_category = "Layout Infrastructure"

	-- Info from ChoGGi's Layout Example
	PlaceObj("BuildingTemplate", {
		-- "Id", "LayoutList", "Group" must begin with capital letter!!! All is case sensitive
		-- keep it unique folks 
		"Id", id,
		-- "LayoutList" id corresponds to the "LayoutConstruction" below
		"LayoutList", id,
		-- what group to add it to
		"Group", build_category,
		"build_category", build_category,
		-- pos in build menu
		"build_pos", 0,
		"display_name", "Service Slice Simple",
		"display_name_pl", "Service Slice Simple",
		"description", "Diner + Infirmary + Grocery + Statue",
		"display_icon", "UI/Icons/Buildings/dinner.tga",
		-- hands off
		"template_class", "LayoutConstructionBuilding",
		"entity", "InvisibleObject",
		"construction_mode", "layout",
	})

	PlaceObj("LayoutConstruction", {
		-- Don't write here like this: "group" = "Default" ... this cause error
		group = "Default",
		id = id,

		-- Buildings
		-- "template" -> String -> Class Template.
		--		Open: "Expanded Cheat Menu" (F2) -> "Debug" -> "Object" -> "Examine Object" (F4) -> "Tools" -> "Ged Editor".
		--		Open: "Expanded Cheat Menu" (F2) -> "Debug" -> "Object" -> "Open In Ged Objects Editor".
		--		Find: "Root Object" on left screen (Selected by default) -> "Misc" on right screen -> "Class Template".
		--		"ElectricitySwitch", "LifesupportSwitch", "passage_grid" not supported.
		-- "pos" -> point(x,y) -> Relative position ("base point" of 3D model).
		--		By default (if you skip parameter) it will be point(0,0).
		--		Help: "Expanded Cheat Menu" (F2) -> "Debug" -> "Grids" -> "Toggle Building Grid Position" (Shift+F3).
		--		Help: "Expanded Cheat Menu" (F2) -> "Debug" -> "Object" -> "Examine Object" (F4) -> "Eye" icon ("Mark Object") on top of dialog window.
		--		Help: "Expanded Cheat Menu" (F2) -> "Debug" -> "Object" -> "Examine Object" (F4) -> "Object" -> "Hex Shape Toggle" -> "HexPeripheralShapes".
		--		"Mark" object to find out "base point" of 3D model (see above). You rotate building around base point. For example "Diner" has base point not on center of 3D model.
		--		Place all buildings. Choose in mind, where will be center of your layout. Find positions relative to center of layout.
		-- "dir" -> Integer -> Building direction.
		--		Possible values: 0-5. 1 click is 60 degree.
		--		Use keys "R" (counterclockwise) and "T" (clockwise) to rotate when build.
		--		Count: "dir" is how many times you press "T" key when build.
		--		Open: "Expanded Cheat Menu" (F2) -> "Debug" -> "Object" -> "Examine Object" (F4).
		--		Find: "GetAngle()" returns angle in minutes, measured clockwise from the x+ axis. Divide it by 3600 = 60degree x 60minutes.
		-- "entity" -> String -> 3D model of building.
		--		Use keys "[" and "]" to cycle between visual variants when build.
		--		Open: "Expanded Cheat Menu" (F2) -> "Debug" -> "Object" -> "Examine Object" (F4).
		--		Find: "GetEntity()" or "entity" field.
		--		Example: "Diner" building have default "entity" "Restaurant".
		-- "instant" -> Boolean -> Instant build.
		--		Possible values: true, false.
		--		Example: For "Universal Depot" must be "true". But game build "Storages" instantly in any case. Not needed.
		
		PlaceObj("LayoutConstructionEntry", {
			"template", "Diner",
			"dir", 5,
			"entity", "Restaurant",
		}),
		
		PlaceObj("LayoutConstructionEntry", {
			"template", "Infirmary",
			"pos", point(-2,2),
			"dir", 4,
			"entity", "Infirmary",
		}),

		PlaceObj("LayoutConstructionEntry", {
			"template", "ShopsFood",
			"pos", point(-1,0),
			"dir", 1,
			"entity", "ShopsFood",
		}),
		
		PlaceObj("LayoutConstructionEntry", {
			"template", "Statue",
			"pos", point(-2,3),
			"entity", "GardenStatue_01",
		}),

		-- Cables
		-- "pos" -> point(x,y) -> Start position
		-- "cur_pos1" -> point(x,y) -> Next cursor position (build "line" of cables)
		-- "cur_pos2" -> point(x,y) -> Next cursor position (build second "line", that continues first)
		-- PlaceObj("LayoutConstructionEntry", {
			-- "template", "electricity_grid",
			-- "pos", point(-1, 3),
			-- "cur_pos1", point(-1, 0),
			-- "cur_pos2", point(2, -3),
		-- }),

		-- Pipes
		-- PlaceObj("LayoutConstructionEntry", {
			-- "template", "life_support_grid",
			-- "pos", point(0, -7),
			-- "cur_pos1", point(0, -8),
		-- }),
	})
end
