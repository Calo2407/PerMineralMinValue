extends Node

const MOD_PRIORITY = 0
const MOD_NAME = "PerMineralMinValue"

var modPath: String = get_script().resource_path.get_base_dir() + "/"
var _savedObjects = []

func _init(modLoader := null):
	l("Initializing")

	# Extend vanilla scripts with our overrides
	installScriptExtension("hud/Hud.gd")
	installScriptExtension("hud/SystemMineralList.gd")
	installScriptExtension("ships/modules/DockingArm.gd")
	installScriptExtension("weapons/drone-plant.gd")
	# NOTE: We intentionally do NOT override hud/components/PriceLabel.gd
	# to avoid interfering with vanilla visibility/disabled behavior.

	l("Initialized")

# Optional: CSV translation loader (kept as utility, no behavioral change)
func updateTL(path: String, delim: String = ","):
	path = str(modPath + path)
	l("Adding translations from: %s" % path)

	var tlFile := File.new()
	if tlFile.open(path, File.READ) != OK:
		l("Failed to open translations at: %s" % path)
		return

	var translations = []
	var csvLine = tlFile.get_line().split(delim)
	l("Adding translations as locales: %s" % csvLine)

	for i in range(1, csvLine.size()):
		var tr := Translation.new()
		tr.locale = csvLine[i]
		translations.append(tr)

	while not tlFile.eof_reached():
		csvLine = tlFile.get_csv_line(delim)
		if csvLine.size() > 1:
			var key = csvLine[0]
			for i in range(1, csvLine.size()):
				translations[i - 1].add_message(key, csvLine[i].c_unescape())
			l("Added translation row: %s" % csvLine)

	tlFile.close()

	for tr_obj in translations:
		TranslationServer.add_translation(tr_obj)

	l("Translations updated")

func installScriptExtension(path: String):
	var childPath := str(modPath + path)
	var childScript: Script = ResourceLoader.load(childPath)
	if childScript == null:
		l("Missing child script: %s" % childPath)
		return

	# Force class to initialize so base is available
	childScript.new()

	var parentScript: Script = childScript.get_base_script()
	if parentScript == null:
		l("No base script for: %s" % childPath)
		return

	var parentPath: String = parentScript.resource_path
	l("Installing script extension: %s <- %s" % [parentPath, childPath])
	childScript.take_over_path(parentPath)

func replaceScene(newPath: String, oldPath: String = ""):
	l("Updating scene: %s" % newPath)

	if oldPath.empty():
		oldPath = str("res://" + newPath)

	newPath = str(modPath + newPath)

	var scene := load(newPath)
	if scene == null:
		l("Failed to load scene: %s" % newPath)
		return

	scene.take_over_path(oldPath)
	_savedObjects.append(scene)
	l("Finished updating: %s" % oldPath)

# DLC preloader helper (no logic change)
func loadDLC():
	l("Preloading DLC")
	var DLCLoader: Settings = preload("res://Settings.gd").new()
	DLCLoader.loadDLC()
	DLCLoader.queue_free()
	l("Finished loading DLC")

func l(msg: String, title: String = MOD_NAME):
	Debug.l("[%s]: %s" % [title, msg])
