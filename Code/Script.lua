-- Skip "Pod", "Rocket" and "Tunnel", it make no sense to capture it.
-- LayoutConstruction.lua - did not support "passage_grid", "TubeSwitch" and "CableSwitch"!!!
	-- local supported_grid_contstruction_modes = {
	--		electricity_grid = true,
	--		life_support_grid = true
	-- }

-- On "Reload Lua" game not re-read mod's "metadata.lua", so when we add here path to new layout, it will
	-- not load it. Only on "restart" game will read updated "metadata.lua".
	-- So concatenate all layout files in one "Layout.lua" file, never change "metadata.lua".
	-- "ChoGGi.ComFuncs.UpdateBuildMenu()" to update menus on the fly (if we add layout on runtime
	-- via "PlaceObj(...)"), but we "Reload Lua" instead.

---- LUA STUFF ----

-- GlobalVar("tmp", {"param1","param2",}) <- this line will not create object, but boolean == false :(
-- GlobalVar("tmp", {}) tmp = {[1] = "param1", [2] = "param2",} <- create empty object, add params

-- pairs() returns key-value pairs and is mostly used for associative tables. key order is unspecified.
-- ipairs() returns index-value pairs and is mostly used for numeric tables. Non numeric keys in an array
	-- are ignored, while the index order is deterministic (in numeric order).

-- Order of function definition is essential. Must define before first usage.
	-- Search "Lua Function Forward Declaration".

-- Official documentation LuaFunctionDoc_AsyncIO.md.html for all "Async*()" functions in this script.

-- Boolean value must be tostring()-ed for concatenation.

-- Operator precedence in Lua follows the table below, from the higher to the lower priority:
	-- ^
	-- not  - (unary)
	-- *   /
	-- +   -
	-- ..
	-- <   >   <=  >=  ~=  ==
	-- and
	-- or



---- Forward function declaration ----
-- All functions are "local", we hide them from global scope, other mods will not see them
local abs
local AllObjectsTablesEmpty
local AxialDirection
local BlacklistEnabled
local BuildBuildings
local BuildCables
local BuildGrid
local BuildLayoutBodyLua
local BuildLayoutHeadLua
local BuildLayoutLua
local BuildLayoutsLua
local BuildLayoutTailLua
local BuildLines
local BuildMetadataLua
local BuildOrphans
local BuildTubesTesting
local CalculateBuildingsCost
local CalculateGridCost
local CalculateLayoutConsumptionProduction
local CalculateLayoutCost
local CalculateLayoutMaintenance
local CaptureObjects
local CheckBitConn
local CheckInputParams
local ChoGGi_ReloadLua
local ClearBitConn
local ClearBuildingTemplates
local ConsumptionVsProduction
local CreateLayoutPath
local CreateMenus
local CreateShortcuts
local DeleteLayoutFile
local FileExist
local FindEndObj
local FindHub
local FindObjByHex
local FormatResourceStr
local FormatSupplyStr
local GetBaseObjectPosition
local GetDate
local GetIdFromFileName
local GetIdList
local GetLayoutListFiles
local GetObjsByEntity
local GetOppositeDirection
local GetResourcesTable
local GetSupplyTable
local Hex
local HexDistance
local HexEqual
local HexNeighbor
local HexObjLineAsStr
local HexObjs
local IsAllNeighbors
local IsCables
local IsHub
local IsIdPresentInLayoutFolder
local IsIdUnique
local IsTubes
local LayoutCapture
local LayoutCaptureIndoor
local LayoutCaptureOutdoor
local LayoutDelete
local LayoutReloadLua
local LayoutSetParams
local LayoutSetRadius
local LayoutShowInfo
local MsgPopup
local MsgPopupBE
local DataPresent
local PhotoMode
local printD
local printDMsgOrErr
local printL
local RemoveNoConn
local RemoveInDomeBuildings
local RemoveUselessBuildings
local ReturnAllNearby
local SaveLayoutLua
local SaveLayoutsLua
local SaveMetadataLua
local SetAdditionalOrphans
local SetAllFileNames
local SetBuildCategory
local SetHubOnLineEnding
local TableEmpty
local ToStringTblI
local ToStringTblK
local TerrainTextureChange
local TrimSpace
local UpdateLayoutsLua
local WriteToFiles




-- If you change mod name: change "layoutIdPrefix", "title" in "metadata.lua", functions printD() and CreateShortcuts()
local modName = "Layout Capture Mod"
-- If you change mod id: change "id" in "metadata.lua"
local modId = "Kyklish_Layout_Capture_Mod"
local layoutIdPrefix = "_LCM_" -- (L)ayout (C)apture (M)od

---- DEBUG ----

-- Open in Notepad++, and hit [Ctrl-Q] to toggle comment
-- local DEBUG = true -- Print some info to console
-- local DEBUG_EXAMINE = true -- Examine lists of objects and "base" object
-- local DEBUG_LUA = true -- Do not overwrite existing lua files

-- This extension will be added to all lua files if DEBUG_LUA enabled
local dbgExt = ""
if DEBUG_LUA then
	dbgExt = ".txt"
end

-- Print to "Layout Mod" log file
printL = function(data)
	if type(data) == "table" then
		data = ToStringTblK(data)
	end
	data = data:gsub("\n", "\n\t")
	print("[LCM] " .. data)
	if BlacklistEnabled() then
		return
	end
	-- -1 - append to file
	AsyncStringToFile(CurrentModPath .. "log.txt", data .. "\n", -1)
end

printD = function(data)
	if DEBUG then
		printL(data)
	end
end

local GlobalError = false

printDMsgOrErr = function(err, sucess, fail)
	if err then
		GlobalError = true
		printL(fail)
		printL(err)
	else
		if sucess then
			printD(sucess)
		end
	end
end

MsgPopup = function(str)
	-- Maximum 2 lines of text
	-- ChoGGi.ComFuncs.MsgPopup(text, title, params)
	-- params = {
		-- expiration = integer, -- how long to show in seconds (default 10)
		-- size = boolean, -- "false" - long text will wrap, "true" - show long text in one line (set default "expiration" to 25)
		-- image = string, -- icon file name
		-- objects = obj or {}, -- click icon to view obj
		-- callback = function,
		-- max_width = integer, -- (default 1000)
	-- }
	printD("[MP] " .. str)
	ChoGGi.ComFuncs.MsgPopup(str, modName, {size = true})
end

MsgPopupBE = function()
	MsgPopup("AsyncIO functions are in blacklist, read info: [" .. ShortcutShowInfo .. "]")
end

-- Remove all layouts from game
ClearBuildingTemplates = function()
	local bt = BuildingTemplates
	local string_find = string.find
	-- Remove only layouts, present in "Code/Layout" folder. If we delete layout, it will be still present in running game. Not good.
	-- for i, id in ipairs(GetIdList()) do
		-- bt[id] = nil
	-- end
	-- Remove all "BuildingTemplates", which starts with "layoutIdPrefix". Will clear all layouts. Good.
	for key, val in pairs(bt) do
		if string_find(key, layoutIdPrefix) == 1 then
			bt[key] = nil
			printD("BuildingTemplates[" .. key .. "] = nil")
		end
	end
end

-- ReloadLua() is in-game function name, don't use it!!!
LayoutReloadLua = function()
	-- cls()
	printD(GetDate())
	-- Remove all layouts from game before reload lua, so we can manually edit layout in text editor and see result after reload
	ClearBuildingTemplates()
	-- Run in real time thread to show MsgPopup() properly!
	-- Else it will be showed after ChoGGi.ComFuncs.ReloadLua() finished. No sense.
	CreateRealTimeThread(function()
		MsgPopup("BEGIN RELOAD LUA")
		Sleep(1000)
		-- Variant 1: Reload all mods + all mods items.
			-- ChoGGi.ComFuncs.ReloadLua() -- Reload mods in "proper" sequence. Maybe most reliable variant.
		-- Variant 2: Reload only my mod + all mods items.
			-- table.remove_entry(AccountStorage.LoadMods, modId)
			-- TurnModOn(modId)
			-- ModsReloadItems()
		-- Variant 3: Reload all mods items.
			ModsReloadItems()
		MsgPopup("DONE RELOAD LUA")
	end)
end

GetDate = function()
	local date = ""
	if not BlacklistEnabled() then
		date = date .. os.date("%Y/%m/%d-%H:%M:%S")
	end
	return "--------" .. date .. "--------"
end




---- SHORTCUTS ----

local key = "Insert"
local ShortcutCaptureOutdoor   = "" .. key
local ShortcutCaptureIndoor    = "Ctrl-" .. key
local ShortcutSetParams        = "Alt-" .. key
local ShortcutShowInfo         = "Shift-" .. key
local ShortcutUpdateLayoutsLua = "Alt-Shift-" .. key
local ShortcutReloadLua        = "Ctrl-Shift-" .. key
local ShortcutPhotoMode        = "Ctrl-Alt-Shift-" .. key
local ShortcutSetRadius        = "Alt-M"
local ShortcutDeleteLayout     = "Ctrl-Alt-Shift-Delete"

-- After this message ChoGGi's object is ready to use
CreateShortcuts = function()
	printD("Shortcuts created")
	local Actions = ChoGGi.Temp.Actions
	
	-- ActionName = 'Display Name In "Key Bindings" Menu' ("Surviving Mars" -> "Options" -> "Key Bindings")
	-- OnAction = FuncName (for example "cls": clear log)
	Actions[#Actions + 1] = {
		ActionName = "Layout Capture Outdoor",
		ActionId = "LCM.Capture.Outdoor",
		OnAction = LayoutCaptureOutdoor,
		ActionShortcut = ShortcutCaptureOutdoor,
		ActionBindable = true,
	}

	Actions[#Actions + 1] = {
		ActionName = "Layout Capture Indoor",
		ActionId = "LCM.Capture.Indoor",
		OnAction = LayoutCaptureIndoor,
		ActionShortcut = ShortcutCaptureIndoor,
		ActionBindable = true,
	}
	
	Actions[#Actions + 1] = {
		ActionName = "Layout Set Params",
		ActionId = "LCM.Set.Params",
		OnAction = LayoutSetParams,
		ActionShortcut = ShortcutSetParams,
		ActionBindable = true,
	}

	Actions[#Actions + 1] = {
		ActionName = "Layout Show Info",
		ActionId = "LCM.Show.Info",
		OnAction = LayoutShowInfo,
		ActionShortcut = ShortcutShowInfo,
		ActionBindable = true,
	}

	Actions[#Actions + 1] = {
		ActionName = 'Layout Update "Layouts.lua"',
		ActionId = "LCM.Update.Layouts.Lua",
		OnAction = UpdateLayoutsLua,
		ActionShortcut = ShortcutUpdateLayoutsLua,
		ActionBindable = true,
	}

	Actions[#Actions + 1] = {
		ActionName = "Layout Reload Lua",
		ActionId = "LCM.Reload.Lua",
		OnAction = LayoutReloadLua,
		ActionShortcut = ShortcutReloadLua,
		ActionBindable = true,
	}

	Actions[#Actions + 1] = {
		ActionName = "Layout Photo Mode",
		ActionId = "LCM.Photo.Mode",
		OnAction = PhotoMode,
		ActionShortcut = ShortcutPhotoMode,
		ActionBindable = true,
	}

	Actions[#Actions + 1] = {
		ActionName = "Layout Set Radius",
		ActionId = "LCM.Set.Radius",
		OnAction = LayoutSetRadius,
		ActionShortcut = ShortcutSetRadius,
		ActionBindable = true,
	}

	Actions[#Actions + 1] = {
		ActionName = "Layout Delete",
		ActionId = "LCM.Delete.Layout",
		OnAction = LayoutDelete,
		ActionShortcut = ShortcutDeleteLayout,
		ActionBindable = true,
	}
end




---- MENUS ----

-- In-game table with root menus, which appears on pressing [B]:
-- Enhanced Cheat Menu -> Console -> ~BuildCategories

-- In-game table with menu subcategories (example is [Depot] in [Storages]):
-- Enhanced Cheat Menu -> Console -> ~BuildMenuSubcategories

-- Empty menu is not visible. Add building, and menu will appear.

-- Path to menu icon
local menuIcon = "UI/MenuIcon.png"
-- Display name of each menu
local menuDisplayName = "Layout"
-- Add this prefix to id of original menu to create id for my menus: "Layout Infrastructure"
local menuIdPrefix = "Layout "
-- Add suffix to id of original menu to create description for my menus: "Infrastructure Layouts"
local menuDescrSuffix = " Layouts"
-- Table with id of original menus. Surviving Mars have 14 menus. Look in ~BuildCategories table
local origMenuId = {
	[1]  = "Infrastructure",
	[2]  = "Power",
	[3]  = "Production",
	[4]  = "Life-Support",
	[5]  = "Storages",
	[6]  = "Domes",
	[7]  = "Habitats",
	[8]  = "Dome Services",
	[9]  = "Dome Spires",
	[10] = "Decorations",
	[11] = "Outside Decorations",
	[12] = "Wonders",
	[13] = "Landscaping",
	[14] = "Terraforming",
	[15] = "Default", -- add my param on last position, we will use it to create id for my submenu in root menu
}
-- Table with id for my menus
local menuId = {}

CreateMenus = function()
	-- Create id for my submenus
	for i, id in ipairs(origMenuId) do
		menuId[i] = menuIdPrefix .. id
	end
	
	-- Create root menu
	local bc = BuildCategories
	local id = menuId[#menuId] -- #var - get size of table "var"
	-- This line was in example, but it not work. Even if "id" is present, "table.find" return "not true" value :(
	-- if not table.find(bc, "id", id) then
	if not bc[id] then
		-- In source code developers don't use PlaceObj(...), so we too
		bc[#bc + 1] = {
			id = id,
			name = menuDisplayName,
			image = CurrentModPath .. menuIcon,
			-- “on hover” effects; this should probably always be "UI/Icons/bmc_infrastructure_shine.tga" to have the default “on hover” effect
			-- Not needed? Works well without them
			-- highlight = "UI/Icons/bmc_infrastructure_shine.tga",
			-- highlight = "UI/Icons/bmc_dome_buildings_shine.tga",
			-- highlight = "UI/Icons/Buildings/dinner_shine.tga",
			-- highlight or highlight_img param? From different sources, not sure.
		}
		printD("Menu created: " .. id)
	else
		printD("Menu exist: " .. id)
	end
	
	-- Create submenu in each original menu
	local bmc = BuildMenuSubcategories
	for i, id in ipairs(menuId) do
		-- This line was in example, but it not work. Even if "id" is present, "table.find" return "not true" value :(
		-- if not table.find(bmc, "id", id) then
		if not bmc[id] then
			bmc[id] = PlaceObj('BuildMenuSubcategory', {
				id = id,
				build_pos = 0,
				-- The main category inside which the subcategory will appear
				category = origMenuId[i],
				-- Unknown, will set equal to id
				category_name = id,
				display_name = menuDisplayName,
				description = origMenuId[i] .. menuDescrSuffix,
				icon = CurrentModPath .. menuIcon,
				-- Unknown
				group = "Default",
				-- If the player can switch between the buildings of this subcategory
				-- using the “cycle visual variant” buttons (by default [ and ]).
				-- This is useful in cases like the “Depots” and “Storage” subcategory.
				-- It is far simpler to use the “cycle visual variant” keys, instead of
				-- going through the build menu, when placing multiple depots for different resources.
				-- By default it's true.
				-- allow_template_variants = true,
				-- action = function(self, context, button)
					-- print("You Selected Subcategory")
				-- end,
			})
			printD("Menu created: " .. id)
		else
			printD("Menu exist: " .. id)
		end
	end
end




---- MAIN CODE ----

local GUIDE
-- Bad coding, global vars :(
-- World objects
local buildings, cables, tubes

-- File names and paths
local layoutFilePath, layoutFileNameNoPath, layoutFileName, metadataFileName, layoutsFileName, menuIconFileName, layoutIconFileName

local default_build_category = #origMenuId
local default_build_pos = 0
local default_radius = 400

local layoutSettings = {
	build_category = default_build_category,
	build_pos = default_build_pos,
	description = "Layout Description",
	display_name = "Display Name",
	id = "SetIdForLayoutFile",
	radius = default_radius,
}

ToStringTblI = function(tbl)
	local str = ""
	for i, v in ipairs(tbl) do
		str = str .. "\t\t"
		if i < 10 then
			-- Shift line with one digit [1-9] to right
			str = str .. "   "
		end
		str = str .. i .. "\t== " .. v .. "\n"
	end
	return str
end

ToStringTblK = function(tbl)
	local tkeys = {}
	-- populate the table that holds the keys
	for k in pairs(tbl) do table.insert(tkeys, k) end
	-- sort the keys
	table.sort(tkeys)
	
	local str = "{ "
	-- use the keys to retrieve the values in the sorted order
	for _, k in ipairs(tkeys) do
		str = str .. k .. " = " .. tbl[k] .. ", "
	end
	str = str .. "}"
	return str
end

-- Get all objects, then filter for ones within *radius*, returned sorted by dist, or *sort* for name
-- ChoGGi.ComFuncs.OpenInExamineDlg(ReturnAllNearby(1000, "class")) from ChoGGi's Library v8.7
-- Removed "pt" parameter. "radius" in meters. Added parameter "class": only get objects inherited from "class", provided by this parameter
ReturnAllNearby = function(radius, sort, class)
	-- local is faster then global
	local table_sort = table.sort
	local pt = GetTerrainCursor()

	-- "radius" = meters * 100
	radius = radius or 50

	-- get objects inherited from "class" within radius
	-- "guim" = 100 - global var ("meters-to-distance" coefficient)
	local list = MapGet(pt, radius * guim, class)

	-- sort list custom
	if sort then
		table_sort(list, function(a, b)
			return a[sort] < b[sort]
		end)
	else
		-- sort nearest
		table_sort(list, function(a, b)
			return a:GetVisualDist(pt) < b:GetVisualDist(pt)
		end)
	end

	return list
end

-- Return table with objects, that match "entity" parameter
GetObjsByEntity = function(inputTable, entity)
	local string_find = string.find
	local table_insert = table.insert
	local resultTable = {}
	for i, v in ipairs(inputTable) do
		if string_find(inputTable[i]:GetEntity(), entity) then
			table_insert(resultTable, inputTable[i])
		end
	end
	return resultTable
end

-- Trim space http://lua-users.org/wiki/StringTrim
TrimSpace = function(str)
	-- "%s" - space
	-- "."  - any character
	-- "-"  - 'lazy' zero or more times
	-- ".-" - 'lazy' any character
	return (str:gsub("^%s*(.-)%s*$", "%1"))
end

-- Return "false" - params OK, "true" - params WRONG
CheckInputParams = function()
	local MsgWait = ChoGGi.ComFuncs.MsgWait
	local build_category = tonumber(layoutSettings.build_category) or default_build_category
	layoutSettings.build_category = build_category
	if build_category < 1 or build_category > #origMenuId then
		-- Restore default value
		layoutSettings.build_category = default_build_category
		MsgWait(
			'"build_category" - enter number from 1 to ' .. #origMenuId,
			'"build_category" - not allowed value: ' .. build_category
		)
		return true
	end
	
	local build_pos = tonumber(layoutSettings.build_pos) or default_build_pos
	layoutSettings.build_pos = build_pos
	if build_pos < 0 or build_pos > 99 then
		layoutSettings.build_pos = default_build_pos
		MsgWait(
			'"build_pos" - enter number from 1 to 99',
			'"build_pos" - not allowed value: ' .. build_pos
		)
		return true
	end
	
	-- No need to check them, they will be automatically tostring() on string concatenation
	-- layoutSettings.description
	-- layoutSettings.display_name
	
	local id = TrimSpace(tostring(layoutSettings.id))
	layoutSettings.id = id
	if string.find(id, " ") or string.find(id, "\t") then
		-- Do not restore default value, user can edit yourself
		MsgWait(
			'"id" - space or tab not allowed, allowed "CamelCase" or "snake_case" notation',
			'"id" - not allowed value: ' .. id
		)
		return true
	end
	
	local radius = tonumber(layoutSettings.radius) or default_radius
	layoutSettings.radius = radius
	if radius < 1 then
	layoutSettings.radius = default_radius
		MsgWait(
			'"radius" - enter positive number [to infinity and beyond]',
			'"radius" - not allowed value: ' .. radius
		)
		return true
	end
	
	return false
end

SetAllFileNames = function()
	-- metadata.lua
	metadataFileName = CurrentModPath .. "metadata.lua"
	-- Layouts.lua
	layoutsFileName = CurrentModPath .. "Code/Layouts.lua"
	
	-- Code/Layout/layout.lua
	-- Path to file
	layoutFilePath = CurrentModPath .. "Code/Layout/"
	-- File name without path
	layoutFileNameNoPath = origMenuId[layoutSettings.build_category] .. " - " .. string.format("%02d", layoutSettings.build_pos) .. " - " .. layoutSettings.id .. ".lua"
	-- Concatenate path and name
	layoutFileName = layoutFilePath ..layoutFileNameNoPath

	-- Icons
	menuIconFileName = CurrentModPath .. menuIcon
	layoutIconFileName = CurrentModPath .. "UI/Layout/" .. layoutSettings.id .. ".png"
	
	-- Do not overwrite existing lua files
	if DEBUG_LUA then
		layoutsFileName = layoutsFileName .. dbgExt
		layoutFileName = layoutFileName .. dbgExt
		layoutFileNameNoPath = layoutFileNameNoPath .. dbgExt
		metadataFileName = metadataFileName .. dbgExt
	end
end

FileExist = function(fileName)
	if AsyncGetFileAttribute(fileName, "size") == "File Not Found" then
		return false
	else
		return true
	end
end

GetIdFromFileName = function(fileName)
	-- %w - alphanumeric character
	return string.match(fileName, " - ([%w_]+).lua")
end

GetIdList = function()
	local idList = {}
	local layoutListFiles = GetLayoutListFiles()
	for i, fileName in ipairs(layoutListFiles) do
		idList[#idList + 1] = GetIdFromFileName(fileName)
	end
	return idList
end

IsIdPresentInLayoutFolder = function(id)
	local layoutListFiles = GetLayoutListFiles()
	for i, fileName in ipairs(layoutListFiles) do
		if GetIdFromFileName(fileName) == id then
			return true
		end
	end
	return false
end

IsIdUnique = function(layoutFileExist)
	local MsgWait = ChoGGi.ComFuncs.MsgWait
	local id = layoutSettings.id
	-- If "id" is present in "Layout" folder in different file - Not unique - return false
	-- If "id" is present in "Layout" folder in file with same name - Not unique, but we can overwrite it and it will be unique - return true
	if IsIdPresentInLayoutFolder(id) then
		if layoutFileExist then
			return true
		else
			MsgWait(
				'"id" - is already used by one of your layouts, must be unique, change "id" value',
				'"id" - not allowed value: ' .. id
			)
			return false
		end
	-- BuildingTemplates[layoutIdPrefix .. id] check must be last. If it will be sooner, then on ReloadLua() user's layouts will stay in "BuildingTemplates" and this check will return false-positive result.
	elseif BuildingTemplates[layoutIdPrefix .. id] then
		MsgWait(
			'"id" - is already used by game or another mod, must be unique, change "id" value',
			'"id" - not allowed value: ' .. id
		)
		return false
	end
	return true
end

RemoveInDomeBuildings = function(buildings, domes)
	local table_insert = table.insert
	local table_remove = table.remove
	if not TableEmpty(domes) then
		local buildings_indoor = {}
		-- Get all indoor buildings in one table
		for i, dome in ipairs(domes) do
			-- LuaMarsLabels.md.html - each dome has own labels: "Buildings" - all buildings in the "Dome"
			local container = dome.labels.Buildings
			for i = 1, #(container or "") do
				table_insert(buildings_indoor, container[i])
			end
		end
		-- Remove building if it was found in "Domes"
		for i = #buildings, 1, -1 do
			for _, indoorBuilding in ipairs(buildings_indoor) do
				if indoorBuilding == buildings[i] then
					table_remove(buildings, i)
					break
				end
			end
		end
	end
end

RemoveUselessBuildings = function(worldObjs, captureIndoor)
	-- Local is faster
	local table_remove = table.remove
	for i = #worldObjs, 1, -1 do
		local entity         = worldObjs[i]:GetEntity()
		local dome_forbidden = worldObjs[i].dome_forbidden
		local dome_required  = worldObjs[i].dome_required
		local template_name  = worldObjs[i].template_name
		-- "Passages" not supported by in-game "LayoutConstruction", remove them
		-- "Passages" between "Domes" are "Building", but they don't have "template_name"
		if template_name == ""
			-- Remove "Pod" and "Rocket"
			or template_name == "PodLandingSite"
			or template_name == "RocketLandingSite"
			or template_name == "SupplyPod"
			or template_name == "SupplyRocket"
			-- Remove "Tunnel"
			or template_name == "Tunnel"
			-- Remove "dome_forbidden", when we capture indoor buildings
			or (captureIndoor and dome_forbidden)
			-- Remove "dome_required" buildings if we capture outdoor buildings, game will not allow build such layout
			or (not captureIndoor and dome_required) then
			table_remove(worldObjs, i)
		end
	end
end

CaptureObjects = function(captureIndoor)
	local table_insert = table.insert
	local domes = ReturnAllNearby(layoutSettings.radius, nil, "Dome") -- sorted by distance
	if captureIndoor then
		-- Capture buildings inside nearest "Dome"
		buildings = {}
		if not TableEmpty(domes) then
			if DEBUG_EXAMINE then
				OpenExamine(domes)
			end
			-- Get first element from "domes" table == nearest "Dome"
			-- LuaMarsLabels.md.html - each dome has own labels: "Buildings" - all buildings in the "Dome"
			local container = domes[1].labels.Buildings
			-- Copy table by element because we will modify our "buildings" table
			for i = 1, #(container or "") do
				table_insert(buildings, container[i])
			end
		end
		-- No cables and tubes inside "Dome"
		cables = {}
		tubes = {}
	else
		-- Capture buildings outside "Dome"
		buildings = ReturnAllNearby(layoutSettings.radius, "template_name", "Building") -- sorted by "template_name"
		RemoveInDomeBuildings(buildings, domes)
		local supplyGrid = ReturnAllNearby(layoutSettings.radius, nil, "BreakableSupplyGridElement") -- sorted by distance
		cables = GetObjsByEntity(supplyGrid, "Cable")
		tubes  = GetObjsByEntity(supplyGrid, "Tube")
	end
	RemoveUselessBuildings(buildings, captureIndoor)

	local numCapturedObjects = #buildings + #cables + #tubes
	printD("Captured objects: " .. numCapturedObjects .. " = #buildings=" .. #buildings .. " + #cables=" .. #cables .. " + #tubes=" .. #tubes)
	if DEBUG_EXAMINE then
		OpenExamine(buildings)
	end
end

TableEmpty = function(table)
	-- next(table) == nil -- Is Empty Table Check
	if next(table) == nil then
		return true
	else
		return false
	end
end

-- Is all object's tables empty
AllObjectsTablesEmpty = function()
	if TableEmpty(buildings) and TableEmpty(cables) and TableEmpty(tubes) then
		return true
	else
		return false
	end
end

BlacklistEnabled = function()
	if AsyncGetFileAttribute then
		return false
	else
		return true
	end
end

LayoutCapture = function(captureIndoor)
	if BlacklistEnabled() then
		MsgPopupBE()
		return
	end
	-- After this all params in layoutSettings are correct
	if CheckInputParams() then
		return
	end
	
	SetAllFileNames()
	local layoutFileExist = FileExist(layoutFileName)
	
	if not IsIdUnique(layoutFileExist) then
		return
	end
	
	CaptureObjects(captureIndoor)
	if AllObjectsTablesEmpty() then
		MsgPopup("Nothing captured!")
		return
	end
	
	if layoutFileExist then
		-- function ChoGGi.ComFuncs.QuestionBox(text, function, title, ok_text, cancel_text, image, context, parent, template, thread)
		ChoGGi.ComFuncs.QuestionBox(
			'Layout file with this name already exist in "Layout" folder:\n\t"' .. layoutFileNameNoPath .. '"\nPath to "Layout" folder:\n\t"' .. CurrentModPath .. 'Code/Layout"',
			function(answer)
				if answer then
					-- If we reload lua, our old layout object still be present in building's table.
					-- Layout script by default skip creating object if it already exist in game.
					-- Delete our layout object from in-game building's table.
					-- So after reloading lua updated layout become visible.
					-- I commented here, because I do it in LayoutReloadLua()
					-- BuildingTemplates[layoutIdPrefix .. layoutSettings.id] = nil
					WriteToFiles()
				else
					MsgPopup("Capture canceled")
				end
			end,
			"Overwrite file?"
		)
	else
		WriteToFiles()
	end
end

LayoutCaptureOutdoor = function()
	-- Run in real time thread to show MsgPopup() properly!
	-- Else it will be showed, after LayoutCapture() finished. No sense.
	printD(GetDate())
	CreateRealTimeThread(function()
		MsgPopup("Capture outdoor, please wait...")
		LayoutCapture(false)
	end)
end

LayoutCaptureIndoor = function()
	printD(GetDate())
	CreateRealTimeThread(function()
		MsgPopup("Capture indoor, please wait...")
		LayoutCapture(true)
	end)
end

CreateLayoutPath = function()
	printDMsgOrErr(
		AsyncCreatePath(CurrentModPath .. "Code/Layout"),
		'"Code/Layout" Folder created (if not exist before)',
		'"Code/Layout" Folder not created')
	printDMsgOrErr(
		AsyncCreatePath(CurrentModPath .. "UI/Layout"),
		'"UI/Layout" Folder created (if not exist before)',
		'"UI/Layout" Folder not created')
end

SaveLayoutLua = function()
	-- string err AsyncStringToFile(...) - by default overwrites file
	printDMsgOrErr(
		AsyncStringToFile(layoutFileName, BuildLayoutLua()),
		"Layout saved: " .. layoutFileNameNoPath,
		"Layout saving failed: " .. layoutFileNameNoPath)
end

SaveLayoutsLua = function()
	printDMsgOrErr(
		AsyncStringToFile(layoutsFileName, BuildLayoutsLua()),
		'"Layouts.lua" updated',
		'"Layouts.lua" update failed')
end

UpdateLayoutsLua = function(firedByHotKey)
	-- if function fired by hotkey, print date. Variable "firedByHotKey" will be "table" in that case.
	if firedByHotKey then
		printD(GetDate())
	end
	SetAllFileNames()
	SaveLayoutsLua()
	if GlobalError == true then
		GlobalError = false
		MsgPopup("Something went wrong :(")
	else
		MsgPopup('"Layouts.lua" updated')
	end
end

-- SaveMetadataLua = function()
	-- printDMsgOrErr(
		-- AsyncStringToFile(metadataFileName, BuildMetadataLua()),
		-- '"metadata.lua" updated',
		-- '"metadata.lua" update failed')
-- end

WriteToFiles = function()
	-- "items.lua" not needed. Empty is OK. It used by in-game "Mod Editor". ChoGGi says "Mod Editor" may corrupt mods on saving.
	CreateLayoutPath()
	SaveLayoutLua()
	SaveLayoutsLua()
	-- SaveMetadataLua()
	if not FileExist(layoutIconFileName) then
		printDMsgOrErr(
			AsyncCopyFile(menuIconFileName, layoutIconFileName),
			"Icon copied: " .. layoutSettings.id .. ".png",
			"Icon copy failed: " .. layoutSettings.id .. ".png")
	else
		local str = "Icon not copied (already exist): " .. layoutSettings.id .. ".png"
		printD(str)
	end
	if GlobalError == true then
		GlobalError = false
		MsgPopup("Something went wrong :(")
	else
		MsgPopup("Layout saved: " .. layoutFileNameNoPath)
	end
end

local IsDialogWindowOpen_Info = false
local IsDialogWindowOpen_Params = false

SetBuildCategory = function()
	local itemList = {}
	for i, id in ipairs(origMenuId) do
		itemList[#itemList + 1] = {text = id, value = i}
	end

	local function CallBackFunc(choice)
		if not DEBUG then
			IsDialogWindowOpen_Params = false
		end
		if choice.nothing_selected then
			return
		end
		layoutSettings.build_category = choice[1].value
	end

	ChoGGi.ComFuncs.OpenInListChoice{
		callback = CallBackFunc,
		items = itemList,
		title = "Choose Building Menu",
		skip_sort = true,
		height = 350.0,
		width = 150.0,
	}
end

local doneSetParams = true

LayoutSetParams = function()
	-- Exit if user still setting params. Fix double press on hotkey shows WaitInputText() twice
	if not doneSetParams then
		return
	end
	if IsDialogWindowOpen_Params then
		-- If we close "Info" dialog window here, flag "IsDialogWindowOpen_Info" will remain "true".
			-- If we hit hotkey to show "Info" window, it will not appear. So clear this flag.
		IsDialogWindowOpen_Info = false
		IsDialogWindowOpen_Params = false
		-- Close ALL windows
		ChoGGi.ComFuncs.CloseDialogsECM()
	else
		IsDialogWindowOpen_Params = true
		doneSetParams = false
		CreateRealTimeThread(function()
			layoutSettings.id           = WaitInputText('Set "id":', layoutSettings.id)
			layoutSettings.display_name = WaitInputText('Set "Display name":', layoutSettings.display_name)
			layoutSettings.description  = WaitInputText('Set "Description":', layoutSettings.description)
			layoutSettings.build_pos    = WaitInputText('Set "Position in menu":', tostring(layoutSettings.build_pos))
			-- layoutSettings.radius       = WaitInputText('Set "Capture radius":', tostring(layoutSettings.radius))
			if DEBUG then
				ChoGGi.ComFuncs.OpenInObjectEditorDlg(layoutSettings)
			end
			SetBuildCategory()
			doneSetParams = true
		end)
	end
end

LayoutSetRadius = function()
	CreateRealTimeThread(function()
		layoutSettings.radius = WaitInputText('Set "Capture radius":', tostring(layoutSettings.radius))
	end)
end

LayoutShowInfo = function()
	if IsDialogWindowOpen_Info then
		IsDialogWindowOpen_Info = false
		IsDialogWindowOpen_Params = false
		ChoGGi.ComFuncs.CloseDialogsECM()
	else
		IsDialogWindowOpen_Info = true
		OpenExamine(GUIDE)
	end
end

local IsDialogWindowOpen_Delete = false

LayoutDelete = function()
	if BlacklistEnabled() then
		MsgPopupBE()
		return
	end
	
	printD(GetDate())
	if IsDialogWindowOpen_Delete then
		IsDialogWindowOpen_Delete = false
		ChoGGi.ComFuncs.CloseDialogsECM()
		return
	end

	local layoutListFiles = GetLayoutListFiles()
	if TableEmpty(layoutListFiles) then
		MsgPopup("You don't have layouts")
		return
	end
	local itemList = {}
	for i, strFileName in ipairs(layoutListFiles) do
		itemList[#itemList + 1] = {text = strFileName, value = strFileName}
	end

	local function CallBackFunc(choice)
		IsDialogWindowOpen_Delete = false
		if choice.nothing_selected then
			return
		end

		local file = choice[1].value
		
		ChoGGi.ComFuncs.QuestionBox(
			'Delete file: ' .. file .. '"?\nRelative icon will be deleted too!',
			function(answer)
				if answer then
					BuildingTemplates[layoutIdPrefix .. GetIdFromFileName(file)] = nil
					DeleteLayoutFile(file)
					UpdateLayoutsLua()
				end
			end,
			"Delete file?"
		)
	end

	IsDialogWindowOpen_Delete = true
	ChoGGi.ComFuncs.OpenInListChoice{
		callback = CallBackFunc,
		items = itemList,
		title = "Delete layout",
		skip_sort = true,
	}
end

DeleteLayoutFile = function(fileName)
	printDMsgOrErr(
		AsyncFileDelete(CurrentModPath .. "Code/Layout/" .. fileName),
		"Layout deleted: " .. fileName,
		"Layout deleting failed: " .. fileName)
	local iconName = GetIdFromFileName(fileName) .. ".png"
	printDMsgOrErr(
		AsyncFileDelete(CurrentModPath .. "UI/Layout/" .. iconName),
		"Icon deleted: " .. iconName,
		"Icon deleting failed: " .. iconName)
end

BuildLayoutHeadLua = function(layoutDescrSuffix)
	local str = [[
-- File is generated by "]] .. modName .. [["
-- Layout Format v1
function OnMsg.ClassesPostprocess()
	local id = "]] .. layoutSettings.id .. [["
	local idPrefix = "]] .. layoutIdPrefix .. [["
	id = idPrefix .. id
	if BuildingTemplates[id] then
		return
	end

	local build_category = "]] .. menuId[layoutSettings.build_category] .. [["
	local description = "]] .. layoutSettings.description .. [["

	PlaceObj("BuildingTemplate", {
		"Id", id,
		"LayoutList", id,
		"Group", build_category,
		"build_category", build_category,
		"build_pos", ]] .. layoutSettings.build_pos .. [[,
		"display_name", "]] .. layoutSettings.display_name .. [[",
		"display_name_pl", "]] .. layoutSettings.display_name .. [[",
		"description", description .. "]] .. layoutDescrSuffix .. [[",
		"display_icon", "]] .. CurrentModPath .. "UI/Layout/" .. layoutSettings.id .. ".png" .. [[",
		"template_class", "LayoutConstructionBuilding",
		"entity", "InvisibleObject",
		"construction_mode", "layout",
	})

	PlaceObj("LayoutConstruction", {
		group = "Default",
		id = id,

]]

	return str
end

-- Line = Hub-segment-...-segment-Hub
-- Hub = "TubeHub" or "CableHub", segment = "Tube" or "CableTerrain"
-- To build grid of tubes or cables we need build objects in straight line. Game engine do that by clicking mouse
	-- on "begin position" and then clicking on	"end position". Segments built automatically, we not needed them
	-- in result.
-- Cable line begins on hub and ends on hub. If line has smooth turn, we assume	that turn as a hub and build two
	-- lines which connects on turn.
-- Tube line begins on hub but ends on hub (usual case) or segment (when tube line ends for example on "Oxygen Tank").
	-- Tube line does not have smooth turns.
-- Orphan - object with no connections. Segments cannot be orphan, Hub can be orphan.
-- Save orphans then find and save lines. Algorithm of finding lines:
	-- Find first hub, get direction of connection, remove that direction from hub, find position of neighbor in
	-- that direction, find object on that position. If it is not hub, so it is segment, so line is not finished,
	-- delete connection from where we came and to where we go (segment always has two connections	with opposite
	-- directions, so we do not need clear two flags, just assign 0 to "conn" field), find again new neighbor in that
	-- direction, traverse objects till we find hub. If it is hub, delete connection from where we came. We found the
	-- end	of line, save line. Delete objects with no connections. Loop this algorithm	until we cannot find hub.
	-- When loop is stopped, table with objects must be empty.

IsCables = function(type)
	if string.lower(type) == "cables" then
		return true
	else
		return false
	end
end

IsTubes = function(type)
	if string.lower(type) == "tubes" then
		return true
	else
		return false
	end
end

abs = function(x)
	if x < 0 then x = 0 - x end
	return x
end

Hex = function(q, r)
	return { q = q, r = r, }
end

HexDistance = function(a, b)
	return (abs(a.q - b.q) + abs(a.q + a.r - b.q - b.r) + abs(a.r - b.r)) / 2
end

HexEqual = function(a, b)
	return a.q == b.q and a.r == b.r
end

HexObjLineAsStr = function(hexBegin, hexEnd, type, saveOrphan)
	saveOrphan = saveOrphan or false
	local str = ""
	local template
	if IsCables(type) then
		template = "electricity_grid"
	elseif IsTubes(type) then
		template = "life_support_grid"
	else
		printD('HexObjLineAsStr(): wrong "type" argument: ' .. type)
		return ""
	end
	
	-- Do not save objects if begin and end position is equal (example: "Moisture Vaporator")
	-- OR save it if we saving orphans
	if not HexEqual(hexBegin, hexEnd) or saveOrphan then
		-- Tubes and Cables don't have "template_name" parameter, write it explicitly
		str = str .. [[
		PlaceObj("LayoutConstructionEntry", {
			"template", "]] .. template .. [[",
			"pos", point(]] .. hexBegin.q .. [[, ]] .. hexBegin.r .. [[),
			"cur_pos1", point(]] .. hexEnd.q .. [[, ]] .. hexEnd.r .. [[),
		}),]] .. "\n\n"
		local distance = HexDistance(hexBegin, hexEnd)
		printD(type .. ": Line=" .. hexBegin.q .. ":" .. hexBegin.r .. "|" .. hexEnd.q .. ":" .. hexEnd.r
			.. " Dist=" .. distance .. " Len=" .. (distance + 1))
	end
	return str
end

IsHub = function(worldObj)
	local entity = worldObj:GetEntity()
	return	entity == "CableHub"       or entity == "TubeHub"       or
			entity == "CableSwitch"    or entity == "TubeSwitch"    or
			entity == "CableSoftLeft"  or entity == "CableHardLeft" or
			entity == "CableSoftRight" or entity == "CableHardRight"
end

-- Make our objects - simpler version of in-game objects
HexObjs = function(worldObjs, baseHex)
	local hexObjs ={}
	for id, obj in pairs(worldObjs) do
		local q, r = WorldToHex(obj)
		local hex = Hex(q - baseHex.q, r - baseHex.r)
		local entity = obj:GetEntity()
		local hub = false
		
		if IsHub(obj) then
			hub = true
		end
		
		hexObjs[#hexObjs + 1] = {
			-- "conn" is a variable with 6 flags (bits from 0 to 5) representing
			--	direction of connection (counts from 1 to 6) beginning from "left", continue clockwise:
			--   0 bit - connection from left side of hex
			-- 1st bit - up-left
			-- 2nd bit - up-right
			-- 3rd bit - right
			-- 4th bit - bottom-right
			-- 5th bit - bottom-left
			-- 16256 - initial value, if no connection; subtract it and we will have only flags we need
			conn = obj.conn - 16256,
			entity = entity,
			hex = hex,
			hub = hub,
			grid = 0, -- grid to which belongs this object
		}
	end
	return hexObjs
end

HexNeighbor = function(hex, direction)
	if direction < 1 or direction > 6 then
		printD('HexNeighbor(): wrong "direction" parameter: ' .. direction)
	end
	local axialDirections = {
		Hex( 1,  0),
		Hex( 0,  1),
		Hex(-1,  1),
		Hex(-1,  0),
		Hex( 0, -1),
		Hex( 1, -1),
	}
	local dir = axialDirections[direction]
	return Hex(hex.q + dir.q, hex.r + dir.r)
end

CheckBitConn = function(hexObj, direction)
	-- Direction numeration begins from one. Bit numeration begins from zero.
	local bitNum = direction - 1
	if hexObj.conn & (1 << bitNum) ~= 0 then
		return true
	else
		return false
	end
end

ClearBitConn = function(hexObj, direction)
	-- Direction numeration begins from one. Bit numeration begins from zero.
	local bitNum = direction - 1
	-- "~" - invert operator
	hexObj.conn = hexObj.conn & ~(1 << bitNum)
end

AxialDirection = function(hexObj)
	local direction = 0
	local noMoreConnection = false
	for i = 1, 6, 1 do
		if CheckBitConn(hexObj, i) then
			ClearBitConn(hexObj, i)
			direction = i
			if hexObj.conn == 0 then
				noMoreConnection = true
			end
			break
		end
	end
	return direction, noMoreConnection
end

GetOppositeDirection = function(direction)
	-- Hex grid have 6 directions, so plus 3 gives opposite direction
	-- Limit result to 6 by "%" operator (module)
	-- Subtract 1 from direction to make it zero-based, because "%" operator is zero-based
	-- Add 1 to result to make numeration starts from one.
	return ((direction - 1) + 3) % 6 + 1
end

BuildOrphans = function(hexObjs, type, strTbl)
	local table_remove = table.remove
	local orphanNum = 0
	for i = #hexObjs, 1, -1 do
		local hexObj = hexObjs[i]
		if hexObj.conn == 0 then
			orphanNum = orphanNum + 1
			strTbl[#strTbl + 1] = HexObjLineAsStr(hexObj.hex, hexObj.hex, type, true)
			table_remove(hexObjs, i)
		end
	end
	return orphanNum
end

FindHub = function(hexObjs)
	for i, hexObj in ipairs(hexObjs) do
		if hexObj.hub then
			return hexObj
		end
	end
	return nil
end

FindObjByHex = function(hexObjs, hex)
	for i, hexObj in ipairs(hexObjs) do
		if HexEqual(hexObj.hex, hex) then
			return hexObj
		end
	end
	return nil
end

FindEndObj = function(hexObjs, hexObjBegin, direction)
	local hexObjPrev = hexObjBegin
	while (true) do
		local hexNext = HexNeighbor(hexObjPrev.hex, direction)
		local hexObjNext = FindObjByHex(hexObjs, hexNext)
		-- Tube line can end not on "TubeHub" (example: "Oxygen Tank")
		if not hexObjNext then
			return hexObjPrev
		end
		if hexObjNext.hub then
			-- Clear direction, from which we came
			ClearBitConn(hexObjNext, GetOppositeDirection(direction))
			return hexObjNext
		else
			-- "Segments" between "Hubs" have only two directions: one from which
			--	we came and second - where we continue go trying find hub or end of line
			hexObjNext.conn = 0
		end
		hexObjPrev = hexObjNext
	end
end

RemoveNoConn = function(hexObjs)
	local table_remove = table.remove
	for i = #hexObjs, 1, -1 do
		if hexObjs[i].conn == 0 then
			table_remove(hexObjs, i)
		end
	end
end

BuildLines = function(hexObjs, type, strTbl)
	local lineNum = 0
	while(true) do
		local hexObjBegin = FindHub(hexObjs)
		if not hexObjBegin then
			break
		end
		
		local noConn = false
		while (not noConn) do
			local direction
			direction, noConn = AxialDirection(hexObjBegin)
			local hexObjEnd = FindEndObj(hexObjs, hexObjBegin, direction)
			local str = HexObjLineAsStr(hexObjBegin.hex, hexObjEnd.hex, type)
			if str ~= "" then
				strTbl[#strTbl + 1] = str
				lineNum = lineNum + 1
			end
		end
		
		RemoveNoConn(hexObjs)
	end
	return lineNum
end

IsAllNeighbors = function(hexObjs, hexObj)
	-- AxialDirection() will change "conn" value, save it
	local conn = hexObj.conn
	local allNeighborsExist = true
	local allNeighborsNotExist = true
	local noConn = false
	while (not noConn) do
		local direction
		direction, noConn = AxialDirection(hexObj)
		local hexNeighbor = HexNeighbor(hexObj.hex, direction)
		local hexObjNeighbor = FindObjByHex(hexObjs, hexNeighbor)
		if hexObjNeighbor then
			allNeighborsNotExist = false
		else
			allNeighborsExist = false
		end
	end
	-- Restore previous value
	hexObj.conn = conn
	return allNeighborsExist, allNeighborsNotExist
end

SetAdditionalOrphans = function(hexObjs)
	for i, hexObj in ipairs(hexObjs) do
		if hexObj.conn ~= 0 then
			-- If "conn" parameter says object has neighbors, but actually all of them are absent -> this is orphan
			local allNeighborsExist, allNeighborsNotExist = IsAllNeighbors(hexObjs, hexObj)
			if allNeighborsNotExist then
				-- Orphan must don't have connections
				hexObj.conn = 0
			end
		end
	end
end

SetHubOnLineEnding = function(hexObjs)
	for i, hexObj in ipairs(hexObjs) do
		-- If "conn" parameter says object has neighbors, but actually at least one is absent -> this is end of line
		local allNeighborsExist, allNeighborsNotExist = IsAllNeighbors(hexObjs, hexObj)
		if not allNeighborsExist then
			hexObj.hub = true
		end
	end
end

BuildGrid = function(worldObjs, baseHex, type)
	local strTbl = {"",}
	if not TableEmpty(worldObjs) then
		local comment
		if IsCables(type) then
			comment = "\t\t-- Cables\n"
		elseif IsTubes(type) then
			comment = "\t\t-- Tubes\n"
		else
			printD('BuildGrid(): wrong "type" argument: ' .. type)
			return ""
		end
		table.insert(strTbl, comment)

		-- After successful finding or saving, objects removed from "hexObjs"
		-- At the end, hexObjs must be empty
		local hexObjs = HexObjs(worldObjs, baseHex)
		-- Set additional orphans
		SetAdditionalOrphans(hexObjs)
		local orphanNum = BuildOrphans(hexObjs, type, strTbl)
		-- Tube line without hubs at both ends (example straight line between two domes)
		-- OR if part of straight line of grid falls within the capture radius it will be captured without any hubs
		SetHubOnLineEnding(hexObjs)
		local lineNum = BuildLines(hexObjs, type, strTbl)

		printD(type .. ": GridOrphan = " .. orphanNum .. " GridLine = " .. lineNum)
		if not TableEmpty(hexObjs) then
			MsgPopup(type .. " ERROR: table not empty, some objects not saved")
		end
	end
	return table.concat(strTbl)
end

-- Get position of "base object". Position offset of all other objects will be calculated relative to it.
GetBaseObjectPosition = function()
	local baseObj
	-- ~= is equivalent of !=
	-- Check if table is not empty
	if not TableEmpty(buildings) then
		baseObj = buildings[1]
	elseif not TableEmpty(cables) then
		baseObj = cables[1]
	elseif not TableEmpty(tubes) then
		baseObj = tubes[1]
	end

	local q, r = WorldToHex(baseObj)

	printD("Base Object: " .. baseObj:GetEntity() .. " q:r=" .. q .. ":" .. r)
	if DEBUG_EXAMINE then
		OpenExamine(baseObj)
	end
	
	return Hex(q, r)
end

BuildBuildings = function(worldObjs, baseHex)
	local str = ""
	if not TableEmpty(worldObjs) then
		str = str .. "\t\t-- Buildings\n"
		for i, obj in ipairs(worldObjs) do
			local q, r = WorldToHex(obj)
			-- Calculate offset from "base object"
			q = q - baseHex.q
			r = r - baseHex.r
			str = str .. [[
		PlaceObj("LayoutConstructionEntry", {
			"template", "]] .. obj.template_name .. [[",
			"pos", point(]] .. q .. [[, ]] .. r .. [[),
			"dir", ]] .. HexAngleToDirection(obj) .. [[,
			"entity", "]] .. obj:GetEntity() .. [[",]] .. "\n"
			-- "instant" parameter not needed at all, game build "Storages" instantly in any case
			-- if string.find(obj.template_name, "Storage") then
				-- str = str .. [[
			-- "instant", true,]] .. "\n"
			-- end
			str = str .. [[
		}),]] .. "\n\n"
		end
	end
	return str
end

BuildCables = function(worldObjs, baseHex)
	local str = ""
	-- Don't have "template_name" parameter, write it explicitly
	-- Brute force variant, ugly result in game
	if not TableEmpty(worldObjs) then
		str = str .. "\t\t-- Cables\n"
		for i, obj in ipairs(worldObjs) do
			local q, r = WorldToHex(obj)
			q = q - baseHex.q
			r = r - baseHex.r
			str = str .. [[
		PlaceObj("LayoutConstructionEntry", {
			"template", "electricity_grid",
			"pos", point(]] .. q .. [[, ]] .. r .. [[),
			"cur_pos1", point(]] .. q .. [[, ]] .. r .. [[),
		}),]] .. "\n\n"
		end
	end
	return str
end

-- Save tube objects as lua objects, that can be used in "ZeroBrane Studio" (LUA IDE) for debugging
BuildTubesTesting = function(worldObjs, baseHex)
	local str = ""
	-- Brute force variant
	if not TableEmpty(worldObjs) then
		str = str .. "\t\t-- Tubes\n"
		for i, obj in ipairs(worldObjs) do
			local q, r = WorldToHex(obj)
			q = q - baseHex.q
			r = r - baseHex.r
			local hub = false
			local entity = obj:GetEntity()
			if IsHub(obj) then
				hub = true
			end
			str = str .. [[{ conn = ]] .. obj.conn - 16256 .. [[, hex = Hex(]] .. q .. [[,]] .. r .. [[), hub = ]] .. tostring(hub) .. [[, entity = "]] .. entity .. [["},]] .. "\n"
		end
	end
	return str
end

GetResourcesTable = function()
	local tbl = {
		blackCube = 0,
		concrete = 0,
		electronics = 0,
		machineparts = 0,
		metals = 0,
		polymers = 0,
		preciousmetals = 0,
		wasteRock = 0,
	}
	return tbl
end

GetSupplyTable = function()
	local tbl = {
		air = 0,
		electricity = 0,
		water = 0,
	}
	return tbl
end

DataPresent = function(tbl)
	local sum = 0
	for k, v in pairs(tbl) do
		sum = sum + v
	end
	if sum ~= 0 then
		return true
	else
		return false
	end
end

CalculateBuildingsCost = function(cost)
	for i, obj in ipairs(buildings) do
		cost.blackCube      = cost.blackCube      + (obj:GetProperty("base_construction_cost_BlackCube")      or 0)
		cost.concrete       = cost.concrete       + (obj:GetProperty("base_construction_cost_Concrete")       or 0)
		cost.electronics    = cost.electronics    + (obj:GetProperty("base_construction_cost_Electronics")    or 0)
		cost.machineparts   = cost.machineparts   + (obj:GetProperty("base_construction_cost_MachineParts")   or 0)
		cost.metals         = cost.metals         + (obj:GetProperty("base_construction_cost_Metals")         or 0)
		cost.polymers       = cost.polymers       + (obj:GetProperty("base_construction_cost_Polymers")       or 0)
		cost.preciousmetals = cost.preciousmetals + (obj:GetProperty("base_construction_cost_PreciousMetals") or 0)
		cost.wasteRock      = cost.wasteRock      + (obj:GetProperty("base_construction_cost_WasteRock")      or 0)
	end
end

CalculateGridCost = function(cost)
	local function CalculateOrphanCost(hexObjs)
		local table_remove = table.remove
		local metals = 0
		for i = #hexObjs, 1, -1 do
			if hexObjs[i].conn == 0 then
				metals = metals + 1
				table_remove(hexObjs, i)
			end
		end
		return metals
	end

	local function MarkUniqueGrid(hexObjs)
		local function FindObjNoGrid(hexObjs)
			for i, hexObj in ipairs(hexObjs) do
				if hexObj.grid == 0 then
					return hexObj
				end
			end
			return nil
		end

		local function MarkNeighbors(hexObjs, hexObj)
			local noConn = false
			-- Last obj in cable/tube line does non have connections and not marked neighbors
			if hexObj.conn == 0 then
				noConn = true
			end
			while (not noConn) do
				local direction
				direction, noConn = AxialDirection(hexObj)
				local hexNeighbor = HexNeighbor(hexObj.hex, direction)
				local hexObjNeighbor = FindObjByHex(hexObjs, hexNeighbor)
				-- Tube line can end not on "TubeHub" (example: "Oxygen Tank")
				if hexObjNeighbor then
					if hexObjNeighbor.grid > 0 and hexObjNeighbor.grid ~= hexObj.grid then
						printD("MarkNeighbors() - logic error. Get neighbor object, that belongs to different grid.")
					elseif hexObjNeighbor.grid == hexObj.grid then
						-- Do nothing, neighbor was marked from another recursion call
					else
						-- Clear direction, from which we came
						ClearBitConn(hexObjNeighbor, GetOppositeDirection(direction))
						hexObjNeighbor.grid = hexObj.grid
						MarkNeighbors(hexObjs, hexObjNeighbor)
					end
				end
			end
		end

		local gridCount = 0
		while(true) do
			gridCount = gridCount + 1
			local hexObj = FindObjNoGrid(hexObjs)
			if not hexObj then
				break
			end
			hexObj.grid = gridCount
			MarkNeighbors(hexObjs, hexObj)
		end
		return gridCount
	end

	local function GridLen(hexObjs)
		local gridLen = {}
		for i, hexObj in ipairs(hexObjs) do
			gridLen[hexObj.grid] = (gridLen[hexObj.grid] or 0) + 1
		end
		return gridLen
	end

	local function CalculateUniqueGridCost(gridLen)
		-- Grid cost: 1 metal for each 5 hexes-long section
		local metals = 0
		for i, len in ipairs(gridLen) do
			printD("Hex sections in Grid[" .. i .. "]=" .. len)
			-- "//" is floor (integer) division
			metals = metals + len // 5
			if len % 5 > 0 then
				-- Less than 5 hexes-long section cost 1 metal too
				metals = metals + 1
			end
		end
		return metals
	end

	-- "w" = World, "h" = Hex
	local baseHex = GetBaseObjectPosition()
	for i, wGrid in ipairs({cables, tubes}) do
		local metals = 0
		local hGrid = HexObjs(wGrid, baseHex)
		metals = metals + CalculateOrphanCost(hGrid) -- removes orphans from "hGrid"
		local gridNum = MarkUniqueGrid(hGrid)
		local gridLen = GridLen(hGrid)
		metals = metals + CalculateUniqueGridCost(gridLen)
		cost.metals = cost.metals + metals * const.ResourceScale
	end
end

FormatResourceStr = function(resource)
	-- I suppose order like in game
	local str = ""
	if resource.concrete       > 0 then str = str .. "<concrete("        .. resource.concrete       .. ")> " end
	if resource.metals         > 0 then str = str .. "<metals("          .. resource.metals         .. ")> " end
	if resource.polymers       > 0 then str = str .. "<polymers("        .. resource.polymers       .. ")> " end
	if resource.electronics    > 0 then str = str .. "<electronics("     .. resource.electronics    .. ")> " end
	if resource.machineparts   > 0 then str = str .. "<machineparts("    .. resource.machineparts   .. ")> " end
	if resource.preciousmetals > 0 then str = str .. "<preciousmetals("  .. resource.preciousmetals .. ")> " end
	if resource.wasteRock      > 0 then str = str .. "<wasterock("       .. resource.wasteRock      .. ")> " end
	if resource.blackCube      > 0 then str = str .. "<mysteryresource(" .. resource.blackCube      .. ")> " end
	return str
end

FormatSupplyStr = function(supply)
	local str = ""
	if supply.electricity > 0 then str = str .. "<power(" .. supply.electricity .. ")> " end
	if supply.air         > 0 then str = str .. "<air("   .. supply.air         .. ")> " end
	if supply.water       > 0 then str = str .. "<water(" .. supply.water       .. ")> " end
	return str
end

CalculateLayoutCost = function()
	local cost = GetResourcesTable()
	CalculateBuildingsCost(cost)
	CalculateGridCost(cost)
	printD("Cost:")
	printD(cost)
	if not DataPresent(cost) then
		return ""
	else
		return "<newline><newline>Cost: " .. FormatResourceStr(cost)
	end
end

ConsumptionVsProduction = function(c, p)
	for key, val in pairs(c) do
		if c[key] > p[key] then
			c[key] = c[key] - p[key]
			p[key] = 0
		else
			p[key] = p[key] - c[key]
			c[key] = 0
		end
	end
end

CalculateLayoutConsumptionProduction = function()
	local consumption = GetSupplyTable()
	local production  = GetSupplyTable()
	for i, obj in ipairs(buildings) do
		consumption.air         = consumption.air         + (obj:GetProperty("air_consumption")         or 0)
		consumption.electricity = consumption.electricity + (obj:GetProperty("electricity_consumption") or 0)
		consumption.water       = consumption.water       + (obj:GetProperty("water_consumption")       or 0)
		production.air          = production.air          + (obj:GetProperty("air_production")          or 0)
		production.electricity  = production.electricity  + (obj:GetProperty("electricity_production")  or 0)
		production.water        = production.water        + (obj:GetProperty("water_production")        or 0)
	end
	printD("Consumption:")
	printD(consumption)
	printD("Production:")
	printD(production)
	ConsumptionVsProduction(consumption, production)
	printD("ConsumptionVsProduction calc result:")
	printD("Consumption*:")
	printD(consumption)
	printD("Production*:")
	printD(production)
	local str = ""
	if DataPresent(consumption) or DataPresent(production) then
		str = str .. "<newline><newline>"
	end
	if DataPresent(consumption) then
		str = str .. "Consumption: " .. FormatSupplyStr(consumption)
	end
	if DataPresent(production) then
		if DataPresent(consumption) then
			str = str .. "<newline>"
		end
		str = str .. "Production: " .. FormatSupplyStr(production)
	end
	return str
end

CalculateLayoutMaintenance = function()
	local maintenance = GetResourcesTable()
	for i, obj in ipairs(buildings) do
		local amount = obj:GetProperty("maintenance_resource_amount") or 0
		local type   = obj:GetProperty("maintenance_resource_type")   or "no_maintenance"
		type = string.lower(type)
		if type == "no_maintenance" then
			-- do nothing
		elseif not maintenance[type] then
			print("No such resource: " .. type)
		else
			maintenance[type] = maintenance[type] + amount
		end
	end
	printD("Maintenance:")
	printD(maintenance)
	if not DataPresent(maintenance) then
		return ""
	else
		return "Maintenance: " .. FormatResourceStr(maintenance)
	end
end

BuildLayoutBodyLua = function()
	local str = ""
	-- Base point (zero point)
	local baseHex = GetBaseObjectPosition()
	str = str .. BuildBuildings(buildings, baseHex)
	str = str .. BuildGrid(cables, baseHex, "Cables")
	str = str .. BuildGrid(tubes, baseHex, "Tubes")
	-- str = str .. BuildTubesTesting(tubes, baseHex)
	return str
end

BuildLayoutTailLua = function()
	local str = [[
	})
end
]]
	return str .. "\n\n\n\n"
end

BuildLayoutLua = function()
	-- Reverse order is important, BuildLayoutBodyLua() prepares data for Calculate*() functions!
	local tail = BuildLayoutTailLua()
	local body = BuildLayoutBodyLua()
	local layoutDescrSuffix = ""
	local cost        = CalculateLayoutCost()
	local consumption = CalculateLayoutConsumptionProduction()
	local maintenance = CalculateLayoutMaintenance()
	layoutDescrSuffix = layoutDescrSuffix .. cost
	layoutDescrSuffix = layoutDescrSuffix .. consumption
	if maintenance ~= "" then
		if consumption ~= "" then
			layoutDescrSuffix = layoutDescrSuffix .. "<newline>"
		else
			layoutDescrSuffix = layoutDescrSuffix .. "<newline><newline>"
		end
		layoutDescrSuffix = layoutDescrSuffix .. maintenance
	end
	local head = BuildLayoutHeadLua(layoutDescrSuffix)
	return head .. body .. tail
end

-- Return list of files in "Code/Layout" folder
GetLayoutListFiles = function()
	local err, layoutListFiles = AsyncListFiles(CurrentModPath .. "Code/Layout", "*.lua" .. dbgExt, "relative, sorted")
	printDMsgOrErr(
		err,
		nil,
		"Error AsyncListFiles():")
	return layoutListFiles
end

-- Not used anymore, only for history
-- BuildMetadataLua = function()
	-- local layoutListFiles = GetLayoutListFiles()
	-- local strLayoutFiles = ""
	-- for i, strFileName in ipairs(layoutListFiles) do
		-- strLayoutFiles = strLayoutFiles .. '\t\t"' .. 'Code/Layout/' .. strFileName .. '",\n'
	-- end
	-- local str = [[
-- return PlaceObj('ModDef', {
	-- "dependencies", {
		-- PlaceObj("ModDependency", {
			-- "id", "ChoGGi_Library",
			-- "title", "ChoGGi's Library",
			-- "version_major", 8,
			-- "version_minor", 6,
		-- }),
		-- PlaceObj("ModDependency", {
			-- "id", "ChoGGi_CheatMenu",
			-- "title", "Expanded Cheat Menu",
			-- "version_major", 15,
			-- "version_minor", 6,
		-- }),
	-- },
	-- -- If you change mod name: change "modName" in .\Code\Script.lua
	-- 'title', "Layout Capture Mod",
	-- 'description', "Capture and save building's layout.",
	-- 'image', "Preview.png",
	-- 'last_changes', "Initial release.",
	-- -- If you change mod id: change "modId" in .\Code\Script.lua
	-- 'id', "Kyklish_Layout_Capture_Mod",
	-- 'steam_id', "9876543210",
	-- 'pops_desktop_uuid', "2985b508-0ba0-4f20-8ff3-8bf242be35e3",
	-- 'pops_any_uuid', "bbf577bf-dee0-4346-bad5-1037f6a827e7",
	-- 'author', "Kyklish",
	-- 'version_major', 1,
	-- 'version_minor', 0,
	-- 'version', 1,
	-- 'lua_revision', 233360,
	-- 'saved_with_revision', 249143,
	-- 'code', {
		-- -- Main Code --
		-- "Code/Script.lua",
		-- -- Captured Layouts --
		-- "Code/Layouts.lua",
	-- },
	-- 'saved', 1604768099,
	-- 'TagTools', true,
	-- 'TagOther', true,
-- })
-- ]]
	-- return str
-- end

BuildLayoutsLua = function()
	local layoutListFiles = GetLayoutListFiles()
	local str = ""
	for i, strFileName in ipairs(layoutListFiles) do
		local err, data = AsyncFileToString(CurrentModPath .. "Code/Layout/" .. strFileName)
		printDMsgOrErr(
			err,
			nil,
			"Error AsyncFileToString():")
		str = str .. data
	end
	return str
end




---- Photo Mode ----

PhotoMode = function()
	ChoGGi.ComFuncs.QuestionBox(
			"No way back! To restore view, you must reload game.",
			function(answer)
				if answer then
					MsgPopup("PhotoMode")
					-- Pause game
					UICity:SetGameSpeed(0)
					UISpeedState = "pause"
					-- Set bright light
					SetLightmodelOverride(1)
					SetLightmodel(1, "ArtPreview")
					-- Set green color for terrain to make screenshot
					TerrainTextureChange({ text = "Prefab_Green", value = 27, })
				end
			end,
			'Enable "Photo Mode"?'
		)
end

-- Copy-Paste from ChoGGi.MenuFuncs.TerrainTextureChange()
TerrainTextureChange = function(choice)
	local function RestoreSkins(label, temp_skin, idx)
		for i = 1, #(label or "") do
			local o = label[i]
			-- If i don't set waste skins to the ground texture then it won't be the right texture for GetCurrentSkin
			-- got me
			if temp_skin then
				o.orig_terrain1 = idx
				o.orig_terrain2 = nil
				o:ChangeSkin("Terrain" .. temp_skin)
			end
			o:ChangeSkin(o:GetCurrentSkin())
		end
	end

	local GridOpFree = GridOpFree
	local AsyncSetTypeGrid = AsyncSetTypeGrid
	local MulDivRound = MulDivRound
	local sqrt = sqrt

	local NoisePreset = DataInstances.NoisePreset
	local guim = guim

	local TerrainTextures = TerrainTextures

	local function CallBackFunc(choice)
		if TerrainTextures[choice.value] then
			SuspendPassEdits("ChoGGi.MenuFuncs.TerrainTextureChange")
			terrain.SetTerrainType{type = choice.value}

			-- add back dome grass
			RestoreSkins(UICity.labels.Dome)
			-- restore waste piles
			RestoreSkins(UICity.labels.WasteRockDumpSite, choice.text, choice.value)

			-- re-build concrete marker textures
			local texture_idx1 = table.find(TerrainTextures, "name", "Regolith") + 1
			local texture_idx2 = table.find(TerrainTextures, "name", "Regolith_02") + 1

			local deposits = UICity.labels.TerrainDeposit or ""
			for i = 1, #deposits do
				local d = deposits[i]
				if IsValid(d) then
					local pattern = NoisePreset.ConcreteForm:GetNoise(128, Random())
					pattern:land_i(NoisePreset.ConcreteNoise:GetNoise(128, Random()))
					-- any over 1000 get the more noticeable texture
					if d.max_amount > 1000000 then
						pattern:mul_i(texture_idx2, 1)
					else
						pattern:mul_i(texture_idx1, 1)
					end
					-- blend in with surrounding ground
					pattern:sub_i(1, 1)
					-- ?
					pattern = GridOpFree(pattern, "repack", 8)
					-- paint deposit
					AsyncSetTypeGrid{
						type_grid = pattern,
						pos = d:GetPos(),
						scale = sqrt(MulDivRound(10000, d.max_amount / guim, d.radius_max)),
						centered = true,
						invalid_type = -1,
					}
				end
			end -- for

			ResumePassEdits("ChoGGi.MenuFuncs.TerrainTextureChange")
		end -- If TerrainTextures

	end -- CallBackFunc

	CallBackFunc(choice)
	printD("Terrain texture changed")
end




---- OnMsg ----

-- Use this message to perform post-built actions on the final classes
function OnMsg.ClassesBuilt()
	CreateShortcuts() -- in other places not work :(
	CreateMenus()
end

-- -- New_Game + Load_Save
-- function OnMsg.ModsReloaded()
-- end

-- -- Load_Save
-- function OnMsg.LoadGame()
-- end

-- -- New_Game
-- function OnMsg.CityStart()
-- end




---- GUIDE ----

GUIDE = '\n' .. [[
SHORTCUTS:
	Layout Capture Outdoor = []] .. ShortcutCaptureOutdoor .. [[]
	Layout Capture Indoor = []] .. ShortcutCaptureIndoor .. [[]
	Layout Set Params = []] .. ShortcutSetParams .. [[]
	Layout Show Info = []] .. ShortcutShowInfo .. [[]
	Layout Update "Layouts.lua" = []] .. ShortcutUpdateLayoutsLua .. [[]
	Layout Reload Lua = []] .. ShortcutReloadLua .. [[]
	Layout Photo Mode = []] .. ShortcutPhotoMode .. [[]
	Layout Set Radius = []] .. ShortcutSetRadius .. [[]
	Layout Delete = []] .. ShortcutDeleteLayout .. [[]
INSTALL:
	ChoGGi's Mods: https://github.com/ChoGGi/SurvivingMars_CheatMods/
	[REQUIRED] ChoGGi's "Startup HelperMod" to bypass blacklist (we need access to AsyncIO functions to create lua files).
		Install mod, then copy "AppData\BinAssets" from "]] .. modName .. [[" folder to "%AppData%\Surviving Mars\BinAssets".
	[REQUIRED] ChoGGi's "Expanded Cheat Menu" [F2] -> "Cheats" -> "Toggle Unlock All Buildings" -> Double click "Unlock".
	[REQUIRED] "ChoGGi's Library"
	[Optional] ChoGGi's "Fix Layout Construction Tech Lock" mod if you want build buildings, that is locked by tech.
BUILD:
	Place your buildings (recommend on empty map OR tune capture "radius" to capture only needed buildings).
	"Passage", "Pipe Valve", "Power Switch" not supported. "Pod", "Rocket" and "Tunnel" supported, but mod skips them.
	Mod will skip "dome_required" buildings if you capture all buildings, game will not allow to build such layout.
	Press [Alt-B] to complete constructions.
SET PARAMS:
	Place your mouse cursor in the center of building's layout.
	Press [Ctrl-M] and measure radius of building's layout. Press []] .. ShortcutSetRadius .. [[] to set capture radius.
	Press []] .. ShortcutSetParams .. [[] and set layout's params.
	In "Choose Building Menu" window choose building menu by double click, or ignore it (previous selected menu category will be used).
	In debug mode additional window "Edit Object" will appear, "building_category" value will not be updated after double click,
		but will be saved anyway!
	Set parameters in "Edit Object" window:
		"build_category" (allowed number from 1 to ]] .. #origMenuId .. [[) in which menu captured layout will be placed.
		"build_pos" (number from 0 to 99, can be duplicated) position in build menu.
		"description", "display_name" - as you like.
			Example: "Text.<newline>Text on new line.\nAnother line."
			Example: "<red>Red text</red>, <em>yellow text</em>."
			Example: "<left>Left alignment.<right>Right alignment.<center>Center alignment."
			Example: "<image UI/Common/rollover_line.tga 2000>"
		"id" (must be unique, allowed "CamelCase" or "snake_case" notation, allowed characters [_a-zA-Z0-9]) internal script parameter,
			additionally will be used as part of file name of layout's lua script and as file name for layout's icon.
		"radius" (positive number [to infinity and beyond]) capture radius in meters.
	Press []] .. ShortcutSetParams .. [[] again to close all dialog windows.
CAPTURE:
	Press []] .. ShortcutCaptureOutdoor .. [[] to capture outdoor buildings (be aware to capture buildings required be near dome or resource deposit).
	Press []] .. ShortcutCaptureIndoor .. [[] to capture indoor buildings in nearest dome.
APPLY:
	To take changes in effect restart game (reliable). Press [Ctrl-Alt-R] then [Enter].
	Or reload lua (not responsible for potential mess if you want continue play). Press []] .. ShortcutReloadLua .. [[].
PHOTO MODE [Optional]:
	To reset changes made below, load savegame.
	Press []] .. ShortcutPhotoMode .. [[], it will change terrain texture to green, brighter light, set game on pause.
	Press [Ctrl-Alt-I] to hide UI, [Ctrl-Alt-U] to toggle signs.
	Make screenshot [PrintScreen]. It will be saved in "%AppData%\Surviving Mars"
	Make some fancy icon and replace the one, located in "]] .. CurrentModPath .. 'UI/%id%.png"\n' .. [[
	Icon template: "Surviving Mars\ModTools\Samples\Mods\User Interface Elements\UI\Buildings Icons.png"
I WANT DELETE LAYOUT:
	Press []] .. ShortcutDeleteLayout .. [[] and double click file to delete. Press hotkey again to close window if you change mind.
	Or delete layout file in "]] .. CurrentModPath .. "Code/Layout" .. [[" folder.
	Delete icon file in "]] .. CurrentModPath .. "UI/Layout" .. [[" folder.
	Press []] .. ShortcutUpdateLayoutsLua .. [[] to update "Layouts.lua" or capture new layout.
I WANT ADD LAYOUT:
	The same as "delete", but add files, then update "Layouts.lua".
I WANT SHARE LAYOUT:
	Share layout file in "]] .. CurrentModPath .. "Code/Layout" .. [[" folder.
	Share icon file in "]] .. CurrentModPath .. "UI/Layout" .. [[" folder.
DEBUG:
	"build_category" (allowed value is number from 1 to ]] .. #origMenuId .. [[):]] .. '\n' .. ToStringTblI(origMenuId)




---- StdDialogs.lua ----

-- CommonLua\UI\StdDialogs.lua
-- local text
-- function WaitInputText(caption, text)
-- text = WaitInputText('Set "id":', "ChangeMe")
-- print(text)

-- function WaitListChoice(items, caption, parent, start_selection, max_lines_to_show)
-- text = WaitListChoice({"item1","item2","item3","item4"}, "caption")
-- print(text)

-- function WaitMessage(parent, caption, text, ok_text, obj) - Wait variant of CreateMessageBox()
-- WaitMessage(nil, "caption", "text")

-- function CreateMessageBox(caption, text, ok_text, parent, obj)
-- CreateMessageBox("caption", "text")

-- function WaitQuestion(parent, caption, text, ok_text, cancel_text, obj)
-- text = WaitQuestion(nil, "caption", "text")
-- print(text)

-- function CloseAllMessagesAndQuestions()
-- function AreMessageBoxesOpen()




-- DELETE THIS IF DEVELOPERS FIX THIS BUGS
-- Fix bugs in source lua: .\Lua\LayoutConstruction.lua
-- Change "electricity_support_grid" to "electricity_grid"
function GetLayoutConstructionBuildingCost(template_obj)
	if IsGameRuleActive("FreeConstruction") then
		return T(10540, "Cost: Nothing (Free Construction rule)"),false
	end
		
	local costs = {}
	local layout_preset = Presets.LayoutConstruction.Default[template_obj.LayoutList]  or empty_table
	assert(#layout_preset > 0)
	-- addd buildings cost 	
	for _, entry in ipairs(layout_preset) do
		local entity = entry.entity ~= "" and entry.entity
		if entry.template~="life_support_grid" and entry.template~="electricity_grid" then
			local template_class = ClassTemplates.Building[entry.template]
			local mod_o = GetModifierObject(template_class.template_name)
			for _, resource in ipairs(ConstructionResourceList) do
				local amount = UICity:GetConstructionCost(template_class, resource, mod_o)
				if amount > 0 then
					costs[resource] = (costs[resource] or 0) + amount
				end
			end	
		end	
	end

	local items = {}
	for resource, amount in pairs(costs) do
		items[#items+1]  = T{901, "<resource_name><right><resource(number,resource)>", resource_name = Resources[resource].display_name, number = amount, resource = resource }
	end
	if #items > 0 then
		return table.concat(items, "<newline><left>"), costs
	else
		return T(902, "Doesn't require construction resources"), costs
	end
end

function GetLayoutConstructionControllerBMDescription(template, texts, dont_modify)
	local available_prefabs = UICity:GetPrefabs("SelfSufficientDome")
	if available_prefabs>0 then
		texts[#texts+1] = T{3969, "Available prefabs: <number>", number = available_prefabs}
	else
		local text, costs = GetLayoutConstructionBuildingCost(template)
		if costs and next(costs) then
			local cost1 = {}
			for resource, cost in pairs(costs) do
				cost1[#cost1+1] =  FormatResource(empty_table, cost, resource)
			end
			if next(cost1)then
				texts[#texts+1] =  T(263, "Cost: ")..table.concat(cost1," ")
			end
		else
			texts[#texts+1] = text
		end
	end
	local layout_preset = Presets.LayoutConstruction.Default[template.LayoutList]  or empty_table
	assert(#layout_preset > 0)
	
	local consumption = {}
	local maintenance = {}
	local consumption_res = {}
	local entry_templates = {}
	
	for _, entry in ipairs(layout_preset) do
		local entity = entry.entity ~= "" and entry.entity
		if entry.template~="life_support_grid" and entry.template~="electricity_grid" then
			local template_class = ClassTemplates.Building[entry.template]
			 entry_templates[#entry_templates +1] = template_class
		end	
	end		
	
	for i = 1, #maintenance_props do
		local maintenance_prop = maintenance_props[i][1]
		local consumption_resource =  maintenance_props[i][2]
		
		local val = 0
		for idx, template_class in ipairs(entry_templates) do
			local properties = template_class.properties
			local modifier_obj = GetModifierObject(template_class.template_name)
			local prop = table.find_value(properties, "id", maintenance_prop)
			if prop then
				if not dont_modify then
					local disable_prop = table.find_value(properties, "id", "disable_" .. maintenance_prop)
					val = val + (disable_prop and modifier_obj:ModifyValue(template_class[disable_prop.id], disable_prop.id) >= 1
									and 0 or modifier_obj:ModifyValue(template_class[prop.id], prop.id))
				else
					val = val + template_class[prop.id]
				end
			end	
			-- calc only ones additional consumption_res and maintanence
			if i==1  then
				if template_class:DoesHaveConsumption() then
					consumption_res[template_class.consumption_resource_type] = consumption_res[template_class.consumption_resource_type] + 1000
				end
				-- maintanence
				if template_class:DoesRequireMaintenance() and template_class:DoesMaintenanceRequireResources()
					and (dont_modify or modifier_obj:ModifyValue(template_class.disable_maintenance, "disable_maintenance") <= 0) then
					maintenance[template_class.maintenance_resource_type] = (maintenance[template_class.maintenance_resource_type] or 0) + template_class.maintenance_resource_amount
				end
			end
		end
		if val ~= 0 then
			consumption[#consumption + 1] = FormatResource(empty_table, val, consumption_resource)
		end
	end

	if next(consumption) then
		local c_text = ""
		for res, val in pairs(consumption_res) do
			c_text = c_text .. FormatResource(empty_table, val, res).." "
		end	
		if c_text~="" then
			consumption[#consumption + 1] = c_text
		end	
		texts[#texts+1] = T(3959, "Consumption: ") .. table.concat(consumption, " ")
	end
	if next(maintenance) then
		local m_text = ""
		for res, val in pairs(maintenance) do
			m_text = m_text .. FormatResource(empty_table, val, res).." "
		end	
		texts[#texts+1] = T(12398, "Maintenance: ") .. m_text
	end

	return table.concat(texts, "\n")
end
