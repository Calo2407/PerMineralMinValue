extends "res://ships/modules/DockingArm.gd"

# ------------------------------ Setup / API ------------------------------

func _ready():
	._ready()
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
		ship.setConfig(getSlotName("config"), mineralConfig)

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

# ------------------------------ Target validation ------------------------------

func isValidTarget(body):
	var ok = .isValidTarget(body)
	if not ok:
		return false
	if not mineralTargetting:
		return true

	# If no per-min thresholds are > 0, do not change vanilla behavior
	var hasAny = false
	if mineralConfig.has("mineralMinValues"):
		for k in mineralConfig["mineralMinValues"].keys():
			if float(mineralConfig["mineralMinValues"][k]) > 0.0:
				hasAny = true
				break
	if not hasAny:
		return true

	var enabled = _permin_enabled_minerals()
	var meets = _permin_target_meets_threshold(body, enabled)
	if meets == null:
		# Could not assess -> fall back to vanilla behavior
		return true
	return meets

# ------------------------------ Helpers ------------------------------

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

# Returns geologist's estimated price if available, otherwise falls back to market price.
func _geo_estimated_price(m):
	if CurrentGame and CurrentGame.has_method("getEstimatedMineralPrice"):
		return float(CurrentGame.getEstimatedMineralPrice(m))

	var est_dict = null
	if CurrentGame:
		est_dict = CurrentGame.get("estimatedMineralPrices")
	if typeof(est_dict) == TYPE_DICTIONARY and est_dict.has(m):
		return float(est_dict[m])

	var geo_dict = null
	if CurrentGame:
		geo_dict = CurrentGame.get("geologistPrices")
	if typeof(geo_dict) == TYPE_DICTIONARY and geo_dict.has(m):
		return float(geo_dict[m])

	var market = null
	if CurrentGame:
		market = CurrentGame.get("mineralPrices")
	if typeof(market) == TYPE_DICTIONARY and market.has(m):
		return float(market[m])

	return 0.0

# Returns: true/false if assessed; null if cannot assess (do not block vanilla)
func _permin_target_meets_threshold(body, minerals: Array):
	if body == null:
		return null

	var could_assess_any = false

	for m in minerals:
		var amount = 0.0
		var have_amount = false

		# Amount in the target body
		if body.has_method("getProcessedCargo"):
			amount = float(body.getProcessedCargo(m))
			have_amount = true
		else:
			var comp = body.get("composition")
			if typeof(comp) == TYPE_DICTIONARY and comp.has(m):
				amount = float(comp[m])
				have_amount = true

		if not have_amount or amount <= 0.0:
			continue

		# Use geologist estimate when available
		var unit_price = _geo_estimated_price(m)
		if unit_price <= 0.0:
			# No estimate yet — skip; do not block overall decision
			continue

		could_assess_any = true

		# Worth and threshold are in internal units
		var worth = amount * unit_price

		# print("ARM worth %s for %s vs min %s" % [worth, m, getMinValueFor(m)])

		if worth >= getMinValueFor(m):
			return true

	if not could_assess_any:
		return null
	return false
