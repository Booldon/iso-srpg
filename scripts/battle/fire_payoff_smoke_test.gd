## 헤드리스 스모크 테스트 — Fire F1 (temp STR + detonation) 로직 검증
## 실행: Godot 에디터 > 이 파일 열기 > 우상단 "실행" 아이콘
## 또는 헤드리스: godot --headless --script res://scripts/battle/fire_payoff_smoke_test.gd
## 테스트 프레임워크(GUT) 없이 print+assert 방식. 실패 시 FAIL 출력.
extends SceneTree

var _pass := 0
var _fail := 0


func _check(label: String, condition: bool) -> void:
	if condition:
		print("  PASS  %s" % label)
		_pass += 1
	else:
		printerr("  FAIL  %s" % label)
		_fail += 1


# Unit stub: minimal Unit-like object for testing logic in isolation.
# We cannot instantiate Unit (it is a Node2D requiring a scene), so we simulate the
# three new methods directly to verify the formulas, then test StatusEffects + CardEffects
# with real UnitStats + a custom inner class.
class FakeUnit:
	var stats: UnitStats
	var status: Dictionary = {}
	var cards: Array = []   # untyped — CardData objects added manually
	var temp_strength: int = 0
	var is_player: bool = true

	func effective_strength() -> int:
		return stats.strength + temp_strength

	func is_alive() -> bool:
		return effective_strength() > 0

	func take_str_damage(amount: int) -> void:
		if amount <= 0:
			return
		var from_temp := mini(temp_strength, amount)
		temp_strength -= from_temp
		var remaining := amount - from_temp
		stats.strength = maxi(0, stats.strength - remaining)


func _make_unit(base_str: int, base_armor: int = 0, temp: int = 0) -> FakeUnit:
	var u := FakeUnit.new()
	u.stats = UnitStats.new()
	u.stats.strength = base_str
	u.stats.armor = base_armor
	u.stats.speed = 10
	u.stats.move_range = 3
	u.temp_strength = temp
	return u


