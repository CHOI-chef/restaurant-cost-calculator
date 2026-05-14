# 조리 단계 + 사진 업로드 — Supabase 셋업

이 SQL은 Supabase Dashboard → **SQL Editor**에서 1회 실행하면 됩니다.

> ⚠️ 재실행 주의: PostgreSQL은 `CREATE POLICY`에 `IF NOT EXISTS`를 지원하지 않습니다. 이미 같은 이름의 정책이 있다면 먼저 `DROP POLICY IF EXISTS "정책이름" ON storage.objects;`로 삭제 후 재생성하세요.

```sql
-- recipe-images 버킷 생성 (public)
INSERT INTO storage.buckets (id, name, public)
VALUES ('recipe-images', 'recipe-images', true)
ON CONFLICT DO NOTHING;

-- 누구나 읽기 허용 (public 버킷이므로)
CREATE POLICY "recipe-images public read"
ON storage.objects FOR SELECT
USING (bucket_id = 'recipe-images');

-- 로그인 사용자만 업로드 허용
CREATE POLICY "recipe-images authenticated upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'recipe-images');

-- 로그인 사용자 본인 파일만 삭제 허용
CREATE POLICY "recipe-images authenticated delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'recipe-images');
```

## menus.cooking_steps 컬럼

이미 `migrations/20260513_cooking_steps_and_storage.sql`로 추가되었고, 앱 로드 시 `SCHEMA_MIGRATIONS` 자동 점검에서도 검증합니다. 별도 작업 불필요.

```sql
-- (참고용 — 이미 적용되어 있음)
ALTER TABLE menus ADD COLUMN IF NOT EXISTS cooking_steps jsonb DEFAULT '[]'::jsonb;
```

## 클라이언트 헬퍼 함수 (1단계)

`index.html` 스크립트에 다음 데이터 레이어 함수가 추가되어 있습니다:

| 함수 | 시그니처 | 설명 |
|---|---|---|
| `compressImage(file)` | `(File) → Promise<Blob>` | 가로/세로 큰 쪽 1024px 초과 시 비율 유지 축소, JPEG quality 0.85 |
| `uploadCookingPhoto(file, menuId, stepIndex)` | `(File, string, number) → Promise<string>` | 압축 후 `{menuId}/{stepIndex}_{ts}.jpg` 경로로 업로드, public URL 반환 |
| `deleteCookingPhoto(url)` | `(string) → Promise<void>` | public URL에서 경로 추출 후 Storage에서 삭제 |
| `getEmptyStep()` | `() → Step` | 빈 단계 객체 (기본값) 생성 |
| `normalizeCookingSteps(steps)` | `(any) → Step[]` | DB 로드값 정규화 — 누락 필드 기본값 채움, step 번호 1부터 재할당 |

### Step 객체 스키마 (1단계 기준)

```js
{
  step: 1,            // 단계 번호 (자동)
  heat: '중불',        // 강불 / 중불 / 약불 / 없음
  temp: null,         // 온도 (°C, 선택)
  tool: '',           // 도구 (선택)
  duration_sec: 0,    // 조리 시간 (초)
  description: '',    // 조리 방법
  key_point: '',      // 핵심 포인트
  warning: '',        // 주의사항
  photos: []          // public URL 배열
}
```

UI(2단계)와 인쇄(3단계)는 별도 작업 예정.
