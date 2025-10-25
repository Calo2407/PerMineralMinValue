extends "res://hud/Hud.gd"

# Neue Map für pro-Mineral-Minimalwerte
var mineralMinValues := {}

# Gibt den Mindestwert für ein bestimmtes Mineral zurück
func getMinValueFor(mineral: String) -> float:
	if not mineralTargetting:
		return 0.0
	return mineralMinValues.get(mineral, getMinValue())

# Setzt den Mindestwert für ein bestimmtes Mineral
func setMinValueFor(mineral: String, value: float):
	if not mineralTargetting:
		return
	mineralMinValues[mineral] = max(value, 0.0)
	# optional in die Schiffsconfig speichern, damit es persistiert
	if ship:
		var config = ship.getConfig(getSlotName("config"), {})
		config["mineralMinValues"] = mineralMinValues
		ship.setConfig(getSlotName("config"), config)

# Beim Booten laden wir existierende Werte
func _ready():
	if mineralTargetting and ship:
		var cfg = ship.getConfig(getSlotName("config"), {})
		if "mineralMinValues" in cfg:
			mineralMinValues = cfg["mineralMinValues"]

# --- OMS: per-Mineral-Logik statt global 1000 E$ -----------------------------

func isValidMineralTarget(body):
	# Wenn Mineral-Targeting aus ist -> Vanilla
	if not mineralTargetting:
		return .isValidMineralTarget(body)

	# Wenn keine per-Mineral-Schwellen gesetzt sind -> Vanilla
	var hasAny := false
	if ship:
		var cfg = ship.getConfig(getSlotName("config"), {})
		if cfg.has("mineralMinValues"):
			for k in cfg["mineralMinValues"].keys():
				if float(cfg["mineralMinValues"][k]) > 0.0:
					hasAny = true
					break
	if not hasAny:
		return .isValidMineralTarget(body)

	# Per-Mineral prüfen: ist IRGENDEIN aktiviertes Mineral im Ziel ≥ eigener Schwelle?
	var enabled = _permin_enabled_minerals()
	var meets = _permin_target_meets_threshold(body, enabled)

	# Wenn wir den Wert nicht sicher bestimmen können -> NICHT blocken (zeige wie Vanilla)
	if meets == null:
		return .isValidMineralTarget(body)
	return bool(meets)

# Aktivierte Minerale aus dem aktuellen HUD/mineralConfig bestimmen
func _permin_enabled_minerals():
	var out = []
	if mineralConfig and mineralConfig.has("minerals"):
		var mineralsNode = mineralConfig["minerals"]
		if typeof(mineralsNode) == TYPE_ARRAY:
			for m in mineralsNode:
				if hasMineralEnabled(m):
					out.append(m)
		elif typeof(mineralsNode) == TYPE_DICTIONARY:
			for m in mineralsNode.keys():
				if hasMineralEnabled(m):
					out.append(m)
	else:
		# Fallback: was das Schiff verarbeitet
		if ship and ship.has_method("getProcessedCargoTypes"):
			for m in ship.getProcessedCargoTypes():
				if hasMineralEnabled(m):
					out.append(m)
	return out

# true/false wenn sicher, null wenn Ziel nicht bewertbar (keine Daten)
func _permin_target_meets_threshold(body, minerals):
	if body == null:
		return null

	# per-Mineral-Werte aus der Schiffsconfig holen (du speicherst sie dort)
	var cfg = ship.getConfig(getSlotName("config"), {})
	var permin = {}
	if cfg.has("mineralMinValues"):
		permin = cfg["mineralMinValues"]

	var couldAssessAny = false

	for m in minerals:
		var thr = float(permin.get(m, getMinValue()))  # fallback auf globalen Slider
		if thr <= 0.0:
			continue

		var amount = 0.0
		var haveAmount = false

		# Bevorzugt: Ziel liefert verarbeitete Cargo-Mengen
		if body.has_method("getProcessedCargo"):
			amount = float(body.getProcessedCargo(m))
			haveAmount = true
		else:
			# Fallback: übliche Zusammensetzung
			var comp = body.get("composition")
			if typeof(comp) == TYPE_DICTIONARY and comp.has(m):
				amount = float(comp[m])
				haveAmount = true

		if not haveAmount:
			continue

		couldAssessAny = true
		if amount <= 0.0:
			continue

		var unitPrice = float(CurrentGame.mineralPrices.get(m, 0.0))
		var worth = amount * unitPrice
		if worth >= thr:
			return true

	if not couldAssessAny:
		return null
	return false
