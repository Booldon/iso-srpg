extends Resource
class_name ChapterData

@export var id: int = 1
@export var title: String = ""
@export var enemy_party: Array[Resource] = []   # Array of UnitStats .tres references
