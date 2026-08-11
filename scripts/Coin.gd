extends Area3D

var collected := false

func pickup_coin(peer_id: int) -> void:
    if collected:
        return
    collected = true
    GameManager.collect_coin(peer_id)
    AudioManager.play("coin")
    queue_free()
