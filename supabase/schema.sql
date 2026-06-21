-- ============================================
-- Fangame Review App — Full Database Schema
-- Based on DBML design
-- Supabase Auth Compatible
-- Run in Supabase SQL Editor
-- Re-runnable (drops everything first)
-- ============================================

-- ==================== CLEANUP ====================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP TABLE IF EXISTS public.review CASCADE;
DROP TABLE IF EXISTS public.fangame CASCADE;
DROP TABLE IF EXISTS public.desarrolladores CASCADE;
DROP TABLE IF EXISTS public.Escritores CASCADE;

-- ==================== ESCRITORES ====================
CREATE TABLE public.Escritores (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  nombre VARCHAR NOT NULL,
  contraseña VARCHAR NOT NULL
);

ALTER TABLE public.Escritores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Escritores are viewable by owner"
  ON public.Escritores FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Escritores are insertable by owner"
  ON public.Escritores FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Escritores are updatable by owner"
  ON public.Escritores FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Escritores are deletable by owner"
  ON public.Escritores FOR DELETE
  USING (auth.uid() = user_id);

-- ==================== DESARROLLADORES ====================
CREATE TABLE public.desarrolladores (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR NOT NULL
);

ALTER TABLE public.desarrolladores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "desarrolladores are publicly readable"
  ON public.desarrolladores FOR SELECT
  USING (true);

CREATE POLICY "desarrolladores are insertable by authenticated users"
  ON public.desarrolladores FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "desarrolladores are updatable by authenticated users"
  ON public.desarrolladores FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "desarrolladores are deletable by authenticated users"
  ON public.desarrolladores FOR DELETE
  USING (auth.role() = 'authenticated');

-- ==================== FANGAME ====================
CREATE TABLE public.fangame (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR,
  url_icon VARCHAR,
  desarrollador_id INTEGER NOT NULL,
  CONSTRAINT fk_fangame_desarrollador_id_desarrolladores
    FOREIGN KEY (desarrollador_id) REFERENCES public.desarrolladores(id)
    ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX idx_fangame_desarrollador_id ON public.fangame(desarrollador_id);

ALTER TABLE public.fangame ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fangame are publicly readable"
  ON public.fangame FOR SELECT
  USING (true);

CREATE POLICY "fangame are insertable by authenticated users"
  ON public.fangame FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "fangame are updatable by authenticated users"
  ON public.fangame FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "fangame are deletable by authenticated users"
  ON public.fangame FOR DELETE
  USING (auth.role() = 'authenticated');

-- ==================== REVIEW ====================
CREATE TABLE public.review (
  id SERIAL PRIMARY KEY,
  id_fangame INTEGER NOT NULL,
  score INTEGER CHECK (score >= 1 AND score <= 10),
  contenido VARCHAR NOT NULL,
  url_video VARCHAR NOT NULL,
  id_escritor UUID NOT NULL,
  CONSTRAINT fk_review_id_fangame_fangame
    FOREIGN KEY (id_fangame) REFERENCES public.fangame(id)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT fk_review_id_escritor_Escritores
    FOREIGN KEY (id_escritor) REFERENCES public.Escritores(user_id)
    ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX idx_review_id_fangame ON public.review(id_fangame);
CREATE INDEX idx_review_id_escritor ON public.review(id_escritor);

ALTER TABLE public.review ENABLE ROW LEVEL SECURITY;

CREATE POLICY "review are publicly readable"
  ON public.review FOR SELECT
  USING (true);

CREATE POLICY "review are insertable by authenticated users"
  ON public.review FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = id_escritor);

CREATE POLICY "review are updatable by author"
  ON public.review FOR UPDATE
  USING (auth.uid() = id_escritor);

CREATE POLICY "review are deletable by author"
  ON public.review FOR DELETE
  USING (auth.uid() = id_escritor);

-- ==================== AUTO-CREATE ESCRITORES ====================
-- When admin adds a user via Supabase dashboard, auto-create Escritores entry
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.Escritores (user_id, nombre, contraseña)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'nombre', SPLIT_PART(NEW.email, '@', 1)),
    ''
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ==================== MIGRATION (for existing DBs) ====================
ALTER TABLE public.fangame ADD COLUMN IF NOT EXISTS url_icon VARCHAR;
ALTER TABLE public.review ADD COLUMN IF NOT EXISTS score INTEGER CHECK (score >= 1 AND score <= 10);
