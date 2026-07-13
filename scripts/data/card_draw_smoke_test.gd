## 헤드리스 스모크 테스트 — CardDraw 로직 검증 (에디터에서 직접 실행)
## 실행: Godot 에디터 > 이 파일 열기 > 우상단 "실행" 아이콘 (또는 Ctrl+Shift+X)
## 테스트 프레임워크(GUT) 없이 print+assert_로 동작. 실패 시 에러 출력.
extends SceneTree

func _init() -> void:
	print("\n=== CardDraw Smoke Test ===")
	var cfg := CardDrawConfig.new()
	cfg.common_weight         = 30.0
	cfg.rare_weight           = 60.0
	cfg.epic_weight           = 10.0
	cfg.rare_pity_soft_bonus  = 15.0
	cfg.rare_pity_hard_cap    = 3
	cfg.epic_conditioned_weight_mult = 2.0
	cfg.pick_count            = 3

	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # 고정 시드로 재현 가능

	# ─ 테스트 A: 하드 천장 ─
	var tier := CardDraw.roll_tier(cfg, 3, rng)
	assert(tier == CardData.Tier.RARE, "A fail: stages_since_rare=3 이면 Rare 확정")
	print("A pass: 하드 천장(stages_since_rare=3) → RARE")

	# ─ 테스트 B: 소프트 천장 — 시드 반복으로 분포 확인 ─
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 0
	var counts := {CardData.Tier.COMMON: 0, CardData.Tier.RARE: 0, CardData.Tier.EPIC: 0}
	var n := 1000
	for _i in range(n):
		var t := CardDraw.roll_tier(cfg, 1, rng2)  # stages_since_rare=1 → rare=75
		counts[t] += 1
	# stages_since_rare=1: rare_weight=75, total=115. Rare 기대치 ≈65.2%
	var rare_pct: float = counts[CardData.Tier.RARE] / float(n) * 100.0
	assert(rare_pct > 55.0 and rare_pct < 80.0,
		"B fail: stages_since_rare=1 Rare 비율이 예상 범위(55~80) 밖: %.1f%%" % rare_pct)
	print("B pass: 소프트 천장(stages_since_rare=1) Rare 비율 = %.1f%% (기대 ~65%%)" % rare_pct)

	# ─ 테스트 C: eligible — 조건없는 에픽 항상 통과 ─
	var epic_free := CardData.new()
	epic_free.id = "epic_free"
	epic_free.tier = CardData.Tier.EPIC
	epic_free.prerequisite_card_ids = []

	var pool_c: Array[CardData] = [epic_free]
	var found_c := CardDraw.eligible(pool_c, CardData.Tier.EPIC, [])
	assert(found_c.size() == 1, "C fail: 조건없는 에픽은 owned_ids 무관하게 통과해야 함")
	print("C pass: 조건없는 에픽 → 보유 카드 없어도 후보 등장")

	# ─ 테스트 D: eligible — 조건부 에픽, 전제 미충족 → 제외 ─
	var epic_cond := CardData.new()
	epic_cond.id = "epic_cond"
	epic_cond.tier = CardData.Tier.EPIC
	epic_cond.prerequisite_card_ids = ["ember"]

	var pool_d: Array[CardData] = [epic_cond]
	var found_d := CardDraw.eligible(pool_d, CardData.Tier.EPIC, [])
	assert(found_d.is_empty(), "D fail: 전제 미충족 에픽은 후보에서 제외돼야 함")
	print("D pass: 전제 미충족 조건부 에픽 → 후보 제외")

	# ─ 테스트 E: eligible — 조건부 에픽, 전제 충족 → 포함 ─
	var found_e := CardDraw.eligible(pool_d, CardData.Tier.EPIC, ["ember"])
	assert(found_e.size() == 1, "E fail: 전제 충족 시 조건부 에픽 후보 포함")
	print("E pass: 전제 충족 조건부 에픽 → 후보 포함")

	# ─ 테스트 F: draw — 후보 0장이면 폴백 ─
	# Epic 풀이 비어있고, Rare 카드만 있을 때 → Epic 롤이어도 Rare로 폴백
	var rare_card := CardData.new()
	rare_card.id = "rare_only"
	rare_card.tier = CardData.Tier.RARE
	rare_card.resource_path = "res://data/cards/rare_only.tres"  # 가상 경로
	var pool_f: Array[CardData] = [rare_card]
	var rng_f := RandomNumberGenerator.new()
	rng_f.seed = 1
	# draw()에서 resource_path를 직접 추가하므로 실제 파일 필요 없음 — 경로만 반환
	var picks_f := CardDraw.draw(cfg, pool_f, CardData.Tier.EPIC, [], rng_f)
	assert(picks_f.size() == 1, "F fail: 폴백 후 Rare 카드 1장 반환해야 함")
	print("F pass: Epic 후보 0장 → Rare 폴백으로 카드 1장 반환")

	# ─ 테스트 G: draw — pick_count보다 후보가 적으면 있는 만큼만 ─
	var card_g1 := CardData.new(); card_g1.tier = CardData.Tier.COMMON; card_g1.resource_path = "res://g1.tres"
	var card_g2 := CardData.new(); card_g2.tier = CardData.Tier.COMMON; card_g2.resource_path = "res://g2.tres"
	var pool_g: Array[CardData] = [card_g1, card_g2]
	var rng_g := RandomNumberGenerator.new(); rng_g.seed = 2
	var picks_g := CardDraw.draw(cfg, pool_g, CardData.Tier.COMMON, [], rng_g)
	assert(picks_g.size() == 2, "G fail: 후보 2장이면 2장만 반환해야 함(pick_count=3이어도)")
	print("G pass: 후보 2장, pick_count=3 → 2장만 반환")

	print("\n=== 전체 통과 ===")
	quit()
