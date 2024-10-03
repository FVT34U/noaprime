extends Area3D
class_name HitboxComponent

@export var health_component: Node
@export var hitbox_type: HitboxType.HITBOX_TYPE = HitboxType.HITBOX_TYPE.ANY

func get_hitbox_type():
	return hitbox_type

@rpc("any_peer", "call_local")
func take_damage(dmg: Dictionary):
	if health_component:
		if health_component.has_method("take_damage"):
			health_component.take_damage(DamageData.from_dict(dmg))
