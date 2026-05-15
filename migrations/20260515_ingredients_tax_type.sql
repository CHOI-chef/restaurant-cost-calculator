-- 부가세 작업 2단계: 식재료 테이블에 부가세 구분 컬럼 추가
-- 작성: 2026-05-15
-- 목적: 면세(1차 농수축산물) / 과세(가공식품·공산품) 구분
-- 기본값: 'exempt' (면세) — 기존 행 자동 채움
-- 안전성: 기존 데이터 손상 없음. NOT NULL + DEFAULT 조합으로 모든 행이 자동으로 'exempt' 됨.

ALTER TABLE ingredients
  ADD COLUMN tax_type text NOT NULL DEFAULT 'exempt'
  CHECK (tax_type IN ('taxable', 'exempt'));

-- 검증 쿼리 (실행 후 결과 확인용)
-- SELECT tax_type, COUNT(*) FROM ingredients GROUP BY tax_type;
-- → 모든 기존 행이 'exempt'로 채워졌는지 확인

-- 롤백 SQL (문제 발생 시 되돌리기)
-- ALTER TABLE ingredients DROP COLUMN tax_type;
