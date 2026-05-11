extends RefCounted
class_name TileType

# Категории тайлов на поле.
# ENEMY — особый тип: тайл-враг с HP, наносится урон при включении в цепочку.

enum Kind {
	EMPTY,
	SWORD,
	SHIELD,
	COIN,
	HEART,
	ENEMY,
}

# Веса для рандомной генерации (без ENEMY — враги ставятся отдельно).
const SPAWN_WEIGHTS := {
	Kind.SWORD: 30,
	Kind.SHIELD: 20,
	Kind.COIN: 20,
	Kind.HEART: 15,
}

static func name_of(kind: int) -> String:
	match kind:
		Kind.EMPTY:  return "empty"
		Kind.SWORD:  return "sword"
		Kind.SHIELD: return "shield"
		Kind.COIN:   return "coin"
		Kind.HEART:  return "heart"
		Kind.ENEMY:  return "enemy"
	return "unknown"

# Можно ли соединить тайлы типов a и b в одну цепочку.
# По дефолту — только одинаковые. Враги цепляются с мечами (ключевая фишка).
static func can_link(a: int, b: int) -> bool:
	if a == b:
		return true
	if (a == Kind.SWORD and b == Kind.ENEMY) or (a == Kind.ENEMY and b == Kind.SWORD):
		return true
	return false
