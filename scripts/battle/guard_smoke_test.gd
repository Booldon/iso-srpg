## 헤드리스 스모크 테스트 — Earth G1 (Guard 기반 슬라이스) 로직 검증
## 실행: Godot 에디터 > 이 파일 열기 > 우상단 "실행" 아이콘
## 또는 헤드리스: godot --headless --script res://scripts/battle/guard_smoke_test.gd
## 테스트 프레임워크(GUT) 없이 print+assert 방식. 실패 시 FAIL 출력.
##
## fire_payoff_smoke_test.gd와 달리 FakeUnit을 쓰지 않는다: StatusEffects/CardEffects의
## 정적 타입 인자(unit: Unit)는 GDScript 컴파일 타임에 실제 Unit 서브클래스만 허용하므로
## (duck-typed 클래스는 타입 오류로 거부됨), 실제 Unit.new() + UnitStats.new()를 사용한다.
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


func _make_unit(base_str: int, base_armor: int = 0) -> Unit:
	var u := Unit.new()
	u.stats = UnitStats.new()
	u.stats.strength = base_str
	u.stats.armor = base_armor
	u.stats.speed = 10
	u.stats.move_range = 3
	u.temp_strength = 0
	return u


func _init() -> void:
	print("\n=== Earth G1 (Guard) Smoke Test ===\n")

	# ─ 블록 A: Guard 스택 → effective_armor ───────────────────────────────────
	print("-- A: Guard stacks raise effective_armor --")
	var a := _make_unit(10, 3)
	_check("no Guard: effective_armor == base (3)", a.effective_armor() == 3)
	StatusEffects.add(a, StatusEffects.Type.GUARD, 2)
	_check("Guard +2: effective_armor == base+2 (5)", a.effective_armor() == 5)
	_check("Guard stacks == 2", StatusEffects.get_stacks(a, StatusEffects.Type.GUARD) == 2)

	# Brittle Coat와 동시 보유 시 합산 확인 (Guard +, burn_armor_debuff -)
	a.burn_armor_debuff = 1
	_check("Guard(+2) and burn_armor_debuff(-1) combine: 3+2-1=4", a.effective_armor() == 4)

	# ─ 블록 B: Guard 상한 클램프 (MAX_STACK = 5) ──────────────────────────────
	print("\n-- B: Guard stack cap --")
	var b := _make_unit(10, 0)
	StatusEffects.add(b, StatusEffects.Type.GUARD, 10)
	_check("Guard clamps to MAX_STACK(5)", StatusEffects.get_stacks(b, StatusEffects.Type.GUARD) == 5)

	# ─ 블록 C: Guard 반격 (innate, 스택 소비 없음) ────────────────────────────
	print("\n-- C: apply_guard_counter — innate reflect --")
	var attacker := _make_unit(10, 0)
	var defender := _make_unit(10, 0)
	StatusEffects.add(defender, StatusEffects.Type.GUARD, 3)
	CardEffects.apply_guard_counter(attacker, defender)
	_check("counter = stacks(3) x 1: attacker STR 10-3=7", attacker.stats.strength == 7)
	_check("counter does not consume Guard stacks (still 3)", StatusEffects.get_stacks(defender, StatusEffects.Type.GUARD) == 3)

	# Guard 없는 유닛은 반격 없음
	var attacker2 := _make_unit(10, 0)
	var defender2 := _make_unit(10, 0)
	CardEffects.apply_guard_counter(attacker2, defender2)
	_check("no Guard: no counter damage", attacker2.stats.strength == 10)

	# ─ 블록 D: Thorn Armor — counter_damage_multiplier ────────────────────────
	print("\n-- D: Thorn Armor counter multiplier --")
	var td_attacker := _make_unit(10, 0)
	var td_defender := _make_unit(10, 0)
	StatusEffects.add(td_defender, StatusEffects.Type.GUARD, 3)
	var thorn := CardData.new()
	thorn.counter_damage_multiplier = 2.0
	td_defender.cards = [thorn]
	CardEffects.apply_guard_counter(td_attacker, td_defender)
	_check("Thorn Armor doubles counter: stacks(3) x 1 x 2 = 6, attacker STR 10-6=4", td_attacker.stats.strength == 4)

	# ─ 블록 E: Guard 반격이 치명적일 수 있음 ──────────────────────────────────
	print("\n-- E: lethal counter-damage --")
	var lethal_attacker := _make_unit(3, 0)
	var lethal_defender := _make_unit(10, 0)
	StatusEffects.add(lethal_defender, StatusEffects.Type.GUARD, 5)
	CardEffects.apply_guard_counter(lethal_attacker, lethal_defender)
	_check("overkill counter clamps STR to 0", lethal_attacker.stats.strength == 0)
	_check("attacker is_alive() false after lethal counter", not lethal_attacker.is_alive())

	# ─ 블록 F: Earthen Smite — on_attack_guard_self (attacker 자신에게 부여) ──
	print("\n-- F: on_attack_guard_self via apply_on_attack --")
	var smite_attacker := _make_unit(10, 0)
	var smite_target := _make_unit(10, 0)
	var smite := CardData.new()
	smite.on_attack_guard_self = 1
	smite_attacker.cards = [smite]
	CardEffects.apply_on_attack(smite_attacker, smite_target)
	_check("attacker gains Guard +1 (self, not target)", StatusEffects.get_stacks(smite_attacker, StatusEffects.Type.GUARD) == 1)
	_check("target gains no Guard", StatusEffects.get_stacks(smite_target, StatusEffects.Type.GUARD) == 0)
	# 반복 공격 시 누적
	CardEffects.apply_on_attack(smite_attacker, smite_target)
	_check("second attack: Guard accumulates to 2", StatusEffects.get_stacks(smite_attacker, StatusEffects.Type.GUARD) == 2)

	# ─ 최종 결과 ─────────────────────────────────────────────────────────────
	print("\n=== Result: %d PASS / %d FAIL ===" % [_pass, _fail])
	if _fail > 0:
		printerr(">>> SMOKE TEST FAILED — %d test(s) did not pass" % _fail)
		quit(1)
	else:
		print("All tests passed.")
		quit(0)
