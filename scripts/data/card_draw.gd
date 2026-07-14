class_name CardDraw

## 카드 등급 추첨 + 후보 필터링 전담 순수 static 헬퍼.
##
## 이 클래스는 게임 상태(GameState 등)를 직접 읽지 않는다.
## 모든 입력은 인수로 주입 — 독립 테스트 가능, 사이드 이펙트 없음.
##
## 호출 순서:
##   1. roll_tier()   → 이번 화면의 등급 결정 (천장 포함)
##   2. draw()        → 그 등급에서 카드 경로 배열 반환 (에픽 게이팅 포함)


## 소프트+하드 천장을 반영해 등급 1개를 뽑는다.
##
## stages_since_rare: GameState.stages_since_rare
## rng: 호출자가 randomize()한 RandomNumberGenerator
static func roll_tier(
		cfg: CardDrawConfig,
		stages_since_rare: int,
		rng: RandomNumberGenerator) -> int:

	# 하드 천장: 연속 미등장이 cap에 달하면 Rare 확정
	if stages_since_rare >= cfg.rare_pity_hard_cap:
		return CardData.Tier.RARE

	# 소프트 천장: 미등장 스테이지만큼 Rare 가중치 누적
	var w_common: float = cfg.common_weight
	var w_rare: float   = cfg.rare_weight + stages_since_rare * cfg.rare_pity_soft_bonus
	var w_epic: float   = cfg.epic_weight
	var total: float    = w_common + w_rare + w_epic

	var roll: float = rng.randf() * total
	if roll < w_common:
		return CardData.Tier.COMMON
	elif roll < w_common + w_rare:
		return CardData.Tier.RARE
	else:
		return CardData.Tier.EPIC


## 특정 등급에서 선택 가능한 카드 목록을 반환한다 (에픽 조건 게이팅 포함).
##
## pool: 전체 CardData 배열
## tier: roll_tier()가 결정한 등급
## owned_ids: GameState.active_cards에서 추출한 보유 카드 id 배열
##
## 반환: 이번 화면에 등장 가능한 CardData 배열
static func eligible(
		pool: Array[CardData],
		tier: int,
		owned_ids: Array[String]) -> Array[CardData]:

	var result: Array[CardData] = []
	for card in pool:
		if card.tier != tier:
			continue
		# 이미 보유한 카드는 후보에서 제외
		if card.id in owned_ids:
			continue
		# Epic 조건 게이팅: prerequisite_card_ids가 비어있지 않으면 모두 보유해야 통과
		if tier == CardData.Tier.EPIC and not card.prerequisite_card_ids.is_empty():
			var all_met: bool = true
			for req_id in card.prerequisite_card_ids:
				if req_id not in owned_ids:
					all_met = false
					break
			if not all_met:
				continue
		result.append(card)
	return result


## 등급 롤 → 후보 필터 → 가중 비복원 추출 → 카드 경로 배열 반환.
##
## pool: 전체 CardData 배열
## tier: roll_tier()가 반환한 등급
## owned_ids: 보유 카드 id 배열 (에픽 전제 판정 + 중복 제외)
## rng: 호출자가 randomize()한 RandomNumberGenerator
##
## 반환: 선택된 카드들의 res:// 경로 배열 (최대 cfg.pick_count개. 후보 부족 시 그보다 적을 수 있음)
static func draw(
		cfg: CardDrawConfig,
		pool: Array[CardData],
		tier: int,
		owned_ids: Array[String],
		rng: RandomNumberGenerator) -> Array[String]:

	# GDScript 4는 Array[EnumType]을 지원하지 않으므로 int 배열 사용.
	var active_tier: int = tier
	var candidates: Array[CardData] = eligible(pool, active_tier, owned_ids)

	# 폴백: 뽑힌 등급 후보가 0장이면 Rare → Common → Epic 순으로 대체
	if candidates.is_empty():
		var fallback_order: Array[int] = [
			CardData.Tier.RARE,
			CardData.Tier.COMMON,
			CardData.Tier.EPIC,
		]
		for fallback_tier: int in fallback_order:
			if fallback_tier == active_tier:
				continue  # 이미 시도한 등급 건너뜀
			candidates = eligible(pool, fallback_tier, owned_ids)
			if not candidates.is_empty():
				active_tier = fallback_tier
				break

	if candidates.is_empty():
		return []  # 전체 풀이 비어있는 극단적 상황

	# 가중 비복원 추출
	# Epic일 때: 조건부-충족 카드는 epic_conditioned_weight_mult 배 가중 (전제가 있고 충족된 경우)
	# Common/Rare: 균등 가중 (1.0)
	var result_paths: Array[String] = []
	var remaining: Array[CardData] = candidates.duplicate()
	var picks: int = mini(cfg.pick_count, remaining.size())

	for _i in range(picks):
		var weights: Array[float] = []
		for card in remaining:
			if active_tier == CardData.Tier.EPIC and not card.prerequisite_card_ids.is_empty():
				weights.append(cfg.epic_conditioned_weight_mult)
			else:
				weights.append(1.0)

		var total_w: float = 0.0
		for w in weights:
			total_w += w
		var roll: float = rng.randf() * total_w
		var cumulative: float = 0.0
		var chosen_idx: int = 0
		for idx in range(weights.size()):
			cumulative += weights[idx]
			if roll < cumulative:
				chosen_idx = idx
				break

		result_paths.append(remaining[chosen_idx].resource_path)
		remaining.remove_at(chosen_idx)

	return result_paths
