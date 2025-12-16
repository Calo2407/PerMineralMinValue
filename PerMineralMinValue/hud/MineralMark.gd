extends "res://hud/MineralMark.gd"

# Override _ready and leave it EMPTY to prevent vanilla logic from interfering
func _ready():
	pass

# Hook into scanParent because this is where we know the actual asteroid node
func scanParent(parent):
	_sync_error_factor(parent)
	# Call the original function -> it will now use our synchronized 'error' variable
	.scanParent(parent)

# Helper: Synchronize the error value deterministically
func _sync_error_factor(body):
	if not body:
		return

	# 1. Has the error factor already been calculated (by drones or previous scan)?
	if body.has_meta("geo_factor"):
		error = body.get_meta("geo_factor")
	else:
		# 2. No -> Calculate new one (Deterministic based on ID)
		var accuracy = 1.0
		if CurrentGame and CurrentGame.has_method("getGeologistAccurancy"):
			accuracy = CurrentGame.getGeologistAccurancy()
			
		var seed_val = body.get_instance_id()
		var deterministic_rand = CurrentGame.sraf(seed_val)
		
		# Formula: 1.0 +/- (Random * Inaccuracy)
		var calculated_error = 1.0 + (deterministic_rand - 0.5) * 2.0 * (1.0 - accuracy)
		
		# 3. Save for all other systems (OMS, Drones, Arm)
		body.set_meta("geo_factor", calculated_error)
		error = calculated_error
