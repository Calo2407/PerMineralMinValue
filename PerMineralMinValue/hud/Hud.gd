extends "res://hud/Hud.gd"

# IMPORTANT: Do not declare 'var mineralConfig' here, the parent class already has it!

# --- Setup & Config (Load/Save) ---

func _ready():
	# If we are on a ship, load the config
	if mineralTargetting and ship:
		var cfg = ship.getConfig(getSlotName("config"), {})
		if not cfg.has("minerals"):
			var pickup = CurrentGame.traceMinerals.duplicate()
			pickup.append("CARGO_UNKNOWN")
			cfg["minerals"] = pickup
		if not cfg.has("minValue"):
			cfg["minValue"] = 0
		if not cfg.has("mineralMinValues"):
			cfg["mineralMinValues"] = {}
		mineralConfig = cfg
		# Do not write config back immediately to avoid IO, wait for setters.

func setMinValueFor(mineral, value):
	if not mineralTargetting or ship == null:
		return
	if not mineralConfig.has("mineralMinValues"):
		mineralConfig["mineralMinValues"] = {}
	
	mineralConfig["mineralMinValues"][mineral] = max(0.0, float(value))
	ship.setConfig(getSlotName("config"), mineralConfig)

func getMinValueFor(mineral):
	if mineralTargetting and mineralConfig.has("mineralMinValues"):
		return float(mineralConfig["mineralMinValues"].get(mineral, getMinValue()))
	return getMinValue()

# UI Helper: Checks if a mineral is enabled (Toggle)
func hasMineralEnabled(mineral):
	if not mineralConfig.has("minerals"):
		return true
	var m = mineralConfig["minerals"]
	if typeof(m) == TYPE_ARRAY:
		return m.has(mineral)
	if typeof(m) == TYPE_DICTIONARY:
		return m.has(mineral) and m[mineral]
	return false

# UI Helper: Saves Toggles
func setMineralConfig(mineral, enabled):
	if not mineralConfig.has("minerals"):
		mineralConfig["minerals"] = []
	
	var m = mineralConfig["minerals"]
	if typeof(m) == TYPE_ARRAY:
		if enabled and not m.has(mineral):
			m.append(mineral)
		elif not enabled and m.has(mineral):
			m.erase(mineral)
	elif typeof(m) == TYPE_DICTIONARY:
		m[mineral] = enabled
		
	ship.setConfig(getSlotName("config"), mineralConfig)

# --- OMS Targeting Logic (The green brackets) ---

func isValidMineralTarget(body):
	# 1. Vanilla checks (e.g. is OMS enabled?)
	if not mineralTargetting:
		return .isValidMineralTarget(body)

	# 2. Do we have any active sliders?
	# If all sliders are 0, fall back to vanilla behavior (show everything enabled)
	var hasAny = false
	if mineralConfig.has("mineralMinValues"):
		for k in mineralConfig["mineralMinValues"].keys():
			if float(mineralConfig["mineralMinValues"][k]) > 0.0:
				hasAny = true
				break
	
	if not hasAny:
		return .isValidMineralTarget(body)

	# 3. Extended check using our new logic
	var enabled_minerals = _permin_enabled_minerals()
	var meets = _permin_target_meets_threshold(body, enabled_minerals)
	
	if meets == null:
		# Fallback: If we couldn't assess the value, let vanilla decide
		return .isValidMineralTarget(body)
		
	return meets

# --- Helper Functions (Identical to DockingArm/DronePlant) ---

func _permin_enabled_minerals() -> Array:
	var out = []
	if mineralConfig.has("minerals"):
		var n = mineralConfig["minerals"]
		if typeof(n) == TYPE_ARRAY:
			for m in n:
				if hasMineralEnabled(m):
					out.append(m)
		elif typeof(n) == TYPE_DICTIONARY:
			for m in n.keys():
				if hasMineralEnabled(m):
					out.append(m)
	else:
		if ship and ship.has_method("getProcessedCargoTypes"):
			for m in ship.getProcessedCargoTypes():
				if hasMineralEnabled(m):
					out.append(m)
	return out

func _get_geologist_error_factor(body):
	if not body: return 1.0
	
	# Use cache (Sync with MineralMark & Drones)
	if body.has_meta("geo_factor"):
		return body.get_meta("geo_factor")
	
	# Fallback calculation
	var accuracy = 1.0
	if CurrentGame and CurrentGame.has_method("getGeologistAccurancy"):
		accuracy = CurrentGame.getGeologistAccurancy()
	
	var seed_val = body.get_instance_id()
	var deterministic_rand = CurrentGame.sraf(seed_val)
	var factor = 1.0 + (deterministic_rand - 0.5) * 2.0 * (1.0 - accuracy)
	
	body.set_meta("geo_factor", factor)
	return factor

func _permin_target_meets_threshold(body, minerals: Array):
	if body == null:
		return null

	# 1. Get base market value of the WHOLE rock
	var total_real_value = 0.0
	if CurrentGame and CurrentGame.has_method("getMarketPrice"):
		total_real_value = CurrentGame.getMarketPrice(body)
	else:
		return null 

	# 2. Apply geologist error
	var geo_factor = _get_geologist_error_factor(body)
	var perceived_total_value = total_real_value * geo_factor

	var has_active_threshold = false

	# 3. Check minerals
	for m in minerals:
		# Is mineral m present in the asteroid?
		var has_mineral = false
		if body.has_method("getProcessedCargo"):
			if body.getProcessedCargo(m) > 0: has_mineral = true
		else:
			var comp = body.get("composition")
			if typeof(comp) == TYPE_DICTIONARY and comp.has(m) and comp[m] > 0:
				has_mineral = true

		if not has_mineral:
			continue
			
		# FIX: Convert slider value (kE$) to E$ (Market Price)
		var threshold = getMinValueFor(m) * 1000.0
		
		if threshold > 0.0:
			has_active_threshold = true
			if perceived_total_value >= threshold:
				return true

	# If active limits existed but none were met -> Reject
	if has_active_threshold:
		return false
		
	# No relevant limits -> Neutral (null)
	return null
