-- ═══════════════════════════════════════════════════════════════════════════
-- Migration: Align Supabase schema with Flutter app model
-- Run this in Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 1. STORIES: Add app-specific columns ─────────────────────────────────
-- The app uses cover_color + cover_emoji instead of cover_image_url.
ALTER TABLE public.stories
  ADD COLUMN IF NOT EXISTS cover_color  text,
  ADD COLUMN IF NOT EXISTS cover_emoji  text;

-- Make author_id optional (the app may not send it for local-only stories).
ALTER TABLE public.stories
  ALTER COLUMN author_id DROP NOT NULL;

-- ─── 2. STORY_PAGES: Add app-specific columns ────────────────────────────
-- The app sends image_description (text description) not image_url.
-- The app also tracks a background_color per page.
ALTER TABLE public.story_pages
  ADD COLUMN IF NOT EXISTS image_description text,
  ADD COLUMN IF NOT EXISTS background_color  text;

-- Make page_number optional (app doesn't track ordinal yet).
ALTER TABLE public.story_pages
  ALTER COLUMN page_number DROP NOT NULL;

-- ─── 3. Verify ───────────────────────────────────────────────────────────
-- Run these to confirm the columns exist:
-- SELECT column_name, data_type, is_nullable
--   FROM information_schema.columns
--  WHERE table_name = 'stories'
--  ORDER BY ordinal_position;
--
-- SELECT column_name, data_type, is_nullable
--   FROM information_schema.columns
--  WHERE table_name = 'story_pages'
--  ORDER BY ordinal_position;
