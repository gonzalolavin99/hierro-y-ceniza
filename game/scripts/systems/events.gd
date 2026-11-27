extends Node
## Bus de eventos (docs/06 §5, docs/15 §D): señales globales para que unos sistemas se enteren de otros
## sin depender entre sí. Por ahora solo una (#46); las demás se añaden cuando haga falta, sin migrar nada.
## Uso: Events.enemy_alerted.emit(self) · Events.enemy_alerted.connect(_on_enemy_alerted)

## Un enemigo acaba de entrar en alerta (descubrió a Kael o oyó la alarma de un compañero).
signal enemy_alerted(enemy: Node3D)
