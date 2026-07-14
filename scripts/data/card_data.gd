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

# --- AoE + on-death 전이 (F3 슬라이스 — 구현됨) ---
# splash 대상 = target + target에 인접한 살아있는 적 (grid_manager._splash_targets() 계산).

# 공격 시 splash 대상 각각에 Burn 부여 (Conflagration: 1).
@export var on_attack_aoe_burn: int = 0

# true면 공격 시 splash 대상 각각의 Burn을 MAX_STACK까지 충전 (Wildfire Storm 1단계).
@export var on_attack_aoe_fill_max: bool = false

# > 0이면 공격 시, AoE Burn 처리 후, Burn 보유한 살아있는 적 전체에 방어 무시 STR 데미지 (Wildfire Storm 2단계).
@export var on_attack_aoe_burst_all_burning: int = 0

# true면 불붙은 적이 사망할 때 남은 스택 절반(올림)을 인접 살아있는 적 하나에 전이 (Ember Trace).
# 처리 책임: grid_manager._sweep_deaths() → CardEffects.transfer_burn_on_death().
@export var on_burn_kill_transfer_stacks: bool = false

# --- F4 틱 수정자 (신규) ---
# White Heat: 공격 시 대상의 다음 Burn 틱 데미지에 곱할 배수. 틱 적용 후 즉시 1.0으로 리셋.
# 1.0이면 no-op. 처리: apply_on_attack() [3] 블록 → target.burn_tick_mult_next = 이 값.
@export var on_attack_burn_tick_multiplier: float = 1.0

# Smolder: 공격 시 대상의 자연 Burn 감쇠를 2턴에 1회로 늦춤.
# false이면 no-op. 처리: apply_on_attack() [3] 블록 → target.burn_decay_slowed = true.
@export var on_attack_burn_decay_slow: bool = false

# High Density: 보유 시 전투 시작 시 모든 유닛의 Burn 상한을 이 값으로 올림 (예: 7).
# 0이면 no-op (기본 MAX_STACK=5 유지). grid_manager._setup_burn_caps()가 처리.
# 여러 카드가 있으면 최댓값 적용.
@export var on_attack_burn_max_override: int = 0

# Brittle Coat: Burn 스택이 임계 이상인 적의 유효 AMR을 지속 차감하는 양 (예: 2).
# 0이면 no-op. 처리 책임: grid_manager._refresh_burn_armor_debuffs() → enemy.burn_armor_debuff 갱신.
@export var on_burn_threshold_armor_debuff: int = 0

# Brittle Coat 발동 최소 Burn 스택. get_stacks(enemy, BURN) >= 이 값이면 디버프 활성.
# on_burn_threshold_armor_debuff == 0이면 이 값은 무시됨.
@export var on_burn_threshold_armor_min: int = 3
