extends PathFollow3D
## Drives along its [Path3D] at [member speed], round and round: the park's truck, for skitching. Anything moved
## this way that the board may hang off goes in the "skitchable" group with a SkitchPoint child at its back.

@export var speed: float = 10.0 ## Metres a second along the path.


func _physics_process(delta: float) -> void:
	progress += speed * delta
