-- 2026-05-11 migration
-- 1) menu_sales table for order forecast
-- 2) liquors.target_rate column (already shipped in app code)

CREATE TABLE IF NOT EXISTS menu_sales (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users,
  menu_id uuid,
  menu_name text,
  monthly_qty integer DEFAULT 0,
  order_cycle text DEFAULT 'weekly',
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE menu_sales ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "user owns row" ON menu_sales
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE liquors ADD COLUMN IF NOT EXISTS target_rate numeric DEFAULT 30;
