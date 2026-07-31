## 헤드리스 스모크 테스트 — Earth G1+G2+G3 (Guard 기반/소비/반응 슬라이스) 로직 검증
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
	print("\n=== Earth G1+G2+G3 (Guard) Smoke Test ===\n")

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

	# ─ 블록 G: Crush — attacker 자신의 Guard 소비 → target 방어 무시 버스트 ────
	print("\n-- G: Crush (on_attack_consume_guard_self) --")
	var crush_attacker := _make_unit(10, 0)
	var crush_target := _make_unit(20, 5)
	StatusEffects.add(crush_attacker, StatusEffects.Type.GUARD, 3)
	var crush := CardData.new()
	crush.on_attack_consume_guard_self = 2
	crush.on_attack_guard_burst_per_stack = 3
	crush_attacker.cards = [crush]
	CardEffects.apply_on_attack(crush_attacker, crush_target)
	_check("Crush consumes 2 of 3: attacker Guard now 1", StatusEffects.get_stacks(crush_attacker, StatusEffects.Type.GUARD) == 1)
	_check("Crush burst = 2x3=6, armor ignored: target STR 20-6=14", crush_target.stats.strength == 14)

	# ─ 블록 H: 전량 소비 (Cataclysm 패턴) ──────────────────────────────────────
	print("\n-- H: consume-all (Cataclysm pattern) --")
	var cat_attacker := _make_unit(10, 0)
	var cat_target := _make_unit(40, 5)
	StatusEffects.add(cat_attacker, StatusEffects.Type.GUARD, 5)
	var cataclysm := CardData.new()
	cataclysm.on_attack_consume_all_guard_self = true
	cataclysm.on_attack_guard_burst_per_stack = 6
	cat_attacker.cards = [cataclysm]
	CardEffects.apply_on_attack(cat_attacker, cat_target)
	_check("Cataclysm consumes all 5: attacker Guard now 0", StatusEffects.get_stacks(cat_attacker, StatusEffects.Type.GUARD) == 0)
	_check("Cataclysm burst = 5x6=30, armor ignored: target STR 40-30=10", cat_target.stats.strength == 10)

	# ─ 블록 I: Awakening of Earth — Guard 소비에 반응해 영구 AMR 획득 ─────────
	print("\n-- I: Awakening of Earth (on_guard_consumed_gain_armor) --")
	var awaken_attacker := _make_unit(10, 2)
	var awaken_target := _make_unit(20, 0)
	StatusEffects.add(awaken_attacker, StatusEffects.Type.GUARD, 3)
	var crush2 := CardData.new()
	crush2.on_attack_consume_guard_self = 2
	crush2.on_attack_guard_burst_per_stack = 3
	var awakening := CardData.new()
	awakening.on_guard_consumed_gain_armor = 1
	awaken_attacker.cards = [crush2, awakening]
	CardEffects.apply_on_attack(awaken_attacker, awaken_target)
	_check("Awakening: 2 consumed x 1 = permanent AMR +2 (base 2 -> 4)", awaken_attacker.stats.armor == 4)
	_check("Crush burst still applies alongside Awakening: target STR 20-6=14", awaken_target.stats.strength == 14)

	# ─ 블록 J: Fracture — [5] 소비 이후 잔여 Guard로 target AMR 영구 차감 ─────
	print("\n-- J: Fracture (on_attack_armor_shred_by_guard) --")
	var fr_attacker := _make_unit(10, 0)
	var fr_target := _make_unit(20, 8)
	StatusEffects.add(fr_attacker, StatusEffects.Type.GUARD, 3)
	var fracture := CardData.new()
	fracture.on_attack_armor_shred_by_guard = true
	fr_attacker.cards = [fracture]
	CardEffects.apply_on_attack(fr_attacker, fr_target)
	_check("Fracture alone (no consume card): target AMR 8-3=5", fr_target.stats.armor == 5)

	# 순서 규칙: 같은 attacker가 Crush(소비)도 함께 들고 있으면 Fracture는 소비 '이후' 값을 읽는다.
	var fr2_attacker := _make_unit(10, 0)
	var fr2_target := _make_unit(30, 8)
	StatusEffects.add(fr2_attacker, StatusEffects.Type.GUARD, 5)
	var crush3 := CardData.new()
	crush3.on_attack_consume_guard_self = 2
	crush3.on_attack_guard_burst_per_stack = 3
	var fracture2 := CardData.new()
	fracture2.on_attack_armor_shred_by_guard = true
	fr2_attacker.cards = [crush3, fracture2]
	CardEffects.apply_on_attack(fr2_attacker, fr2_target)
	_check("order rule: Crush consumes 2 (5->3); Fracture reads POST-consume 3, not pre-consume 5: target AMR 8-3=5", fr2_target.stats.armor == 5)
	_check("order rule: Crush burst also applied (2x3=6): target STR 30-6=24", fr2_target.stats.strength == 24)

	# ─ 블록 K: Center of Gravity — get_outgoing_multiplier() ─────────────────
	print("\n-- K: Center of Gravity (get_outgoing_multiplier) --")
	var cog_attacker := _make_unit(10, 0)
	var cog := CardData.new()
	cog.on_guard_threshold_dmg_bonus = 0.2
	cog.on_guard_threshold_dmg_bonus_min = 4
	cog_attacker.cards = [cog]
	StatusEffects.add(cog_attacker, StatusEffects.Type.GUARD, 3)
	_check("Guard(3) < min(4): outgoing multiplier == 1.0", is_equal_approx(CardEffects.get_outgoing_multiplier(cog_attacker), 1.0))
	StatusEffects.add(cog_attacker, StatusEffects.Type.GUARD, 1)
	_check("Guard(4) >= min(4): outgoing multiplier == 1.2", is_equal_approx(CardEffects.get_outgoing_multiplier(cog_attacker), 1.2))

	# 여러 장 보유 시 곱셈 합산 확인
	var cog_attacker2 := _make_unit(10, 0)
	var cog2a := CardData.new()
	cog2a.on_guard_threshold_dmg_bonus = 0.2
	cog2a.on_guard_threshold_dmg_bonus_min = 4
	var cog2b := CardData.new()
	cog2b.on_guard_threshold_dmg_bonus = 0.2
	cog2b.on_guard_threshold_dmg_bonus_min = 4
	cog_attacker2.cards = [cog2a, cog2b]
	StatusEffects.add(cog_attacker2, StatusEffects.Type.GUARD, 4)
	_check("two Center of Gravity cards stack multiplicatively: 1.2 x 1.2 = 1.44", is_equal_approx(CardEffects.get_outgoing_multiplier(cog_attacker2), 1.44))

	# ─ 블록 L: Bedrock — get_incoming_multiplier() (target 자신의 Guard 기준) ─
	print("\n-- L: Bedrock (on_guard_threshold_dmg_reduction) --")
	var bed_attacker := _make_unit(10, 0)
	var bed_target := _make_unit(10, 0)
	var bedrock := CardData.new()
	bedrock.on_guard_threshold_dmg_reduction = 0.2
	bedrock.on_guard_threshold_dmg_reduction_min = 4
	bed_target.cards = [bedrock]
	StatusEffects.add(bed_target, StatusEffects.Type.GUARD, 3)
	_check("target Guard(3) < min(4): incoming multiplier == 1.0", is_equal_approx(CardEffects.get_incoming_multiplier(bed_attacker, bed_target), 1.0))
	StatusEffects.add(bed_target, StatusEffects.Type.GUARD, 1)
	_check("target Guard(4) >= min(4): incoming multiplier == 0.8", is_equal_approx(CardEffects.get_incoming_multiplier(bed_attacker, bed_target), 0.8))

	# F2(Ember Barrier류)와 G3(Bedrock)이 함께 있으면 곱셈 합산되는지 확인
	var bed_attacker2 := _make_unit(10, 0)
	StatusEffects.add(bed_attacker2, StatusEffects.Type.BURN, 1)
	var bed_target2 := _make_unit(10, 0)
	var ember_barrier := CardData.new()
	ember_barrier.on_hit_dmg_reduction_burning = 0.3
	var bedrock2 := CardData.new()
	bedrock2.on_guard_threshold_dmg_reduction = 0.2
	bedrock2.on_guard_threshold_dmg_reduction_min = 4
	bed_target2.cards = [ember_barrier, bedrock2]
	StatusEffects.add(bed_target2, StatusEffects.Type.GUARD, 4)
	_check("Ember Barrier(0.7) x Bedrock(0.8) = 0.56 combined", is_equal_approx(CardEffects.get_incoming_multiplier(bed_attacker2, bed_target2), 0.56))

	# ─ 블록 M: Retaliatory Strike — 반격 성공 → 다음 공격 outgoing multiplier ─
	print("\n-- M: Retaliatory Strike (guard_counter_bonus_pending) --")
	var rs_attacker := _make_unit(10, 0)
	var rs_defender := _make_unit(10, 0)
	var retaliatory := CardData.new()
	retaliatory.on_retaliation_dmg_bonus = 0.5
	rs_defender.cards = [retaliatory]
	StatusEffects.add(rs_defender, StatusEffects.Type.GUARD, 3)
	_check("before counter: guard_counter_bonus_pending == false", not rs_defender.guard_counter_bonus_pending)
	CardEffects.apply_guard_counter(rs_attacker, rs_defender)
	_check("counter landed (attacker STR 10-3=7)", rs_attacker.stats.strength == 7)
	_check("after successful counter: guard_counter_bonus_pending == true", rs_defender.guard_counter_bonus_pending)
	_check("defender's next-attack outgoing multiplier == 1.5", is_equal_approx(CardEffects.get_outgoing_multiplier(rs_defender), 1.5))
	_check("get_outgoing_multiplier() is pure (does not reset the flag): still true", rs_defender.guard_counter_bonus_pending)
	_check("calling get_outgoing_multiplier() again still returns 1.5", is_equal_approx(CardEffects.get_outgoing_multiplier(rs_defender), 1.5))

	# Guard 없어서 반격 자체가 안 나면 플래그도 안 세워짐
	var rs_attacker2 := _make_unit(10, 0)
	var rs_defender2 := _make_unit(10, 0)
	rs_defender2.cards = [retaliatory]
	CardEffects.apply_guard_counter(rs_attacker2, rs_defender2)
	_check("no Guard, no counter: guard_counter_bonus_pending stays false", not rs_defender2.guard_counter_bonus_pending)
	_check("no pending: outgoing multiplier == 1.0", is_equal_approx(CardEffects.get_outgoing_multiplier(rs_defender2), 1.0))

	# ─ 최종 결과 ─────────────────────────────────────────────────────────────
	print("\n=== Result: %d PASS / %d FAIL ===" % [_pass, _fail])
	if _fail > 0:
		printerr(">>> SMOKE TEST FAILED — %d test(s) did not pass" % _fail)
		quit(1)
	else:
		print("All tests passed.")
		quit(0)
