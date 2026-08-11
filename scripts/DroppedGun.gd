extends Area3D

var picked_up := false

func pickup_gun(_peer_id: int) -> void:
    if picked_up:
        return
    picked_up = true
    queue_free()
