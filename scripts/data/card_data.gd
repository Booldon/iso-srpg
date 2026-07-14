extends Resource
class_name CardData

# Element: 카드가 속한 원소. NONE은 무속성(agnostic) 카드에 사용.
enum Element { NONE, FIRE, ICE, EARTH }

# Tier: 카드 등급. COMMON/RARE/EPIC 순서로 int 값 0/1/2 고정 (직렬화 키로 사용됨).
enum Tier { COMMON, RARE, EPIC }

@export var id: String = ""               # 고유 식별자. snake_case. 예: "ember", "kindling"
@export var title: String = ""            # 표시 이름 (한국어 가능). 예: "불씨"
@export var description: String = ""      # 카드 효과 설명 (UI 표시용 자연어)
@export var element: Element = Element.FIRE
@export var tier: Tier = Tier.RARE

# --- 에픽 전제조건 ---
# 비어있으면 조건없는 에픽(Epic 롤 시 항상 후보).
# 채워져 있으면 이 id들의 카드를 모두 보유해야 카드 풀에 등장. (tier가 EPIC일 때만 체크됨)
@export var prerequisite_card_ids: Array[String] = []

# --- 공격 시 Burn 부여 (Burn 슬라이스 — 구현됨) ---
# 일반 공격(resolve_attack) 직후 CardEffects.apply_on_attack()이 읽는 필드.
@export var on_attack_burn: int = 0
# true이면 대상의 Burn 스택이 0일 때 이 카드의 on_attack_burn을 적용하지 않음 (Kindling 규칙).
# false이면 대상의 Burn 스택과 무관하게 항상 적용.
@export var on_attack_burn_requires_burning: bool = false

# --- Detonation / burst (F1 슬라이스 — 구현됨) ---
# 이 값보다 target Burn 스택이 적으면 아래 detonation 효과 전체 발동 안 함. 0 = 게이트 없음.
@export var on_attack_min_burn: int = 0
# 소비할 Burn 스택 수. on_attack_consume_all_burn이 true면 이 값은 무시됨.
@export var on_attack_consume_burn: int = 0
# true이면 대상 Burn 전량 소비 (Grand Detonation 스타일). false이면 consume_burn 수만큼.
@export var on_attack_consume_all_burn: bool = false
# 소비한 스택 1개당 방어 무시 STR 데미지.
@export var on_attack_burst_per_stack: int = 0
# 소비 없이 고정으로 방어 무시 보너스 데미지 (Overheat형). min_burn 게이트 통과 후 발동.
@export var on_attack_burst_flat: int = 0

# --- Solar / temp STR (F1 슬라이스 — 구현됨) ---
# 전투 시작 시(배치 직후) 이 카드를 보유한 유닛 자신에게 부여하는 임시 Strength.
# temp_strength 버퍼에 쌓임 — 피해 시 base STR보다 먼저 깎임.
@export var battle_start_temp_str_self: int = 0

# --- 전투 시작 스탯 보너스 (Common 슬라이스 — 구현됨) ---
# 배치 직후 unit.stats에 직접 합산. 음수면 패널티 (Trade-off 카드용).
# base STR 수정이므로 temp_strength와 달리 피해 시 일반 차감 규칙을 따름.
@export var battle_start_str_bonus:   int = 0
@export var battle_start_armor_bonus: int = 0
@export var battle_start_spd_bonus:   int = 0
@export var battle_start_move_bonus:  int = 0

# --- 피격 반응 효과 (F2 슬라이스 — 구현됨) ---
# 이 카드를 보유한 유닛이 맞을 때 발동. target(피격자)의 cards에서 읽힘.
# 공격 직후 CardEffects.apply_on_hit() / get_incoming_multiplier() 에서 처리.

# 피격 시 공격자에게 Burn 부여. 0 = no-op. (Flame Retort: 2)
@export var on_hit_burn_attacker: int = 0

# 피격 시 공격자가 Burn 상태이면 받는 피해 감소 비율 (0.0~1.0). 0.3 = 30% 감소.
# get_incoming_multiplier()가 곱셈적으로 합산 → Combat.resolve_attack(dmg_mult)에 전달.
# 0.0 = no-op. (Ember Barrier: 0.3)
@export var on_hit_dmg_reduction_burning: float = 0.0

# 이 카드를 보유한 유닛에 인접한 아군이 피격될 때, 그 공격자에게 Burn 부여.
# 0 = no-op. 처리 책임: grid_manager._apply_ashen_ward(). (Ashen Ward: 2)
@export var on_adjacent_ally_hit_burn_attacker: int = 0
