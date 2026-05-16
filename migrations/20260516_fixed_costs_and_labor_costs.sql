-- 2026-05-16 migration
-- 1) fixed_costs  : 고정비 입력·저장 (입력 그릇만 — 분석/계산 미연동)
-- 2) labor_costs  : 인건비 입력·저장 (입력 그릇만 — 4대보험 사장부담금·세금 자동계산 없음)
--
-- 공통 컨벤션
--  · id는 uuid PK, user_id로 RLS 격리 (auth.uid() = user_id)
--  · 부가세/근무형태는 CHECK 제약으로 값 무결성 보장 (식재료 tax_type과 동일 패턴)
--  · 금액은 numeric (원 단위 정수가 기본이지만, 부가세 분리 등 소수 가능성 대비)
--  · NOTE: CREATE POLICY는 IF NOT EXISTS 미지원 → DROP-then-CREATE 패턴으로 idempotent 유지
--          (기존 20260511_menu_sales_and_target_rate.sql 컨벤션과 동일)

------------------------------------------------------------
-- 1) fixed_costs (고정비)
------------------------------------------------------------
-- 항목: 임차료, 통신비, 보험료, 관리비 등 매월 반복 지출
-- tax_type:
--   'taxable' = 과세  (총금액에 부가세 10/110 포함되어 있다고 간주)
--   'exempt'  = 면세·부가세없음 (총금액=공급가, 부가세 0)
-- amount: 사용자가 입력한 "총금액" 원본. 공급가/부가세 분리 표시는 화면에서만 계산.

CREATE TABLE IF NOT EXISTS fixed_costs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users,
  name text NOT NULL,
  tax_type text NOT NULL DEFAULT 'exempt'
    CHECK (tax_type IN ('taxable', 'exempt')),
  amount numeric NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE fixed_costs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user owns row" ON fixed_costs;
CREATE POLICY "user owns row" ON fixed_costs
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

------------------------------------------------------------
-- 2) labor_costs (인건비)
------------------------------------------------------------
-- name: 직원 이름
-- position: 직급/직책 (홀매니저, 주방장 등) — 빈 값 허용
-- salary: 실지급액 (원). 4대보험 사장부담금/세금 자동계산은 이번 범위 아님.
-- employment_type:
--   'insurance'   = 4대보험 가입자 (정규직)
--   'withholding' = 원천징수 (3.3% 사업소득자 — 단기/프리랜서)

CREATE TABLE IF NOT EXISTS labor_costs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users,
  name text NOT NULL,
  position text DEFAULT '',
  salary numeric NOT NULL DEFAULT 0,
  employment_type text NOT NULL DEFAULT 'withholding'
    CHECK (employment_type IN ('insurance', 'withholding')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE labor_costs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user owns row" ON labor_costs;
CREATE POLICY "user owns row" ON labor_costs
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

------------------------------------------------------------
-- 검증 쿼리 (실행 후 확인용)
------------------------------------------------------------
-- SELECT table_name FROM information_schema.tables
--   WHERE table_name IN ('fixed_costs', 'labor_costs');
-- → 두 행이 모두 나오면 생성 성공
--
-- SELECT polname, polrelid::regclass FROM pg_policy
--   WHERE polrelid IN ('fixed_costs'::regclass, 'labor_costs'::regclass);
-- → 각 테이블에 "user owns row" 정책이 1줄씩 있어야 함

------------------------------------------------------------
-- 롤백 SQL (문제 발생 시 되돌리기)
------------------------------------------------------------
-- DROP TABLE IF EXISTS fixed_costs CASCADE;
-- DROP TABLE IF EXISTS labor_costs CASCADE;
