extends Resource
class_name BoonData

enum Target { ALLY_BUFF, ENEMY_DEBUFF }
enum Stat { STRENGTH, ARMOR, SPEED, MOVE_RANGE }

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var target: Target = Target.ALLY_BUFF
@export var stat: Stat = Stat.STRENGTH
@export var amount: int = 1             # always positive; sign determined by target
