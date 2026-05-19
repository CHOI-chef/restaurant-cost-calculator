-- 2026-05-18 식재료에 수율 카테고리 / 손질 상태 컬럼 추가
-- ⚠️ 실행 전: 브라우저 자동 번역 OFF 필수 (한글 변환 시 SQL 오류)
-- ⚠️ 이 마이그레이션은 컬럼 추가만 하며, 기존 데이터는 건드리지 않습니다.
-- ⚠️ 기존 식재료의 waste_rate 값은 그대로 보존됩니다.
-- ⚠️ yield_category 기본값 '기타'를 받아 기존 행은 카테고리 매핑의 영향을 받지 않습니다.

ALTER TABLE ingredients
  ADD COLUMN IF NOT EXISTS yield_category text DEFAULT '기타';

ALTER TABLE ingredients
  ADD COLUMN IF NOT EXISTS prep_state text DEFAULT '';

-- 기존 NULL 행에 대해 안전망: 빈 값/NULL을 '기타'로 채움 (default 미적용 행 대비)
UPDATE ingredients SET yield_category = '기타' WHERE yield_category IS NULL OR yield_category = '';
UPDATE ingredients SET prep_state = '' WHERE prep_state IS NULL;

-- 검증 쿼리 (실행 후 information_schema에서 컬럼 2개 확인)
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'ingredients'
--   AND column_name IN ('yield_category','prep_state');
