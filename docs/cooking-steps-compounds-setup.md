# 자체제조(compounds) 조리법 — Supabase 셋업

이 SQL을 Supabase Dashboard → **SQL Editor**에서 1회 실행하면 됩니다.

```sql
-- 자체제조 조리법 컬럼 추가
ALTER TABLE compounds ADD COLUMN IF NOT EXISTS cooking_steps jsonb DEFAULT '[]';
```

## 사진 Storage

이미 1단계에서 만든 `recipe-images` 버킷을 그대로 사용합니다. 메뉴와 자체제조 사진이 섞이지 않도록 경로 접두사로 구분:

- 메뉴 사진: `recipe-images/menu_{menu_id}/{step}_{ts}.jpg`
- 자체제조 사진: `recipe-images/compound_{compound_id}/{step}_{ts}.jpg`

> ⓘ 1단계 후 업로드된 기존 메뉴 사진은 접두사 없는 옛 경로(`{menu_id}/...`)에 그대로 남아있고, 저장된 public URL로 계속 정상 표시됩니다. 신규 업로드부터 접두사 적용.

## menus.cooking_steps와의 관계

스키마는 동일 (`jsonb` 배열, 각 step은 `{step, heat, temp, tool, duration_sec, description, key_point, warning, photos}`). `normalizeCookingSteps()`로 동일하게 정규화.

## 통합 인쇄

메뉴 인쇄 미리보기에서 ☑️ "자체제조 조리법도 함께 인쇄"를 체크하면 본 메뉴 조리법 아래에 해당 메뉴 레시피에 포함된 자체제조들의 조리법이 섹션별로 추가 출력됩니다 (신입 교육용 통합 매뉴얼).

- 자체제조 조리법이 비어있어도 섹션은 표시되며 "조리법 미등록"으로 안내
- 자체제조 재료가 없는 메뉴는 체크박스 자체가 숨김
