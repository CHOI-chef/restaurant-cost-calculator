-- 2026-05-13 migration: 메뉴 조리 단계 + 사진 업로드
-- 1) menus.cooking_steps jsonb 컬럼 추가 — 조리 단계 배열 저장
-- 2) recipe-images storage bucket 생성 — 단계별 사진 (public read)
-- 3) storage.objects RLS — 본인 user_id 폴더 안에서만 쓰기 가능, 읽기는 누구나(public bucket)

-- 1) cooking_steps 컬럼
ALTER TABLE menus ADD COLUMN IF NOT EXISTS cooking_steps jsonb DEFAULT '[]'::jsonb;

-- 2) recipe-images public bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('recipe-images', 'recipe-images', true)
ON CONFLICT (id) DO NOTHING;

-- 3) storage.objects RLS — 본인 폴더({user_id}/...)에만 INSERT/UPDATE/DELETE 가능
--    SELECT는 public bucket이라 anon 키로도 URL 직접 접근 가능
DROP POLICY IF EXISTS "recipe-images user owns folder insert" ON storage.objects;
CREATE POLICY "recipe-images user owns folder insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'recipe-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "recipe-images user owns folder update" ON storage.objects;
CREATE POLICY "recipe-images user owns folder update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'recipe-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "recipe-images user owns folder delete" ON storage.objects;
CREATE POLICY "recipe-images user owns folder delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'recipe-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- public bucket의 SELECT 정책 — anon/authenticated 모두 read 가능
DROP POLICY IF EXISTS "recipe-images public read" ON storage.objects;
CREATE POLICY "recipe-images public read" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'recipe-images');
