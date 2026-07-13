extends Resource
class_name CardDrawConfig

## 카드 선택 화면의 등급 추첨 규칙을 담는 밸런싱 Resource.
## 모든 수치는 여기(.tres)에서 조정 — 코드 수정 없이 밸런싱 (feedback_code_style).

# ── 기본 등급 가중치 ──
# 합이 100일 필요 없음. 상대 비율로 정규화되어 사용된다.
@export var common_weight: float = 30.0
@export var rare_weight: float   = 60.0
@export var epic_weight: float   = 10.0

# ── 천장(피티) — Rare 대상 ──
# Rare가 미등장한 스테이지마다 rare_weight에 이 값을 가산 (소프트 천장).
@export var rare_pity_soft_bonus: float = 15.0
# 이 수 이상 Rare 미등장 시 다음 화면은 Rare 확정 (하드 천장).
@export var rare_pity_hard_cap: int = 3

# ── 에픽 조건부 가중 보정 ──
# Epic 롤 시, 전제조건을 충족한 조건부 에픽의 상대 가중 배수.
# 조건없는 에픽 및 이 배수를 못 받는 카드는 1.0으로 취급된다.
@export var epic_conditioned_weight_mult: float = 2.0

# ── 한 화면에 보여줄 카드 수 ──
@export var pick_count: int = 3
