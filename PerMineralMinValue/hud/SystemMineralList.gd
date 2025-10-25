extends "res://hud/SystemMineralList.gd"

export (PackedScene) var vpriceBox = preload("res://PerMineralMinValue/hud/components/VPriceLabel.tscn")

const COL_W        = 90
const COL_W_NARROW = 40
const CELL_H       = 60
const UI_MAX_E     = 20000.0  # UI slider range in E$

# UI registries to mirror sliders/toggles between tabs
var _global_price_by_sys = {}            # sysId -> PriceLabel (vanilla)
var _custom_price_by_sys_m = {}          # sysId|mineral -> VPriceLabel
var _vanilla_toggle_by_sys_m = {}        # sysId|mineral -> Button
var _custom_toggle_by_sys_m = {}         # sysId|mineral -> Button

var tabs = null
var currentFocusMineral = ""

func _sid(sys):
	return str(sys.get_instance_id())

func _key(sys, mineral):
	return _sid(sys) + "|" + mineral

func _col_width_for(m):
	if m == "CARGO_UNKNOWN":
		return COL_W_NARROW
	return COL_W

# Shorten long tab titles; special-case onboard computer
func _short_tab_title(name):
	var low = name.to_lower()
	if low.find("amd-752s") != -1 and (low.find("on-board") != -1 or low.find("computer") != -1 or low.find("bord") != -1):
		return "AMD-752S OBC"
	var max_len = 22
	if name.length() <= max_len:
		return name
	return name.substr(0, max_len - 1) + "…"

# UI E$ <-> internal units (internal ≈ UI/1000)
func _to_display_e(internal_v):
	if internal_v == null:
		return 0.0
	var disp = float(internal_v) * 1000.0
	return clamp(disp, 0.0, UI_MAX_E)

func _from_display_e(ui_v):
	return float(ui_v) / 1000.0

# ---------------- Focus relay ----------------

func _ready():
	if has_signal("mineralFocusChanged"):
		connect("mineralFocusChanged", self, "_onMineralFocusChanged")

func _onMineralFocusChanged(m):
	currentFocusMineral = m

func getFocusMineral() -> String:
	return currentFocusMineral

# ---------------- Mirror helpers ----------------

func _refresh_price_views_for_system(system):
	var sid = _sid(system)
	if _global_price_by_sys.has(sid):
		var pb = _global_price_by_sys[sid]
		if is_instance_valid(pb) and system.has_method("getMinValue"):
			pb.value = _to_display_e(system.getMinValue())
	for m in minerals:
		if m == "CARGO_UNKNOWN":
			continue
		var k = _key(system, m)
		if _custom_price_by_sys_m.has(k):
			var vp = _custom_price_by_sys_m[k]
			if is_instance_valid(vp) and system.has_method("getMinValueFor"):
				var v = system.getMinValueFor(m)
				if v != null:
					vp.value = _to_display_e(v)

func _refresh_toggle_views_for(system, mineral):
	var en = false
	if system.has_method("hasMineralEnabled"):
		en = system.hasMineralEnabled(mineral)
	var k = _key(system, mineral)
	if _vanilla_toggle_by_sys_m.has(k):
		var t1 = _vanilla_toggle_by_sys_m[k]
		if is_instance_valid(t1):
			t1.pressed = en
	if _custom_toggle_by_sys_m.has(k):
		var t2 = _custom_toggle_by_sys_m[k]
		if is_instance_valid(t2):
			t2.pressed = en

# ---------------- Build one per-system tab ----------------

func _build_system_tab(system_name, ref):
	var grid = GridContainer.new()
	grid.columns = minerals.size()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Header row (mineral labels)
	for m in minerals:
		var i = mineralLabel.instance()
		if CurrentGame.specificMineralColors.has(m):
			i.modulate = CurrentGame.specificMineralColors[m]
		else:
			i.modulate = unknownColor
		i.mineral = m
		var header_label = null
		if i.has_method("get_label"):
			header_label = i.get_label()
		elif "label" in i and i.label:
			header_label = i.label
		if header_label:
			header_label.rect_min_size.x = _col_width_for(m)
			header_label.clip_text = true
			header_label.align = Label.ALIGN_CENTER
		grid.add_child(i)

	# Row with toggles + sliders (no system-name column)
	for m in minerals:
		var w = _col_width_for(m)

		var cell = VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cell.add_constant_override("separation", 2)

		# Toggle
		var t = toggleBox.instance()
		if ref.has_method("hasMineralEnabled"):
			t.pressed = ref.hasMineralEnabled(m)
		t.connect("toggled", self, "toggle", [ref, m])
		_custom_toggle_by_sys_m[_key(ref, m)] = t

		var only_minerals = ref.get("onlyMinerals")
		if only_minerals and not CurrentGame.traceMinerals.has(m):
			t.disabled = true
			t.modulate = modulateDisabled

		var tCenter = CenterContainer.new()
		tCenter.rect_min_size = Vector2(w, 0)
		tCenter.add_child(t)
		cell.add_child(tCenter)

		# Slider or spacer
		var skip_slider = (m == "CARGO_UNKNOWN")
		if skip_slider:
			var spacer = Control.new()
			spacer.rect_min_size = Vector2(w, CELL_H)
			cell.add_child(spacer)
		else:
			var p = vpriceBox.instance()
			p.connect("valueChanged", self, "_onMineralMinChanged", [ref, m])
			# Start value = 0 E$ (intended)
			p.value = 0.0
			cell.add_child(p)
			_custom_price_by_sys_m[_key(ref, m)] = p

		grid.add_child(cell)

	# Margins wrapper
	var mc = MarginContainer.new()
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mc.add_constant_override("margin_left", 8)
	mc.add_constant_override("margin_right", 8)
	mc.add_constant_override("margin_top", 6)
	mc.add_constant_override("margin_bottom", 6)
	mc.add_child(grid)
	return mc