func _init() -> void:
	print("\n=== Fire F1 Payoff Smoke Test ===\n")

	# ─ ブロック A: effective_strength ─────────────────────────────────────────
	print("-- A: effective_strength --")
	var u := _make_unit(10, 0, 3)
	_check("effective = base + temp", u.effective_strength() == 13)
	_check("is_alive when eff > 0", u.is_alive())
	var dead_u := _make_unit(0, 0, 0)
	_check("is_alive false when eff == 0", not dead_u.is_alive())

	# ─ 블록 B: take_str_damage — temp 버퍼 우선 차감 ──────────────────────────
	print("\n-- B: take_str_damage --")
	var v := _make_unit(10, 0, 3)
	v.take_str_damage(2)
	_check("damage ≤ temp: temp depleted first (temp 1 remain)", v.temp_strength == 1)
	_check("damage ≤ temp: base unchanged", v.stats.strength == 10)

	var w := _make_unit(10, 0, 3)
	w.take_str_damage(5)
	_check("damage > temp: temp goes to 0", w.temp_strength == 0)
	_check("damage > temp: remainder hits base (10-(5-3)=8)", w.stats.strength == 8)

	var x := _make_unit(10, 0, 0)
	x.take_str_damage(6)
	_check("no temp: base reduced directly (10-6=4)", x.stats.strength == 4)
	_check("no temp: temp stays 0", x.temp_strength == 0)

	var y := _make_unit(2, 0, 1)
	y.take_str_damage(10)
	_check("overkill clamps base to 0", y.stats.strength == 0)
	_check("overkill clamps temp to 0", y.temp_strength == 0)
	_check("overkill: is_alive false", not y.is_alive())

	# ─ 블록 C: StatusEffects.consume ──────────────────────────────────────────
	print("\n-- C: StatusEffects.consume --")
	var su := _make_unit(10)
	StatusEffects.add(su, StatusEffects.Type.BURN, 4)
	var removed := StatusEffects.consume(su, StatusEffects.Type.BURN, 2)
	_check("consume 2 of 4: removed == 2", removed == 2)
	_check("consume 2 of 4: stacks now 2", StatusEffects.get_stacks(su, StatusEffects.Type.BURN) == 2)

	var su2 := _make_unit(10)
	StatusEffects.add(su2, StatusEffects.Type.BURN, 3)
	var removed_all := StatusEffects.consume(su2, StatusEffects.Type.BURN, StatusEffects.MAX_STACK)
	_check("consume all (MAX_STACK cap): removed 3", removed_all == 3)
	_check("consume all: stacks now 0", StatusEffects.get_stacks(su2, StatusEffects.Type.BURN) == 0)

	var su3 := _make_unit(10)
	var removed_none := StatusEffects.consume(su3, StatusEffects.Type.BURN, 5)
	_check("consume from empty: removed 0", removed_none == 0)
	_check("consume from empty: stacks still 0", StatusEffects.get_stacks(su3, StatusEffects.Type.BURN) == 0)

	# ─ 블록 D: Burn tick — take_str_damage 경로 ──────────────────────────────
	print("\n-- D: Burn tick via tick_turn_start --")
	var tu := _make_unit(10, 0, 3)
	StatusEffects.add(tu, StatusEffects.Type.BURN, 3)
	var dmg := StatusEffects.tick_turn_start(tu)
	_check("tick returns 3 (3 stacks × 1)", dmg == 3)
	_check("tick deducts from temp first (temp 0 remain)", tu.temp_strength == 0)
	_check("tick deducts remaining from base (10+3-3 eff = 10, base 10)", tu.stats.strength == 10)
	_check("burn decays by 1 (3→2)", StatusEffects.get_stacks(tu, StatusEffects.Type.BURN) == 2)

	# ─ 블록 E: detonation (raging_flame 패턴) ─────────────────────────────────
	print("\n-- E: detonation via CardEffects --")
	var attacker := _make_unit(10, 0, 0)
	var target := _make_unit(20, 5, 0)

	# raging_flame: min_burn=2, consume_burn=2, burst_per_stack=3
	var raging := CardData.new()
	raging.on_attack_min_burn = 2
	raging.on_attack_consume_burn = 2
	raging.on_attack_burst_per_stack = 3
	attacker.cards = [raging]

	# 케이스 1: Burn < min_burn → 게이트 막힘
	StatusEffects.add(target, StatusEffects.Type.BURN, 1)
	CardEffects.apply_on_attack(attacker, target)
	_check("gate blocks when Burn(1) < min_burn(2): base unchanged", target.stats.strength == 20)
	_check("gate blocks: Burn still 1", StatusEffects.get_stacks(target, StatusEffects.Type.BURN) == 1)

	# 케이스 2: Burn ≥ min_burn → 소비 + 방어 무시 데미지
	StatusEffects.add(target, StatusEffects.Type.BURN, 2)  # now 3 total
	CardEffects.apply_on_attack(attacker, target)
	_check("gate passes when Burn(3) >= min_burn(2): burst = 2×3 = 6, armor ignored", target.stats.strength == 14)
	_check("raging_flame consumes 2: Burn now 1", StatusEffects.get_stacks(target, StatusEffects.Type.BURN) == 1)

	# ─ 블록 F: overheat (burst_flat 패턴) ────────────────────────────────────
	print("\n-- F: burst_flat (overheat) --")
	var ov_attacker := _make_unit(10, 0, 0)
	var ov_target := _make_unit(20, 5, 0)
	var overheat := CardData.new()
	overheat.on_attack_min_burn = 3
	overheat.on_attack_burst_flat = 4

	# Burn < 3 → 발동 안 함
	StatusEffects.add(ov_target, StatusEffects.Type.BURN, 2)
	ov_attacker.cards = [overheat]
	CardEffects.apply_on_attack(ov_attacker, ov_target)
	_check("overheat gated at Burn(2) < 3: no damage", ov_target.stats.strength == 20)
	_check("overheat gated: Burn stacks unchanged (2)", StatusEffects.get_stacks(ov_target, StatusEffects.Type.BURN) == 2)

	# Burn ≥ 3 → 발동, armor 무시
	StatusEffects.add(ov_target, StatusEffects.Type.BURN, 1)  # now 3
	CardEffects.apply_on_attack(ov_attacker, ov_target)
	_check("overheat fires at Burn(3): burst_flat 4, armor ignored → 20-4=16", ov_target.stats.strength == 16)
	_check("overheat: no stack consumed (still 3)", StatusEffects.get_stacks(ov_target, StatusEffects.Type.BURN) == 3)

	# ─ 블록 G: grand_detonation (consume_all + per_stack) ────────────────────
	print("\n-- G: grand_detonation --")
	var gd_attacker := _make_unit(10, 0, 0)
	var gd_target := _make_unit(30, 5, 0)
	var grand := CardData.new()
	grand.on_attack_min_burn = 3
	grand.on_attack_consume_all_burn = true
	grand.on_attack_burst_per_stack = 5
	gd_attacker.cards = [grand]

	StatusEffects.add(gd_target, StatusEffects.Type.BURN, 5)  # max stacks
	CardEffects.apply_on_attack(gd_attacker, gd_target)
	_check("grand_detonation consumes all 5 stacks: burst = 5×5 = 25", gd_target.stats.strength == 5)
	_check("grand_detonation: all stacks gone (0)", StatusEffects.get_stacks(gd_target, StatusEffects.Type.BURN) == 0)

	# min_burn gate on grand_detonation
	var gd_target2 := _make_unit(30, 5, 0)
	StatusEffects.add(gd_target2, StatusEffects.Type.BURN, 2)
	CardEffects.apply_on_attack(gd_attacker, gd_target2)
	_check("grand_detonation: Burn(2) < min(3), gated — no damage", gd_target2.stats.strength == 30)

	# ─ 최종 결과 ─────────────────────────────────────────────────────────────
	print("\n=== Result: %d PASS / %d FAIL ===" % [_pass, _fail])
	if _fail > 0:
		printerr(">>> SMOKE TEST FAILED — %d test(s) did not pass" % _fail)
		quit(1)
	else:
		print("All tests passed.")
		quit(0)
