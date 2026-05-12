-- 2026-05-12: menu_sales 중복 방지 (발주 예측 합산 오차 방지)
-- 동일 사용자의 동일 메뉴(menu_name)는 단 한 행만 허용.
-- 클라이언트도 in-flight 락 + 로드시 dedupe로 1차 방어하지만,
-- 다중 기기/네트워크 재시도 환경에서는 DB unique 제약이 필요.

-- 1) 기존 중복 정리: (user_id, menu_name)당 가장 최근 updated_at만 남기고 삭제.
DELETE FROM menu_sales m1 USING menu_sales m2
  WHERE m1.user_id = m2.user_id
    AND COALESCE(m1.menu_name,'') = COALESCE(m2.menu_name,'')
    AND (m1.updated_at < m2.updated_at
         OR (m1.updated_at = m2.updated_at AND m1.id < m2.id));

-- 2) 유니크 제약 추가
ALTER TABLE menu_sales
  ADD CONSTRAINT menu_sales_user_menuname_unique UNIQUE (user_id, menu_name);
