-- ============================================
-- Cleanup — removes ALL remnants of prior schemas
-- Run this BEFORE the new schema.sql
-- ============================================

-- Drop triggers on auth.users (old handle_new_user)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop old auto-profile function
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Drop old updated_at triggers
DROP TRIGGER IF EXISTS set_updated_at_profiles ON public.profiles;
DROP TRIGGER IF EXISTS set_updated_at_fangames ON public.fangames;
DROP TRIGGER IF EXISTS set_updated_at_reviews ON public.reviews;

-- Drop old updated_at function
DROP FUNCTION IF EXISTS public.set_updated_at();

-- Drop old game_ratings view
DROP VIEW IF EXISTS public.game_ratings;

-- Drop old tables (plural names from v1 + v2)
DROP TABLE IF EXISTS public.reviews CASCADE;
DROP TABLE IF EXISTS public.fangames CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Drop new tables (current DBML — in case you re-ran partial)
DROP TABLE IF EXISTS public.review CASCADE;
DROP TABLE IF EXISTS public.fangame CASCADE;
DROP TABLE IF EXISTS public.desarrolladores CASCADE;
DROP TABLE IF EXISTS public.Escritores CASCADE;

-- Done. Now run schema.sql fresh.