# ---------------- Vanilla handlers ----------------

# Global slider changed (UI E$)
func value(how, system):
	if not system:
		return

	# Write global (internal)
	var internal = _from_display_e(how)
	if system.has_method("setMinValue"):
		system.setMinValue(internal)

	# Rule: raise per-min only if below global; do not lower
	if system.has_method("getMinValueFor") and system.has_method("setMinValueFor"):
		for m in minerals:
			if m == "CARGO_UNKNOWN":
				continue
			var cur_internal = system.getMinValueFor(m)
			if cur_internal == null:
				continue
			if float(cur_internal) < float(internal):
				system.setMinValueFor(m, internal)
				# Mirror UI for custom
				var k = _key(system, m)
				if _custom_price_by_sys_m.has(k):
					var vp = _custom_price_by_sys_m[k]
					if is_instance_valid(vp):
						vp.value = how  # already UI units

	# Refresh global and custom views
	_refresh_price_views_for_system(system)

# Toggle from either tab
func toggle(how, system, mineral):
	if system and system.has_method("setMineralConfig"):
		system.setMineralConfig(mineral, how)
	_refresh_toggle_views_for(system, mineral)

# ---------------- Build whole UI ----------------

func updateSystems(systems):
	# Clear
	for c in get_children():
		c.queue_free()
	_global_price_by_sys.clear()
	_custom_price_by_sys_m.clear()
	_vanilla_toggle_by_sys_m.clear()
	_custom_toggle_by_sys_m.clear()

	if self is GridContainer:
		self.columns = 1

	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(tabs)

	# --- Global tab (vanilla layout) ---
	var vanillaGrid = GridContainer.new()
	vanillaGrid.columns = minerals.size() + 2
	vanillaGrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vanillaGrid.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vblank = Label.new()
	vanillaGrid.add_child(vblank)

	for m in minerals:
		var i = mineralLabel.instance()
		if CurrentGame.specificMineralColors.has(m):
			i.modulate = CurrentGame.specificMineralColors[m]
		else:
			i.modulate = unknownColor
		i.mineral = m
		if CurrentGame.specificMineralColors.has(m):
			i.connect("focus_entered", self, "focusOnMineral", [m])
			if i.has_method("highlightChange"):
				connect("mineralFocusChanged", i, "highlightChange")
		vanillaGrid.add_child(i)

	var minValHdr = mineralLabel.instance()
	minValHdr.text = "Minimum value"
	vanillaGrid.add_child(minValHdr)

	for s in systems:
		var ref = systems[s].ref
		var rlock = ref
		if Tool.claim(rlock):
			if "system" in ref and ref.system:
				ref = ref.system
			if "mineralTargetting" in ref and ref.mineralTargetting:
				var l = systemLabel.instance()
				l.text = systems[s].name
				vanillaGrid.add_child(l)

				for m in minerals:
					var tgl = toggleBox.instance()
					tgl.connect("toggled", self, "toggle", [ref, m])
					tgl.connect("focus_entered", self, "focusOnMineral", [m])
					if ref.has_method("hasMineralEnabled"):
						tgl.pressed = ref.hasMineralEnabled(m)
					if "onlyMinerals" in ref and ref.onlyMinerals and not CurrentGame.traceMinerals.has(m):
						tgl.disabled = true
						tgl.modulate = modulateDisabled
					vanillaGrid.add_child(tgl)
					_vanilla_toggle_by_sys_m[_key(ref, m)] = tgl

				var pb = priceBox.instance()
				pb.connect("valueChanged", self, "value", [ref])
				# Start value = 0 E$ (intended)
				pb.value = 0.0
				vanillaGrid.add_child(pb)
				_global_price_by_sys[_sid(ref)] = pb
		Tool.release(rlock)

	var mcg = MarginContainer.new()
	mcg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mcg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mcg.add_constant_override("margin_left", 8)
	mcg.add_constant_override("margin_right", 8)
	mcg.add_constant_override("margin_top", 6)
	mcg.add_constant_override("margin_bottom", 6)
	mcg.add_child(vanillaGrid)

	tabs.add_child(mcg)
	tabs.set_tab_title(0, "Global")

	# --- Per-system tabs ---
	var idx = 1
	for s2 in systems:
		var ref2 = systems[s2].ref
		var rlock2 = ref2
		if Tool.claim(rlock2):
			if "system" in ref2 and ref2.system:
				ref2 = ref2.system
			if "mineralTargetting" in ref2 and ref2.mineralTargetting:
				var title = _short_tab_title(systems[s2].name)
				var tab = _build_system_tab(title, ref2)
				tabs.add_child(tab)
				tabs.set_tab_title(idx, title)
				idx += 1
		Tool.release(rlock2)

	tabs.current_tab = 0
	focusOnMineral(defaultFocus)

# ---------------- Custom slider write-back ----------------

func _onMineralMinChanged(value, system, mineral):
	if not system:
		return

	var internal = _from_display_e(value)
	if system.has_method("setMinValueFor"):
		system.setMinValueFor(mineral, internal)

	# Rule: lower global only if global > custom; do not raise
	if system.has_method("getMinValue") and system.has_method("setMinValue"):
		var g = system.getMinValue()
		if g == null or float(g) > float(internal):
			system.setMinValue(internal)
			var sid = _sid(system)
			if _global_price_by_sys.has(sid):
				var pb = _global_price_by_sys[sid]
				if is_instance_valid(pb):
					pb.value = value  # already UI units

	_refresh_toggle_views_for(system, mineral)
